# Navi cheat file syntax

Full reference: https://github.com/denisidoro/navi/blob/master/docs/cheatsheet/syntax/README.md

## File format

| Element | Syntax | Description |
|---------|--------|-------------|
| Tags    | `%`    | Start of a new cheat, contains tags for searching |
| Description | `#` | Description of the cheat |
| Comment | `;` | Ignored by navi, useful as editor comments |
| Variables | `$` | Lines defining variable values/commands |
| Extend | `@` | Tags from another cheat to share context/variables |
| Snippet | (other lines) | Executable commands |

## Variables

Variables in commands use `<variable_name>` syntax. Names: alphanumeric + `_` only.

```
$ variable: value                         # literal value
$ variable: command                       # command output = selectable choices
$ variable: command --- --flags           # command output with flags
$ variable: --- --flags                   # no choices, just flags
```

### Flags (after `---`)

| Flag | Description |
|------|-------------|
| `--multi` | Allow selecting/entering multiple values |
| `--map "script"` | Transform/validate the selected value via shell script |
| `--expand` | Split each line into a separate argument |
| `--prevent-extra` | Force selection from suggestions only |
| `--column N` | Extract Nth column from command output |
| `--fzf-overrides "arg"` | Pass arbitrary arg to fzf |
| `--header-lines N` | Skip N header lines in fzf preview |
| `--delimiter "regex"` | Field delimiter for column extraction |
| `--query "text"` | Pre-fill fzf search query |
| `--filter "text"` | Filter fzf results without interactive mode |
| `--header "text"` | Header text for fzf |
| `--preview "code"` | Preview command for fzf |
| `--preview-window "pos"` | Preview window position |

### Providing selectable choices

```bash
$ variable: echo -e "choice1\nchoice2\nchoice3"
```
The output of the command (one per line) becomes the selectable options.

### Escaped backslash sequences in choices (4-backslash rule)

To offer a choice whose value contains a literal backslash escape (e.g. `'\r'` so that `tr` interprets it as carriage return), write FOUR backslashes in the file — two are consumed by shell double-quote parsing, two by `echo -e`:

```bash
$ delete: echo -e "'\\\\r'\n' '"   # file has 4 backslashes
```

- Layering: file `\\\\r` → shell dq unescape → `\\r` → `echo -e` → `\r` → choice is `'\r'`
- With only two backslashes (`'\\r'`) `echo -e` emits a real carriage-return byte (or a real newline for `\n`), silently producing a broken choice
- After writing such a line, verify by running the exact `$ var:` command and inspecting its output

### No per-choice descriptions

Navi has no documented way to attach a description to an individual choice line — the FULL line is substituted as the variable value. Do not append trailing text like `'a-z'  lowercase` or `# comment` to choice lines; it lands in the command. Instead: raw values + `#` cheat description + `;` editor comments.

### Validating/transforming typed input (no choices)

```bash
$ variable: --- --map "awk '{if (\$1 >= 0 && \$1 <= 1) print \$1; else {print \"Error msg\"; exit 1}}'"
```
- `---` with no command before it = empty input field, user types freely
- `--map` pipes the user's typed input through the script for validation/transformation
- Do NOT put `echo "instruction"` before `---` — that text becomes the ONLY selectable choice instead of a prompt

### Combining flags

```bash
$ color: --- --multi --map "tr -d '#'"
```
- `--multi` allows multiple values
- `--map` transforms each value (here: strips `#` from colors)

### Variable dependency

```bash
$ x: echo -e "hello\nhi"
$ y: echo "$x foo;$x bar" | tr ';' '\n'           # explicit: $x refers to <x> value
```

- **Implicit**: use `<variable>` in command body
- **Explicit**: use `$variable` in variable definitions

### Extending cheats

Share variable context across cheats using `@`:

```
% dirs, common
$ pictures_folder: echo "/my/pictures"

% wallpapers
@ dirs, common
echo "<pictures_folder>/wallpapers"
```

### Multiline snippets

Backslash continuation:
```
echo foo
true \
   && echo yes \
   || echo no
```

