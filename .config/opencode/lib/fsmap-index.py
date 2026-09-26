#!/usr/bin/env python3
"""
fsmap-index — build the local filesystem map.

One walk of the curated roots, aggregated in flight, into a SQLite index that
the `fsmap` opencode tool queries.

Design constraints that shaped this:

  * Artifact directories are recorded as a SINGLE row with role='artifact' and
    then pruned, rather than being descended into. This keeps the index small
    *and* still answers "is there a build dir here".
  * The `stale` role is DERIVED (newest descendant mtime > STALE_DAYS), not
    hardcoded, so it self-updates when a config is adopted or abandoned. The
    max-mtime per config dir falls out of the same walk for free.
  * `notes` / `notes_pending` / `rejected` are annotations, not derived data.
    A rebuild MUST NOT touch them.
  * Symlinks are never followed (loop safety, and it keeps the walk off the
    Koofr/rclone network mounts).
  * Per-root wall-clock budget: a hung network mount must not hang the build.

Usage:
  fsmap-index.py build     rebuild the index (default)
  fsmap-index.py stats     row counts by role and root
  fsmap-index.py check     verify acceptance invariants
"""

import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from pathlib import Path

# Bump whenever the shape of a DERIVED table changes. Only paths/descriptions
# get rebuilt; notes, notes_pending and rejected are user data and are never
# dropped. v2 added paths.is_exec.
SCHEMA_VERSION = 2

# Single source of truth for the paths row layout. Builder.rows holds plain
# tuples in exactly this order. Positional literals like row[12] are banned:
# adding is_exec shifted role from 12 to 13, which silently made the stale
# classifier compare git_head against "signal", match nothing, and report zero
# of every role in meta -- with no error anywhere.
PATH_COLUMNS = ("path", "root", "name", "parent", "depth", "is_dir", "size",
                "mtime", "ext", "is_exec", "is_git", "git_remote", "git_head",
                "role")
ROLE_IDX = PATH_COLUMNS.index("role")

# ---------------------------------------------------------------- roots

HOME = Path.home()
XDG_DATA = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))

# Curated roots, walked at full depth. Chosen because every row is worth
# having; noise is excluded by construction rather than by denylist.
ROOTS = [
    HOME / "src",
    HOME / ".dotfiles",
    HOME / "Documents",
    HOME / "Obsidian",
    HOME / ".config",
    HOME / ".local/bin",
]

STALE_DAYS = 90
# Configs that are live but rarely touched. Without this, a deliberately
# static config would be misfiled as stale. Keep this list short.
KNOWN_LIVE_CONFIGS = {
    "nvim", "micro", "fontconfig", "fontforge", "kitty", "hypr", "waybar",
    "opencode", "qutebrowser", "navi", "ranger", "nnn", "broot", "fuzzel",
    "mako", "wlogout", "wireplumber", "pulse", "user-dirs.dirs",
    "mimeapps.list", "xdg-terminals.list", "autostart", "systemd",
    "environment.d", "scripts", "command-list", "gnome-terminal",
    "menus", "zsh-plugins-are-in-local-share",
}

# Pruned after recording one row. Order does not matter (set membership).
ARTIFACT_DIRS = {
    ".git", "node_modules", "__pycache__", ".venv", "venv", ".direnv",
    ".mypy_cache", ".pytest_cache", ".ruff_cache", ".tox", "target",
    ".next", ".nuxt", ".cache", ".gradle", ".cargo", "vendor",
    "Testing", "_build", ".elixir_ls", ".dart_tool",
    # Meson vendored dependencies. On this machine ~/src/Waybar/subprojects
    # holds Catch2 + cava + fmt + jsoncpp — thousands of rows of third-party
    # code that crowded out the user's own scripts in the description table.
    "subprojects",
}
ARTIFACT_DIR_RE = re.compile(
    r"^(build|dist|out|cmake-build-.*|\.eggs|.*\.egg-info|\.bundle|\.turbo)$",
    re.I,
)
ARTIFACT_EXT = {
    ".o", ".a", ".so", ".pyc", ".pyo", ".class", ".beam", ".elc",
    ".cmakerc", ".d", ".mod", ".swp", ".swo", ".orig", ".rej", ".bak",
}

# Path segments whose contents are never the user's own work. Descriptions
# from here are noise: upstream test fixtures and vendored docs describe the
# upstream project, not this system.
UNOWNED_SEGMENTS = {
    "test", "tests", "test_hooks", "testing", "example", "examples",
    "benchmark", "benchmarks", "fuzzing", "fixture", "fixtures",
    "benchmarkdata", "spec", "specs",
}

NOISE_FILE_RE = re.compile(
    r"^(core(\.\d+)?|steam-\d+\.log|boot-fail\.log|.*\.deb|.*\.zip|"
    r".*\.webm|.*\.iso|.*\.tar\.gz|.*\.rpm|.*\.pkg|.*\.AppImage)$",
    re.I,
)
# Whole top-level directories that are bulk data, not projects.
NOISE_DIRS = {"Downloads", "Music", "Videos", "Pictures", "Koofr", "Sync",
              ".thunderbird", ".lmstudio", "Liz_Phair-Exile_in_Guyville"}

