import { tool } from "@opencode-ai/plugin"
import { Database } from "bun:sqlite"
import { existsSync } from "node:fs"
import { homedir } from "node:os"
import path from "node:path"

const HOME = homedir()
const DATA = process.env.XDG_DATA_HOME ?? path.join(HOME, ".local/share")
const DB_PATH = path.join(DATA, "opencode/fsmap/index.db")
const INDEXER = path.join(HOME, ".config/opencode/lib/fsmap-index.py")

// Path columns store absolute paths; show them the way the user writes them.
const short = (p: string) => p.startsWith(HOME + "/") ? "~/" + p.slice(HOME.length + 1) : p

/**
 * Translate a user glob into a SQL LIKE pattern.
 *
 * The pattern is always wrapped in `%` on both sides, so it is a *substring*
 * glob rather than an anchored one. That is deliberate: every indexed path is
 * absolute, so an anchored "hypr*" could never match anything and silently
 * returned zero rows. Bare terms get the same treatment for free.
 * Remember to escape SQL wildcards in the user's own text, and that in SQLite
 * `_` is a single-char wildcard unless backslash-escaped.
 */
function likePattern(q: string) {
  const esc = q.replace(/[\\%_]/g, (c) => "\\" + c)
  return `%${esc.replace(/\*/g, "%").replace(/\?/g, "_")}%`
}

const expand = (p: string) => p.startsWith("~/") ? path.join(HOME, p.slice(2)) : p

/**
 * Read-only handle for queries. Every action except `note` uses this, so a
 * stray query can never mutate the index.
 */
function open() {
  if (!existsSync(DB_PATH))
    throw new Error(`No index at ${DB_PATH}. Run \`fsmap-index.py build\` (or the refresh action).`)
  return new Database(DB_PATH, { readonly: true, strict: true })
}

/**
 * Read-write handle, used only by `note` to append to the pending queue.
 * Separate from open() on purpose so the read-only guarantee above holds for
 * everything else -- and because opening one RW handle for a query would
 * create the -wal/-shm siblings needlessly.
 */
function openRW() {
  if (!existsSync(DB_PATH))
    throw new Error(`No index at ${DB_PATH}. Run \`fsmap-index.py build\` first.`)
  return new Database(DB_PATH)
}

function rows(db: Database, sql: string, ...params: any[]) {
  return db.query(sql).all(...params) as any[]
}

function one(db: Database, sql: string, ...params: any[]) {
  return db.query(sql).get(...params) as any
}