Or markdown code blocks:
```sh
echo foo
true && echo yes
```

### Multiple variable definitions (for multi-line options)

Do NOT repeat `$ variable: value` on separate lines — navi 2.24.0 may not show them as choices. Use `echo -e "a\nb\nc"` instead.

## Patterns & recipes

### Pattern: "choose the direction" (case conversion, etc.)

Provide a variable with the two mode-specific tokens, then plug it into the command template:

```bash
% shell, text, case, sed
# Convert piped text to lowercase or uppercase using sed
$ case: echo -e '\\L\n\\U'
$ text: ---
echo "<text>" | sed 's/.*/<case>&/'
```

- The variable choices are the raw tokens (`\L` / `\U`)
- They get substituted directly into the sed expression via `<case>`
- `echo -e '\\L\n\\U'` — single quotes preserve `\\`, then `echo -e` interprets `\\` → `\`, so choices are literally `\L` and `\U`

### Pattern: variable with embedded quotes for multi-argument commands

When a variable needs to expand to multiple shell words (including quotes), bake the quotes into the choice strings:

```bash
$ tr_args: echo -e "'[:upper:]' '[:lower:]'\n'[:lower:]' '[:upper:]'"
$ text: ---
echo "<text>" | tr <tr_args>
```

- Choice 1 is the literal string `'[:upper:]' '[:lower:]'`
- Choice 2 is `'[:lower:]' '[:upper:]'`
- After substitution, the shell consumes the single quotes normally, passing two separate arguments to `tr`
- Baking both args into ONE choice keeps the pair coherent — the user can't select a mismatched SET1/SET2 (e.g. `tr 'atgc' 'A-Z'`). Use this whenever multiple arguments must stay consistent (tr mappings, key-value pairs, etc.)

### Pattern: optional command segment via empty variable choice

Toggle part of a command on/off by making the first variable choice empty and the second the segment to insert:

```bash
$ delete: echo -e "\n&& gio trash \"\$f\""
$ dir: ---
for f in "$dir"/*.{zip,tar.gz,rar,7z}(N); do aunpack "$f"<delete>; done
```

- `<delete>` resolves to empty (just `aunpack`) or `&& gio trash "$f"` (extract + trash)
- `echo -e "\n<text>"` produces two lines: an empty first line and the optional text as the second
- Works for any toggleable suffix (pipe, redirect, flag, chained command, etc.)

### Pattern: file-input for stdin-reading tools

For tools that read stdin (tr, grep, awk, sort, ...), read from a file with redirection instead of wrapping an `echo`:

```bash
$ file: ---
tr -d '\r' < <file>
```

- `cmd < <file>` — navi substitutes `<file>`; the leading `<` is plain shell redirection, not part of the variable
- Document the follow-ups in a header comment: append `> out.txt` to save, and the in-place idiom `cmd < file > file.tmp && mv file.tmp file` for tools without `-i`
- A free-input `$ file: ---` prompt is fine; escalate to selectable choices (`$ file: find . -maxdepth 2 -type f | sort`) only if the user wants file picking from the cwd

### Multiple cheats per file

A `.cheat` file can contain multiple `% tag` sections. Each section is a separate cheat that navi lists in its search results. Variables are scoped to their section.

### Description as user guidance

Use the `#` description line for usage hints, especially when a cheat has variables that are mutually exclusive or have other constraints. This is the first thing the user sees when browsing cheats.

## Conventions

When adding optional arguments as selectable choices in a navi cheat, the default (first) option should be blank. This lets the user mash Enter to get a working command with no extra flags. For example, `maxdepth` and `name_filter` should default to blank — you add them only when needed.

Don't make the default blank for arguments that are required for the command to execute. For example, `type` needs `-type f` or `-type l` — the command won't find anything without one, so keep the most common choice first rather than a blank.

## Agent behavior

If you discover something about navi that would be useful to add to this agent file for future sessions, wait until the user indicates they're satisfied with the cheats designed so far (a simple "looks good", "great", etc. is enough — the signal doesn't need to be strong), then mention the suggestion and ask if they'd like it added. This is lower priority than actually writing cheats.