# Roots we record at depth 1 only, so top-level bulk is visible by name
# without walking into it.
SHALLOW_HOME = True

# Wall-clock budget for the whole build, and per root.
TOTAL_BUDGET_S = 60.0
ROOT_BUDGET_S = 20.0

# ------------------------------------------------------- description extraction

# Block-level licence/copyright detection. Line filtering is not enough: the
# Espressif scripts have licence blocks whose *second* line reads as prose
# ("Espressif Systems (Shanghai) CO LTD, other contributors as noted.").
LICENCE_BLOCK = re.compile(
    r"^(SPDX[-\s]|Copyright|\(c\)|©|Licensed under|License\b|"
    r"All rights reserved|This file is part of|Redistribution and use|"
    r"Author:|Authors:|Contributors:|"
    # MIT / BSD / Apache clauses, which read as prose line 1 and defeat
    # line-level filtering on their second line.
    r"Permission is hereby granted|You may not use this file|"
    r"Permission to use, copy|Redistribution and use in source|"
    r"Licensed under the Apache|Creative Commons|"
    r"THE SOFTWARE IS PROVIDED|TERMS AND CONDITIONS)",
    re.I,
)
PROSE_REJECT = re.compile(r"(https?://|ftp://|/home/|/usr/|\$\(|\bsudo\b|<<-?|'|\")")
SHELL_KEYWORDS = {
    "if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case",
    "esac", "function", "return", "local", "export", "readonly", "declare",
    "echo", "printf", "set", "unset", "shift", "exit", "trap", "source",
    "eval", "exec", "local", "cd", "test", "true", "false", "sudo", "echo",
    "esac", "in", "select", "time", "coproc", "until",
}
STOPWORD_LEN = 3


def extract_header_prose(path, max_lines=25):
    """Return the first *confidently* prose comment line, or None.

    Conservative by design. Measurement showed a naive `grep '^#'` heuristic
    describes ~30% of ~/scripts and produces confident nonsense. Emitting
    nothing is strictly better than emitting something wrong, because a wrong
    description gets trusted.
    """
    try:
        with open(path, "r", errors="replace") as fh:
            lines = [fh.readline() for _ in range(max_lines)]
    except (OSError, UnicodeError):
        return None

    in_block = False
    for raw in lines:
        s = raw.strip()
        if not s:
            in_block = False
            continue
        if s.startswith("#!"):
            continue
        if not s.startswith("#"):
            break  # reached code before finding a comment block
        body = s.lstrip("#").strip()
        if not body:
            continue
        if not in_block and LICENCE_BLOCK.match(body):
            in_block = True  # skip this whole block, not just this line
            continue
        in_block = False
        if re.match(r"^[-=*_~]{3,}$", body):
            continue
        if len(body) < 15 or len(body.split()) < 5:
            continue
        if PROSE_REJECT.search(body):
            continue
        # All-caps lines are banners, not prose. Without this,
        # small-terminal-header.sh summarises as "CODED BY CLAUDE THE ROBOT".
        if not any(c.islower() for c in body):
            continue
        return body
    return None


# Standard-issue plumbing. Present in nearly every script, so it carries no
# information: `runs: bash, cat, mkdir` tells you nothing, while
# `runs: obsidian, hyprctl` tells you what the script does. Only
# *distinguishing* commands are reported.
BOILERPLATE_CMDS = {
    "bash", "sh", "zsh", "dash", "ksh", "env", "cat", "mkdir", "rmdir", "rm",
    "cp", "mv", "ls", "sleep", "printf", "echo", "cut", "sort", "uniq", "head",
    "tail", "wc", "date", "basename", "dirname", "realpath", "readlink",
    "touch", "chmod", "find", "grep", "egrep", "sed", "awk", "xargs", "tr",
    "tee", "true", "false", "test", "kill", "killall", "pgrep", "pkill",
    "uname", "whoami", "id", "which", "command", "time", "wait", "yes", "no",
    "seq", "expr", "let", "diff", "cmp", "stat", "du", "df", "mktemp", "clear",
    "print", "declare", "type", "hash", "mapfile", "read", "tee", "column",
    "nl", "paste", "join", "split", "comm", "fmt", "fold", "shuf", "install",
    "sed", "dirname", "sync", "stty", "tput", "dircolors", "md5sum", "sha1sum",
    "sha256sum", "base64", "xxd", "od", "hexdump", "strings", "file", "jq",
}

_EXTERNAL_CACHE = {}