export default tool({
  description: [
    "Query the prebuilt local filesystem map (SQLite index of ~/src, ~/.config,",
    "~/.local/bin, ~/Documents, ~/Obsidian, ~/.dotfiles plus a depth-1 ~ inventory).",
    "Prefer this over ls/find/du/grep for discovery: it is ~1000x cheaper than shelling out.",
    "",
    "Actions:",
    "  where <glob>   - match paths by glob, e.g. '*waybar*'. Optionally role=signal|artifact|noise|stale|unindexed",
    "  what <path>    - describe one path: role, size, git remote/head, extracted description, children, annotations",
    "  find <terms>   - search names AND file descriptions, e.g. 'screenshot tool'",
    "  repos [glob]   - git repos with remote URL and HEAD commit",
    "  scripts [glob] - executables, with their extracted descriptions",
    "  changed [days] - files changed in the last N days (default 7)",
    "  stale [days]   - config dirs untouched for N days (default 90) - evidence of disuse, not proof",
    "  refresh        - rebuild the index (takes ~3s) and regenerate map/overview.md",
    "  note <path> <text> - queue a durable annotation about a path for the user to review",
    "",
    "Roles: signal = indexed content, artifact = build/vendor dir (do not descend),",
    "noise = bulk (do not search), stale = dormant config, unindexed = present, not walked.",
    "Descriptions are heuristics derived from headers and command usage: treat as leads, verify before acting.",
  ].join("\n"),
  args: {
    action: tool.schema
      .enum(["where", "what", "find", "repos", "scripts", "changed", "stale", "refresh", "note"])
      .describe("Which query to run."),
    query: tool.schema.string().default("").describe("Search term, glob, or path. See action docs."),
    text: tool.schema.string().default("").describe("Annotation body, for action=note."),
    role: tool.schema
      .enum(["signal", "artifact", "noise", "stale", "unindexed", "any"])
      .default("any")
      .describe("Restrict `where` to one role."),
    days: tool.schema.number().default(7).describe("Lookback window for changed/stale."),
    limit: tool.schema.number().default(40).describe("Max rows to return."),
  },
  async execute(args, context) {
    context.metadata({ title: `fsmap ${args.action}` })
    const limit = Math.max(1, Math.min(args.limit, 200))
    const q = args.query.trim()

    if (args.action === "refresh") {
      const t0 = Date.now()
      const out = await Bun.$`python3 ${INDEXER} build`.quiet().text()
      await Bun.$`python3 ${INDEXER} overview`.quiet().text()
      const m = open()
      const meta = Object.fromEntries(
        m.query("SELECT key, value FROM meta WHERE key IN ('rows','descriptions','git_repos','build_seconds')").all() as any[],
      )
      m.close()
      return `Reindexed in ${((Date.now() - t0) / 1000).toFixed(1)}s: ${Number(meta.rows).toLocaleString()} rows, ${meta.descriptions} descriptions, ${meta.git_repos} repos. map/overview.md regenerated.`
    }

    if (args.action === "note") {
      if (!q || !args.text) throw new Error("note needs both `query` (path) and `text` (annotation).")
      const p = expand(q)
      if (!existsSync(p)) return `No such path: ${p}. Nothing queued.`
      const w = openRW()
      w.exec("CREATE TABLE IF NOT EXISTS notes_pending(id INTEGER PRIMARY KEY, path TEXT, text TEXT, created_at INT, session TEXT)")
      const dupe = one(w, "SELECT id FROM notes_pending WHERE path=? AND text=?", p, args.text)
      if (dupe) { w.close(); return `Already queued: "${args.text}"` }
      w.run("INSERT INTO notes_pending(path,text,created_at,session) VALUES(?,?,?,?)", p, args.text, Math.floor(Date.now() / 1000), context.sessionID)
      const n = one(w, "SELECT COUNT(*) c FROM notes_pending").c
      w.close()
      return `Queued annotation on ${short(p)}: "${args.text}"\n${n} pending — the user reviews with \`fsmap-notes review\` or /fsmap-review. It is NOT durable until promoted.`
    }

    const db = open()
    try {
      switch (args.action) {
        case "where": {
          if (!q) throw new Error("where needs a glob, e.g. '*waybar*'.")
          const role = args.role === "any" ? "" : " AND role=?"
          // Spread, never `+`: in JS `[a] + [b]` is a *string* concatenation
          // ("ab"), and spreading that string into the query call passed one
          // parameter per character, which surfaced as a bare
          // "column index out of range" from the driver.
          const params = [...[likePattern(q)], ...(role ? [args.role] : [])]
          const r = rows(db,
            `SELECT path, role, is_dir, size FROM paths
             WHERE path LIKE ? ESCAPE '\\'${role}
             ORDER BY is_dir DESC, length(path) LIMIT ?`, ...params, limit)
          if (!r.length) return `No indexed path matches ${q}${role ? ` with role=${args.role}` : ""}.`
          return r.map((x) =>
            `${x.is_dir ? "d" : "-"} ${x.role.padEnd(9)} ${String(x.size || "").padStart(9)}  ${short(x.path)}`
          ).join("\n")
        }

        case "what": {
          if (!q) throw new Error("what needs a path.")
          const p = expand(q)
          const n = one(db, "SELECT * FROM paths WHERE path=? OR path LIKE ? ESCAPE '\\' ORDER BY length(path) LIMIT 1", p, likePattern(p))
          if (!n) return `${p} is not indexed. It may be under a bulk or unindexed root — see map/overview.md.`
          const desc = one(db, "SELECT summary, source FROM descriptions WHERE path=?", n.path)
          const kids = rows(db, "SELECT path, role, is_dir, size FROM paths WHERE parent=? ORDER BY is_dir DESC, size DESC LIMIT 15", n.path)
          // "path LIKE '<dir>/%'" is written out rather than run through
          // likePattern(), which escapes % and wraps the term in % — that
          // would search for a *literal* percent sign and match no children.
          const desc2 = n.path + "/%"
          const notes = rows(db, "SELECT text FROM notes WHERE path=? OR path LIKE ? ESCAPE '\\' LIMIT 5", n.path, desc2)
          const pending = rows(db, "SELECT text FROM notes_pending WHERE path=? OR path LIKE ? ESCAPE '\\' LIMIT 5", n.path, desc2)
          const out = [`${n.path}`, `role=${n.role} depth=${n.depth}${n.is_dir ? " dir" : ""} size=${n.size}B mtime=${new Date(n.mtime * 1000).toISOString().slice(0, 10)}`]
          if (n.is_git) out.push(`git: ${n.git_remote ?? "(no remote)"} @ ${String(n.git_head).slice(0, 10)}`)
          if (desc) out.push(`description (${desc.source}): ${desc.summary}`)
          if (notes.length) out.push("annotations:\n" + notes.map((x) => "  - " + x.text).join("\n"))
          // Pending notes are shown too, flagged. A queued annotation that
          // `what` cannot see is a note the model can never re-read, which
          // defeats the point of queueing it.
          if (pending.length) out.push("pending (unconfirmed by the user yet, do not treat as fact):\n" + pending.map((x) => "  ? " + x.text).join("\n"))
          if (kids.length) {
            const byRole: Record<string, number> = {}
            for (const k of kids) byRole[k.role] = (byRole[k.role] || 0) + 1
            out.push(`children (${Object.entries(byRole).map(([k, v]) => `${v} ${k}`).join(", ")}):`)
            out.push(kids.map((k) => `  ${k.is_dir ? "d" : "-"} ${k.role.padEnd(9)} ${short(k.path)}`).join("\n"))
          }
          return out.join("\n")
        }

        case "find": {
          if (!q) throw new Error("find needs search terms.")
          // Match ANY term against the path, so "screenshot tool" finds files
          // named for either, and the whole phrase against descriptions,
          // which is where a multi-word concept would actually be described.
          const terms = q.split(/\s+/).filter(Boolean)
          const nameClause = terms.map(() => "p.path LIKE ? ESCAPE '\\'").join(" OR ")
          const r = rows(db,
            `SELECT DISTINCT p.path, p.role, p.is_dir, p.size, d.summary
             FROM paths p LEFT JOIN descriptions d ON d.path = p.path
             WHERE (${nameClause}) OR d.summary LIKE ? ESCAPE '\\'
             ORDER BY p.is_dir DESC, p.size DESC LIMIT ?`,
            ...terms.map(likePattern), `%${q}%`, limit)
          return r.length
            ? r.map((x) => `${x.is_dir ? "d" : "-"} ${x.role.padEnd(9)} ${short(x.path)}${x.summary ? `\n      ${x.summary}` : ""}`).join("\n")
            : `Nothing found for "${q}". Descriptions are heuristic and cover only ~${(one(db, "SELECT COUNT(*) c FROM descriptions").c)} files, so this is not proof of absence.`
        }

        case "repos": {
          const like = q ? likePattern(q) : "%"
          const r = rows(db,
            `SELECT path, git_remote, git_head FROM paths
             WHERE is_git=1 AND path LIKE ? ESCAPE '\\' ORDER BY path LIMIT ?`, like, limit)
          if (!r.length) return q ? `No git repo matches ${q}.` : "No repos indexed."
          return r.map((x) =>
            `${short(x.path)}\n    ${x.git_remote ?? "(no remote)"} @ ${String(x.git_head ?? "?").slice(0, 10)}`
          ).join("\n")
        }

        case "scripts": {
          const like = q ? likePattern(q) : "%"
          // is_exec comes from the real permission bits, so this returns actual
          // executables. Guessing from the filename instead surfaced
          // .gitignore, a vendored LICENSE and taskwarrior's doc/rc/refresh.
          const r = rows(db,
            `SELECT p.path, p.size, d.summary FROM paths p
             LEFT JOIN descriptions d ON d.path = p.path
             WHERE p.is_exec=1 AND p.role='signal' AND p.path LIKE ? ESCAPE '\\'
               AND (p.path LIKE '%/.local/bin/%' OR d.summary IS NOT NULL)
             ORDER BY p.path LIMIT ?`, like, limit)
          return r.length
            ? r.map((x) => `${short(x.path)} (${x.size}B)\n    ${x.summary ?? "(no description extracted)"}`).join("\n")
            : `No scripts match ${q || "*"}.`
        }

        case "changed": {
          const cut = Math.floor(Date.now() / 1000) - args.days * 86400
          const r = rows(db,
            `SELECT path, role, mtime, size FROM paths
             WHERE mtime > ? AND role IN ('signal','stale') ORDER BY mtime DESC LIMIT ?`, cut, limit)
          if (!r.length) return `Nothing changed in the last ${args.days} day(s).`
          return r.map((x) => `${new Date(x.mtime * 1000).toISOString().slice(0, 10)} ${x.role.padEnd(8)} ${short(x.path)}`).join("\n")
        }

        case "stale": {
          const r = rows(db,
            `SELECT name, mtime, path FROM paths
             WHERE role='stale' AND depth=1 AND root LIKE '%/.config' AND mtime < ?
             ORDER BY mtime LIMIT ?`,
            Math.floor(Date.now() / 1000) - args.days * 86400, limit)
          if (!r.length) return `No ~/.config dirs untouched for ${args.days} days.`
          return `Untouched ${args.days}+d (evidence of disuse, not proof — confirm before deleting):\n` +
            r.map((x) => `  ${new Date(x.mtime * 1000).toISOString().slice(0, 10)}  ~/.config/${x.name}`).join("\n")
        }
      }
      return `Unknown action: ${args.action}`
    } finally {
      db.close()
    }
  },
})