def detect_commands(path, limit=250):
    """Statically detect DISTINGUISHING external commands the script invokes.

    Not a description, but it is factual, and it is what makes a script with
    no header comment comprehensible: `new-note` is only understandable from
    the fact that it drives obsidian + hyprctl.
    """
    try:
        if os.path.getsize(path) > 512_000:
            return []
        with open(path, "r", errors="replace") as fh:
            text = fh.read(64_000)
    except (OSError, UnicodeError):
        return []

    # Command position only. Scanning every word in the file matched variable
    # names against real binaries on the system, so change-wallpaper.sh came
    # out as "runs: edit, extend, look, prefix". A token counts only at the
    # start of a line or directly after a command separator.
    words = set(re.findall(
        r"(?:^|(?<=[\n|;&(])\s*|\$\(\s*|`\s*|(?:&&|\|\|)\s*)\s*"
        r"([a-zA-Z][a-zA-Z0-9._-]{2,})\b",
        text, re.M,
    ))
    found = []
    for w in sorted(words):
        if len(found) >= 5:
            break
        low = w.lower()
        if low in SHELL_KEYWORDS or low in BOILERPLATE_CMDS or len(low) < STOPWORD_LEN:
            continue
        if low in _EXTERNAL_CACHE:
            if _EXTERNAL_CACHE[low]:
                found.append(low)
            continue
        # `which` on each unique token; cached across the whole run.
        resolved = shutil.which(low)
        _EXTERNAL_CACHE[low] = resolved is not None
        if resolved and os.path.basename(resolved) == low:
            found.append(low)
    return found


def is_elf(path):
    """True for compiled binaries. Describing these as 'runs: ...' is noise."""
    try:
        with open(path, "rb") as fh:
            return fh.read(4) == b"\x7fELF"
    except OSError:
        return True  # unreadable: assume binary, stay quiet


def describeable(path, root, ext, mode):
    """Only describe things that are plausibly the user's own scripts.

    Order matters for build time. The exec-bit test is free (we already have
    the lstat), the extension and path-segment tests are free, and only the
    ELF sniff actually costs a syscall — so it runs last, on a tiny subset.
    Checking ELF first opened all 65k files and took the build from 2s to 12s.
    """
    if not (mode & 0o111):
        return False
    if ext in (".md", ".txt", ".json", ".yaml", ".yml", ".toml", ".png",
               ".jpg", ".svg", ".pdf", ".desktop", ".conf", ".log", ".bak"):
        return False
    if ext in UNOWNED_SEGMENTS or set(Path(path).parts) & UNOWNED_SEGMENTS:
        return False
    if ext not in ("", ".sh", ".bash", ".zsh", ".py") and root.name != "bin":
        return False
    return not is_elf(path)


def describe(path):
    """Return (summary, source). source ∈ {header, commands, none}."""
    if not (os.path.isfile(path) and os.access(path, os.X_OK)):
        return None, "none"
    prose = extract_header_prose(path)
    if prose:
        return prose[:200], "header"
    cmds = detect_commands(path)
    if cmds:
        return "runs: " + ", ".join(cmds), "commands"
    return None, "none"


# ------------------------------------------------------------------ git

def git_info(repo):
    """(remote_name, head_sha) for a repo, or (None, None)."""
    def run(*args):
        try:
            return subprocess.run(
                ["git", "-C", str(repo), *args],
                capture_output=True, text=True, timeout=5,
            ).stdout.strip()
        except (subprocess.SubprocessError, OSError):
            return ""
    remote = run("config", "--get", "remote.origin.url")
    if remote:
        remote = remote.rsplit("/", 1)[-1]
        if remote.endswith(".git"):
            remote = remote[:-4]
    return (remote or None), (run("rev-parse", "--short", "HEAD") or None)


def looks_like_git_root(d):
    """True for `.git` subdirs and for repos whose worktree IS the gitdir.

    ~/.dotfiles is the latter: a non-bare repo with no `.git` directory, so a
    naive "contains .git" check misses it and indexes the object database.
    """
    if (d / ".git").exists():
        return True
    return (d / "HEAD").is_file() and (d / "objects").is_dir() and (d / "refs").is_dir()


# ------------------------------------------------------------------ db

DDL = """
CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);

CREATE TABLE IF NOT EXISTS paths(
  path TEXT PRIMARY KEY,
  root TEXT, name TEXT, parent TEXT, depth INT,
   is_dir INT, size INT, mtime INT, ext TEXT,
   is_exec INT DEFAULT 0,
   is_git INT DEFAULT 0, git_remote TEXT, git_head TEXT,
   role TEXT NOT NULL DEFAULT 'signal'
 );
CREATE INDEX IF NOT EXISTS idx_paths_root  ON paths(root);
CREATE INDEX IF NOT EXISTS idx_paths_role  ON paths(role);
CREATE INDEX IF NOT EXISTS idx_paths_name  ON paths(name);
CREATE INDEX IF NOT EXISTS idx_paths_mtime ON paths(mtime);

CREATE TABLE IF NOT EXISTS descriptions(
  rowid INTEGER PRIMARY KEY,
  path TEXT UNIQUE NOT NULL,
  summary TEXT,
  source TEXT
);
CREATE VIRTUAL TABLE IF NOT EXISTS descriptions_fts
  USING fts5(summary, content='descriptions');

-- Annotations. NEVER truncated by a rebuild.
CREATE TABLE IF NOT EXISTS notes(
  id INTEGER PRIMARY KEY,
  path TEXT, text TEXT NOT NULL,
  created_at INT, session TEXT, promoted_at INT
);
CREATE TABLE IF NOT EXISTS notes_pending(
  id INTEGER PRIMARY KEY,
  path TEXT, text TEXT NOT NULL,
  created_at INT, session TEXT
);
CREATE TABLE IF NOT EXISTS rejected(
  key TEXT PRIMARY KEY,
  reason TEXT, at INT
);
"""


def db_path():
    return XDG_DATA / "opencode" / "fsmap" / "index.db"


def connect():
    p = db_path()
    p.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(p)
    ensure_schema(con)
    con.commit()
    return con


# Recreated wholesale when the version changes, because the whole point of
# storing a version is to avoid ALTER TABLE. All three are pure functions of
# the filesystem, so dropping them loses nothing.
DERIVED_TABLES = ("descriptions_fts", "descriptions", "paths")


def ensure_schema(con):
    """Apply the DDL, rebuilding derived tables if the schema version moved.

    The DDL is all CREATE ... IF NOT EXISTS, so on its own it would happily
    leave a stale table in place and the next INSERT would fail on a missing
    column. Comparing the stored version catches that.
    """
    row = con.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='meta'"
    ).fetchone()
    if not row:
        con.executescript(DDL)
        return
    have = con.execute(
        "SELECT value FROM meta WHERE key='schema_version'"
    ).fetchone()
    if have and have[0] != str(SCHEMA_VERSION):
        for t in DERIVED_TABLES:
            con.execute(f"DROP TABLE IF EXISTS {t}")
        # FTS5 shadow tables are not listed in sqlite_master as plain tables
        # and would otherwise be left orphaned holding the old content.
        for (name,) in con.execute(
                "SELECT name FROM sqlite_master WHERE name LIKE 'descriptions_fts%'"
        ).fetchall():
            con.execute(f"DROP TABLE IF EXISTS {name}")
    con.executescript(DDL)


# ------------------------------------------------------------------ walk

class Builder:
    def __init__(self, con):
        self.con = con
        self.rows = []
        self.descs = []
        self.git_repos = {}
        # Paths already emitted, so overlapping walks cannot double-count.
        self._seen = set()
        self.config_max_mtime = {}
        self.truncated = []
        self.started = time.time()

    # -- role helpers ---------------------------------------------------
    @staticmethod
    def classify_dir(name):
        if name in ARTIFACT_DIRS or ARTIFACT_DIR_RE.match(name):
            return "artifact"
        return "signal"

    def budget_left(self):
        return TOTAL_BUDGET_S - (time.time() - self.started)

    # -- emit -----------------------------------------------------------
    def emit(self, path, root, parent, depth, is_dir, size, mtime, role,
             is_git=0, git_remote=None, git_head=None, mode=0):
        # Guard against emitting the same path twice. The curated roots are
        # walked at full depth *and* labelled by the depth-1 home sweep, so
        # without this they land in self.rows twice; INSERT OR REPLACE then
        # hides the duplicate in the DB while every in-memory count (and so
        # every meta number) stays quietly one-per-duplicate too high.
        key = str(path)
        if key in self._seen:
            return
        self._seen.add(key)
        self.rows.append((
            key, root, os.path.basename(str(path)),
            str(parent) if parent else None, depth,
            1 if is_dir else 0, size, mtime,
            # Store "" for a dotless name, never None. A trailing `or None`
            # here silently turned "" into NULL for every dotless file, which
            # made `WHERE ext=''` (the natural way to find shell scripts and
            # extensionless executables) match nothing at all.
            (Path(path).suffix or "").lower(),
            # Any execute bit counts, not just owner-x: a script you can only
            # run as root is still a script. Directories are excluded even
            # though they are usually 0755, or every dir would look like a
            # script. Stored so the `scripts` tool action can find real
            # executables instead of guessing from the filename, which
            # surfaced .gitignore and vendored LICENSE files.
            1 if (not is_dir and mode & 0o111) else 0,
            is_git, git_remote, git_head, role,
        ))

    # -- roots ----------------------------------------------------------
    def walk_root(self, root):
        root = Path(root)
        if not root.exists():
            return
        label = str(root)
        root_started = time.time()
        counts = {"signal": 0, "artifact": 0}

        for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
            here = Path(dirpath)
            rel_depth = len(here.relative_to(root).parts)

            try:
                st = here.stat()
                dir_mtime, dir_size = int(st.st_mtime), 0
            except OSError:
                dir_mtime, dir_size = 0, 0

            if time.time() - root_started > ROOT_BUDGET_S or self.budget_left() <= 0:
                self.truncated.append(f"{label} (depth {rel_depth})")
                break

            # Track newest mtime per top-level ~/.config child, for `stale`.
            # Attributed for EVERY descendant, not just immediate children:
            # an app whose data lives in nested subdirs (Slack, Code, anything
            # using Local Storage) has an old top-level mtime but a current
            # one deep inside. Since the walk visits everything anyway,
            # computing the true max is free.
            if root.name == ".config" and rel_depth >= 1:
                top = here.relative_to(root).parts[0]
                self.config_max_mtime[top] = max(
                    self.config_max_mtime.get(top, 0), dir_mtime
                )

            is_repo = looks_like_git_root(here)
            g_remote = g_head = None
            if is_repo:
                g_remote, g_head = git_info(here)
                self.git_repos[str(here)] = (g_remote, g_head)

            self.emit(here, label, here.parent, rel_depth, True, dir_size,
                      dir_mtime, "signal", 1 if is_repo else 0, g_remote, g_head)
            counts["signal"] += 1

            # Prune: record one row, do not descend.
            keep = []
            for d in sorted(dirnames):
                child = here / d
                role = self.classify_dir(d)
                if role == "artifact":
                    try:
                        cst = child.stat()
                        self.emit(child, label, here, rel_depth + 1, True,
                                  0, int(cst.st_mtime), "artifact")
                    except OSError:
                        self.emit(child, label, here, rel_depth + 1, True,
                                  0, 0, "artifact")
                    counts["artifact"] += 1
                    continue
                keep.append(d)
            dirnames[:] = keep

            for f in sorted(filenames):
                fp = here / f
                try:
                    fst = fp.lstat()
                    size, mtime, mode = fst.st_size, int(fst.st_mtime), fst.st_mode
                    is_link = fp.is_symlink()
                except OSError:
                    continue
                ext = (Path(f).suffix or "").lower()
                role = "artifact" if (ext in ARTIFACT_EXT or f in
                                      ("CMakeCache.txt", "CMakeLists.txt",
                                       ".DS_Store", "Thumbs.db")) else "signal"
                self.emit(fp, label, here, rel_depth + 1, False, size, mtime,
                          role, mode=mode)
                counts[role] = counts.get(role, 0) + 1

                if root.name == ".config" and rel_depth >= 1:
                    top = here.relative_to(root).parts[0]
                    self.config_max_mtime[top] = max(
                        self.config_max_mtime.get(top, 0), mtime
                    )

                if role == "signal" and not is_link and describeable(fp, root, ext, mode):
                    summary, source = describe(fp)
                    if summary:
                        self.descs.append((str(fp), summary, source))

        print(f"  {label:38} {counts.get('signal', 0):7} signal  "
              f"{counts.get('artifact', 0):5} artifact"
              + ("  [TRUNCATED]" if any(label in t for t in self.truncated) else ""))

    def sweep_home_depth1(self):
        """Record $HOME top level by name only — never descend.

        Makes the ~1.5GB of core dumps, steam logs and stray archives visible
        as `noise` without reading them. Also records which bulk directories
        exist, which is most of the answer to "what's eating disk".

        Role here answers "is this worth walking into?", which is a different
        question from the per-file role used inside roots. An earlier version
        marked every dotted directory `noise`, which wrongly swept up
        .config, .local and .dotfiles — the three most important dirs there
        are. Hence the distinct `unindexed` role: present, real, deliberately
        not descended. That is the map's "where not to look" channel.
        """
        label = "$HOME (depth 1)"
        curated = {str(r) for r in ROOTS}
        for entry in sorted(HOME.iterdir()):
            name = entry.name
            path = str(entry)
            try:
                if entry.is_symlink():
                    self.emit(entry, label, HOME, 1, False, 0, 0, "unindexed")
                    continue
                st = entry.stat()
            except OSError:
                continue
            is_dir = entry.is_dir()
            if path in curated:
                role = "signal"
            elif is_dir:
                role = "noise" if name in NOISE_DIRS else "unindexed"
            else:
                role = "noise" if (NOISE_FILE_RE.match(name)
                                   or name.endswith((".log", ".bak"))) else "signal"
            self.emit(entry, label, HOME, 1, is_dir,
                      0 if is_dir else st.st_size, int(st.st_mtime), role)

    # -- stale ----------------------------------------------------------
    def apply_stale(self):
        """Return the set of abandoned config dir names.

        Derived, so it self-updates. NOTE: this only *computes* the set. The
        roles are stamped onto the in-memory rows before insert — an earlier
        version ran an UPDATE here, which persist() then erased with its
        `DELETE FROM paths`, silently reporting stale=0.
        """
        cutoff = time.time() - STALE_DAYS * 86400
        marked = set()
        for name, newest in self.config_max_mtime.items():
            if name in KNOWN_LIVE_CONFIGS or newest == 0:
                continue
            if newest < cutoff:
                marked.add(name)
        return marked

    # -- persist --------------------------------------------------------
    def stamp_stale(self, names):
        """Rewrite role in memory so counts and stored roles agree."""
        if not names:
            return 0
        n = 0
        for i, row in enumerate(self.rows):
            path, role = row[0], row[ROLE_IDX]
            if role != "signal":
                continue
            if "/.config/" not in path + "/":
                continue
            if row[1] != str(HOME / ".config"):
                continue
            rel = Path(path).relative_to(HOME / ".config")
            if rel.parts and rel.parts[0] in names:
                self.rows[i] = row[:ROLE_IDX] + ("stale",) + row[ROLE_IDX + 1:]
                n += 1
        return n

    def persist(self):
        con = self.con
        # Derived data only. Notes/pending/rejected are left untouched.
        # Fail loudly on a row/column mismatch: a short row would otherwise
        # raise an opaque sqlite3 error, or worse, insert shifted data.
        bad = [i for i, r in enumerate(self.rows) if len(r) != len(PATH_COLUMNS)]
        if bad:
            raise SystemExit(
                f"fsmap: {len(bad)} row(s) do not match PATH_COLUMNS "
                f"(expected {len(PATH_COLUMNS)} fields, e.g. row {bad[0]} has "
                f"{len(self.rows[bad[0]])}). Refusing to write a corrupt index."
            )
        con.execute("DELETE FROM paths")
        con.execute("DELETE FROM descriptions")
        con.execute("DELETE FROM descriptions_fts")
        con.executemany(
            f"INSERT OR REPLACE INTO paths({','.join(PATH_COLUMNS)}) "
            f"VALUES({','.join('?' * len(PATH_COLUMNS))})",
            self.rows,
        )
        con.executemany(
            "INSERT OR REPLACE INTO descriptions(path,summary,source) VALUES(?,?,?)",
            self.descs,
        )
        con.execute(
            "INSERT INTO descriptions_fts(rowid, summary) "
            "SELECT rowid, summary FROM descriptions WHERE summary IS NOT NULL"
        )
        meta = {
            "schema_version": SCHEMA_VERSION,
            "generated_at": int(time.time()),
            "generated_iso": time.strftime("%Y-%m-%d %H:%M:%S"),
            "build_seconds": round(time.time() - self.started, 2),
            "rows": len(self.rows),
            "signal": sum(1 for r in self.rows if r[ROLE_IDX] == "signal"),
            "artifact": sum(1 for r in self.rows if r[ROLE_IDX] == "artifact"),
            "noise": sum(1 for r in self.rows if r[ROLE_IDX] == "noise"),
            "stale": sum(1 for r in self.rows if r[ROLE_IDX] == "stale"),
            "descriptions": len(self.descs),
            "descriptions_from_header": sum(1 for d in self.descs if d[2] == "header"),
            "git_repos": len(self.git_repos),
            "roots": json.dumps([str(r) for r in ROOTS]),
            "stale_days": STALE_DAYS,
        }
        if self.truncated:
            meta["truncated"] = "; ".join(self.truncated)
        con.executemany(
            "INSERT OR REPLACE INTO meta(key,value) VALUES(?,?)", meta.items()
        )
        con.commit()


# ------------------------------------------------------------------ cmds

def cmd_build():
    t0 = time.time()
    print(f"fsmap: building index -> {db_path()}")
    con = connect()
    b = Builder(con)
    for root in ROOTS:
        b.walk_root(root)
    if SHALLOW_HOME:
        b.sweep_home_depth1()
    stale = b.apply_stale()
    b.stamp_stale(stale)
    b.persist()
    con.close()

    print(f"\n  {len(b.rows):,} rows  {len(b.descs)} descriptions  "
          f"{len(b.git_repos)} git repos  in {time.time() - t0:.2f}s")
    if stale:
        print(f"  stale configs (> {STALE_DAYS}d untouched): {', '.join(sorted(stale))}")
    if b.truncated:
        print(f"  TRUNCATED: {'; '.join(b.truncated)}  (raise TOTAL_BUDGET_S)")
    print("fsmap: done")


def cmd_stats():
    con = connect()
    print("rows by role:")
    for role, n in con.execute(
            "SELECT role, COUNT(*) FROM paths GROUP BY role ORDER BY 2 DESC"):
        print(f"  {role:10} {n:>7,}")
    print("\nrows by root:")
    for root, n in con.execute(
            "SELECT root, COUNT(*) FROM paths GROUP BY root ORDER BY 2 DESC"):
        print(f"  {str(root):40} {n:>7,}")
    print("\ndescriptions by source:")
    for src, n in con.execute(
            "SELECT source, COUNT(*) FROM descriptions GROUP BY source"):
        print(f"  {src:10} {n:>4}")
    print("\ngit repos:")
    for path, remote, head in con.execute(
            "SELECT path, git_remote, git_head FROM paths "
            "WHERE is_git=1 AND depth=(SELECT MIN(depth) FROM paths p2 "
            "WHERE p2.path=paths.path) ORDER BY path"):
        print(f"  {str(path):44} {str(remote or '—'):22} {head or '—'}")
    print("\nmeta:")
    for k, v in con.execute("SELECT key, value FROM meta ORDER BY key"):
        print(f"  {k:28} {v}")
    con.close()


def cmd_check():
    """Acceptance invariants. Exit non-zero on failure."""
    con = connect()
    failures = []

    missing = con.execute(
        "SELECT COUNT(*) FROM paths WHERE role='signal' AND is_dir=0"
    ).fetchone()[0]
    gone = 0
    for (p,) in con.execute(
            "SELECT path FROM paths WHERE role='signal' AND is_dir=0 LIMIT 4000"
    ):
        # lexists, not exists: 8 of the 40 scripts in ~/.local/bin are
        # symlinks, and exists() follows them to a missing target.
        if not os.path.lexists(p):
            gone += 1
    if gone:
        failures.append(f"{gone}/4000 sampled signal files do not exist (index stale)")

    leak = con.execute(
        "SELECT COUNT(*) FROM paths WHERE path LIKE '%/.git/%' AND role='signal'"
    ).fetchone()[0]
    if leak:
        failures.append(f"{leak} .git internals leaked in as role=signal")

    pending = con.execute("SELECT COUNT(*) FROM notes_pending").fetchone()[0]
    if pending > 8:
        failures.append(f"pending queue over cap: {pending} > 8")

    no_notes_lost = con.execute("SELECT COUNT(*) FROM notes").fetchone()[0]
    print(f"  signal files sampled : 4000 ({gone} missing)")
    print(f"  .git leakage         : {leak}")
    print(f"  pending notes        : {pending} (cap 8)")
    print(f"  durable notes        : {no_notes_lost}")

    for f in failures:
        print(f"  FAIL: {f}")
    con.close()
    if failures:
        sys.exit(1)
    print("  all invariants hold")


def disk_usage(max_age_h=24):
    """Top $HOME consumers via `dua aggregate`, cached in meta.

    `dua` has no -s flag; the subcommand is `aggregate`. Answering "what's
    eating disk" cost 3 exploratory calls and one 120s timeout in the
    baseline, so it is worth inlining — but not worth paying for on every
    query, hence the cache. The systemd timer refreshes it daily.
    """
    con = connect()
    row = con.execute(
        "SELECT value FROM meta WHERE key='disk_usage'").fetchone()
    stamp = con.execute(
        "SELECT value FROM meta WHERE key='disk_usage_at'").fetchone()
    fresh = (row and stamp
             and (time.time() - int(stamp[0])) < max_age_h * 3600)
    if fresh:
        con.close()
        return json.loads(row[0])

    dua = shutil.which("dua")
    if not dua:
        con.close()
        return None
    try:
        out = subprocess.run(
            [dua, "aggregate", "-f", "gb", "-x", str(HOME)],
            capture_output=True, text=True, timeout=300,
        ).stdout
    except (subprocess.SubprocessError, OSError):
        con.close()
        return None

    entries, total = [], None
    for raw in out.splitlines():
        line = re.sub(r"\x1b\[[0-9;]*m", "", raw).strip()
        m = re.match(r"^([\d.]+)\s*(TB|GB|MB|KB|B)\s+(\S.*)$", line)
        if not m:
            continue
        val, unit, name = float(m.group(1)), m.group(2), m.group(3).strip()
        gb = {"TB": 1024, "GB": 1, "MB": 1 / 1024, "KB": 1 / 1048576, "B": 1e-9}[unit]
        if name == "total":
            total = round(val * gb, 1)
            continue
        entries.append({"gb": round(val * gb, 2), "name": name})
    entries.sort(key=lambda e: -e["gb"])
    payload = {"total_gb": total, "top": entries[:12]}
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('disk_usage',?)",
                (json.dumps(payload),))
    con.execute("INSERT OR REPLACE INTO meta(key,value) VALUES('disk_usage_at',?)",
                (str(int(time.time())),))
    con.commit()
    con.close()
    return payload


def human(n):
    for unit in ("B", "K", "M", "G", "T"):
        if abs(n) < 1024 or unit == "T":
            return f"{n:.0f}{unit}" if unit in "BT" else f"{n:.1f}{unit}"
        n /= 1024


# One-line character for each root. The generated map is only as good as its
# orientation, and a bare row count does not say whether to look here. This is
# the human-authored part of a generated document.
ROOT_BLURBS = {
    str(HOME / "src"): "your own code projects, mostly git clones/forks",
    str(HOME / ".dotfiles"): "git repo whose worktree IS its gitdir (no .git subdir)",
    str(HOME / "Documents"): "work media, fonts, TWO Obsidian vaults, a hyprland .55 wiki",
    str(HOME / "Obsidian"): "Obsidian vault: flat, date-stamped notes, syncthing",
    str(HOME / ".config"): "all app config; check role=stale before trusting a dir",
    str(HOME / ".local/bin"): "personal scripts on PATH; descriptions may be thin",
}


def cmd_overview():
    """Write map/overview.md - the always-in-context orientation digest.

    Budget is 800 tokens and it is ENFORCED, not eyeballed. The first version
    came in at 2220 because a 63-row markdown table costs ~20 tokens per row;
    every pipe is a token. Grouped one-liners instead.
    """
    con = connect()
    m = dict(con.execute("SELECT key, value FROM meta"))
    out_dir = Path(__file__).resolve().parent.parent / "map"
    out_dir.mkdir(parents=True, exist_ok=True)
    h = str(HOME)

    pending = con.execute("SELECT COUNT(*) FROM notes_pending").fetchone()[0]
    expired = con.execute(
        "SELECT COUNT(*) FROM rejected WHERE reason='expired'").fetchone()[0]
    durable = con.execute("SELECT COUNT(*) FROM notes").fetchone()[0]
    disk = disk_usage()

    def at(role):
        # Directories only — see the note at the call site.
        return [r[0].replace(h, "~") for r in con.execute(
            "SELECT path FROM paths WHERE root='$HOME (depth 1)' AND role=? "
            "AND is_dir=1 ORDER BY path", (role,))]

    noi, uni = at("noise"), at("unindexed")
    # Order the not-walked list by real size so the 126G elephant leads and
    # trivia like ~/.gemini trails. dua gives us top-level child sizes.
    gbs = {e["name"]: float(e["gb"]) for e in ((disk or {}).get("top") or [])}
    uni.sort(key=lambda p: (-gbs.get(p.lstrip("~/").split("/")[0], 0.0), p))

    L = []
    A = L.append
    A("# Filesystem map")
    A("")
    A(f"Generated {m.get('generated_iso','?')} - {int(m.get('rows',0)):,} indexed rows. "
      f"**Generated file: change `fsmap-index.py`, not this.**")
    A("")
    A("Trust **shape** here. Treat **content** as a lead, verify before acting. "
      "**Live state** (loaded file, git HEAD, processes) is never cached - read it fresh.")
    A("Detail: the **`fsmap` tool** (`where` `what` `find` `repos` `scripts` "
      "`changed` `stale`). Prefer it to `ls`/`find`/`du`.")
    A("")
    A("## Indexed roots")
    A("")
    for root, n, art in con.execute(
            "SELECT root, SUM(role='signal'), SUM(role='artifact') FROM paths "
            "WHERE root NOT LIKE '$HOME%' GROUP BY root ORDER BY 2 DESC"):
        A(f"- `{root.replace(h,'~')}` {n:,} files, {art} artifact dirs - "
          f"{ROOT_BLURBS.get(root, '')}")
    A("")
    A("## $HOME")
    A("")
    # Only DIRECTORIES here. Individual dotfiles at depth 1 are not "indexed
    # roots" and listing them was both wrong and the single biggest token
    # sink in the first draft.
    nfiles = con.execute(
        "SELECT COUNT(*) FROM paths WHERE root='$HOME (depth 1)' AND is_dir=0"
    ).fetchone()[0]
    A(f"- indexed roots: the {len(ROOT_BLURBS)} above.")
    A("- bulk, never search: `" + "` `".join(noi) + "`")
    A(f"- present, not walked: `{'` `'.join(uni[:7])}` (+{max(0, len(uni) - 7)} "
      f"more; {nfiles} loose files at ~ — dotfiles, logs, .deb, core dumps).")
    A("")
    if disk and disk.get("top"):
        A(f"**Disk: {disk.get('total_gb','?')}G in ~** - " + ", ".join(
            f"{e['name']} {e['gb']}G" for e in disk["top"][:8]))
        A("")
    stale_dirs = [r[0] for r in con.execute(
        "SELECT DISTINCT name FROM paths WHERE role='stale' AND depth=1 "
        "AND root LIKE '%/.config' ORDER BY name")]
    if stale_dirs:
        A(f"**{len(stale_dirs)} dormant dirs in ~/.config** (untouched "
          f"{m.get('stale_days',90)}d - evidence of disuse, not proof; "
          f"write-once configs of live apps land here too): `"
          + "` `".join(stale_dirs) + "`")
        A("")
    A("## Annotation queue")
    A("")
    if pending:
        A(f"**{pending} pending note(s)** need review - `fsmap-notes review` or "
          f"`/fsmap-review`. Promote what is true, reject the rest so the same "
          f"wrong note is not proposed again.")
    else:
        A(f"{durable} durable annotation(s), none pending"
          + (f", {expired} expired unclaimed." if expired else "."))
    A("")
    A("---")
    A("Rebuild `fsmap-index.py build` - regenerated daily 04:17 by systemd timer.")

    text = "\n".join(L) + "\n"
    dest = out_dir / "overview.md"
    dest.write_text(text)

    # Token estimate. chars/4 badly understates markdown: every / - _ . and |
    # is its own token. Count word runs and symbol runs separately.
    est = (len(re.findall(r"[A-Za-z0-9_]+", text))
           + len(re.findall(r"[^\w\s]", text)))
    print(f"fsmap: wrote {dest}")
    print(f"  {len(text):,} chars, {len(L)} lines, ~{est} tokens (est) - "
          f"budget 800: {'OK' if est <= 800 else 'OVER by ' + str(est - 800)}")
    con.close()
    return est


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    table = {
        "build": cmd_build,
        "stats": cmd_stats,
        "check": cmd_check,
        "overview": cmd_overview,
    }
    fn = table.get(cmd)
    if fn is None:
        print(__doc__)
        sys.exit(2)
    rc = fn()
    sys.exit(1 if rc and cmd == "overview" and rc > 800 else 0)
