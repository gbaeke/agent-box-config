# Console toolkit

A reference for the terminal tools installed by [devbox](../README.md) on Ubuntu.

Run **`tools`** for a live, colourised version of this in the terminal:

```bash
tools           # full cheatsheet with detected versions
tools git       # only entries matching "git"
tools -c        # compact installed/missing check
```

`tools` reads versions from the binaries themselves, so it never goes stale. If a version
mentioned here ever disagrees with `tools -c`, trust `tools -c`.

---

## Markdown

### glow — render markdown in the terminal
The main reason this toolkit exists. Renders markdown with styled headings, tables and
syntax-highlighted code blocks.

```bash
glow README.md          # render one file
glow .                  # browsable TUI list of every .md file in the tree
glow -p README.md       # force the pager (arrows scroll, q quits)
glow -w 100 FILE.md     # wrap at 100 columns
```

`glow .` is the one to remember — it finds all markdown under the current directory and
lets you pick from a list, which beats hunting for paths.

### bat — `cat` with syntax highlighting
Drop-in `cat` replacement with line numbers, a git-change gutter, and paging.

```bash
bat src/main.py            # highlighted, with line numbers
bat -p FILE                # plain: no numbers or decorations
bat -r 40:80 FILE          # just lines 40-80
bat -A FILE                # reveal tabs, spaces and line endings
bat -l yaml < some-input   # force a language when reading stdin
```

Installed as `batcat` by Debian/Ubuntu (a name clash with another package); there is a
`bat` symlink in `~/.local/bin`. It is also wired in as your `man` pager, so `man rsync`
now comes out highlighted.

---

## File navigation

### yazi — TUI file manager with previews
Fast, keyboard-driven, shows a live preview of whatever is selected (including images and
markdown).

```bash
y      # open yazi here
yy     # open yazi, and cd to wherever you ended up when you quit
```

Inside: arrows or `hjkl` to move, `Enter` open, `/` filter, `Space` select, `y`/`x`/`p`
copy/cut/paste, `d` delete, `q` quit. Use `yy` rather than `y` when the point is to
navigate somewhere and then keep working there — plain `y` leaves you where you started.

### mc — Midnight Commander
The classic orthodox two-pane file manager. Better than yazi for bulk copy/move between
two directories, and for editing over a slow connection.

```bash
mc
```
`Tab` switch pane, `F3` view, `F4` edit, `F5` copy, `F6` move, `F7` mkdir, `F8` delete,
`F10` quit.

### eza — a modern `ls`
Colour by file type, human sizes, and a git status column.

```bash
ls                      # aliased: eza --group-directories-first
ll                      # aliased: long, all, with git status
lt                      # aliased: tree, 2 levels, respects .gitignore
eza -l --sort=modified  # newest last
eza -l --total-size     # real recursive directory sizes
```

### zoxide — jump to directories by frecency
Learns the directories you visit and ranks them by frequency + recency. Probably the
biggest day-to-day time saver here.

```bash
z myproject   # jumps to ~/projects/myproject from anywhere
z myproj src  # matches on multiple fragments
zi            # pick interactively from a fuzzy list
```

It only knows directories you have visited since it was installed, so it feels dumb for a
day and then becomes very good.

### fzf — fuzzy finder over anything
Filters any list on stdin. Its real value is the shell keybindings:

- **ctrl-t** — insert a file path into the command line you are typing (with a bat preview)
- **ctrl-r** — fuzzy-search your shell history
- **alt-c** — cd into a subdirectory

```bash
vim "$(fzf)"                       # pick a file to edit
git switch "$(git branch | fzf)"   # pick a branch
```

### fd — a fast, sane `find`
Respects `.gitignore`, skips hidden files by default, regex by default, and is much faster.

```bash
fd config              # anything matching "config"
fd -e py               # all Python files
fd -e yaml . config    # by extension, under one directory
fd -H -I secret        # include hidden and ignored files
fd -e py -x wc -l      # run a command per match
```

Installed as `fdfind` by Ubuntu; there is an `fd` symlink in `~/.local/bin`.

### rg (ripgrep) — a fast recursive grep
Searches file contents. Respects `.gitignore`, so it does not waste time in `.venv`.

```bash
rg "parse_config"               # search everything below here
rg -i tokenizer                 # case-insensitive
rg -t py "async def"            # only Python files
rg -l sqlalchemy                # just list matching filenames  
rg -C 3 "raise ValueError"      # 3 lines of context
rg "def (get|post)" -o          # print only the matched text
```

### tree — plain directory tree
```bash
tree -L 2       # two levels deep
tree -d         # directories only
tree -a         # include hidden
```

---

## Git

### lazygit — the git TUI
Does most of what you would otherwise do with a dozen commands. The killer feature is
staging **individual hunks or lines** without touching `git add -p`.

```bash
lg    # aliased to lazygit
```

Inside: `Space` stage/unstage the selected file or hunk, `Enter` drill into a file to stage
line by line, `c` commit, `A` amend, `P` push, `p` pull, `b` branches, `r` rebase,
`?` help for the current panel, `q` quit.

### tig — history and blame browser
Read-only, fast, good for archaeology.

```bash
tig                  # commit log; Enter opens a commit's diff
tig blame FILE       # who last touched each line
tig status           # a navigable git status
tig FILE             # history of just that file
```

### delta — the diff pager
Already wired into git globally, so every `git diff`, `git show` and `git log -p` renders
with line numbers, intra-line highlighting and colour-moved detection.

```bash
git diff                                          # already goes through delta
git -c delta.side-by-side=true diff               # side-by-side for one command
git diff | delta                                  # explicit
n / N                                             # next/previous file within a diff
```

---

## Data and config

For projects configured by YAML and backed by a SQL database.

### sqlite3 — query a SQLite database

```bash
sqlite3 app.db ".tables"                    # what tables exist
sqlite3 app.db ".schema users"              # DDL for one table
sqlite3 -header -column app.db "SELECT * FROM users ORDER BY id DESC LIMIT 5;"
sqlite3 app.db ".mode csv" ".output out.csv" "SELECT * FROM events;"
```
`-header -column` is what makes output readable; without it you get pipe-separated soup.

### psql — the Postgres client
For a local or containerised Postgres.

```bash
psql -h localhost -U myuser -d mydb
PGPASSWORD=secret psql -h localhost -U myuser -d mydb   # non-interactive
\dt          # list tables
\d+ users    # describe a table
\x           # toggle expanded output (good for wide rows)
\q           # quit
```

### yq — jq for YAML
Reads and edits YAML the way jq reads JSON.

```bash
yq '.server' config.yaml              # one subtree
yq 'keys' config.yaml                 # top-level keys
yq '.items[].name' config.yaml        # pull a field from every list item
yq -o=json '.' config.yaml            # convert YAML to JSON
yq -i '.server.port = 8080' config.yaml   # edit in place
yq '.services | keys' docker-compose.yml  # what a compose file defines
```

This is mikefarah/yq v4 (Go). Note the apt package of the same name is a different,
incompatible Python tool — this is the one whose syntax matches jq.

### jq — slice and filter JSON
```bash
jq . file.json                 # pretty-print
jq -r '.[].url' file.json      # raw strings, no quotes
jq 'map(select(.status==200)) | length' file.json
jq -s 'add' *.json             # slurp several files into one array
```

### jless — a JSON viewer
For payloads too big to read as a wall of `jq` output.

```bash
jless big.json
```
`Enter`/`Tab` expand or collapse, `/` search, `n`/`N` next/previous match, `q` quit.

### csvlens — a CSV viewer
Frozen headers, real column alignment, search — much better than opening a CSV in a pager.

```bash
csvlens export.csv
csvlens -d '\t' file.tsv    # tab-separated
```
`/` search, `arrows` scroll, `q` quit.

---

## HTTP and network debugging

### xh — a fast HTTP client
A curl replacement with a far more humane syntax — the quickest way to see what a
server actually returns.

```bash
xh HEAD example.com                     # status and headers only
xh example.com/robots.txt               # is crawling even allowed
xh --follow example.com                 # follow redirects
xh GET api.example.com/search q==python # query params with ==
xh POST api.example.com name=value      # JSON body by default
xh -p Hh example.com                    # print request+response headers only
xhs example.com                         # same, forcing https
```

### mitmproxy — see the requests your code actually makes
An interception proxy. Point any HTTP client at it and watch every request and response —
the reliable way to find out why a library behaves differently from `curl`, or which
requests are being retried.

```bash
mitmproxy -p 8080     # interactive TUI
mitmweb -p 8080       # browser UI instead
mitmdump -p 8080 -w capture.flows   # headless, record to a file
```
Then run your program with `HTTP_PROXY=http://localhost:8080` /
`HTTPS_PROXY=http://localhost:8080`. For HTTPS you must trust mitmproxy's CA
(generated at `~/.mitmproxy/` on first run).

### lnav — the log navigator
Understands common log formats, merges multiple files into one timeline, colourises by
level, and lets you run SQL over the parsed lines.

```bash
lnav app.log
lnav logs/              # merge every file in a directory, ordered by time
```
`/` search, `e`/`E` jump to next/previous error, `:filter-out DEBUG` hide noise,
`;SELECT ...` query the log as a table, `q` quit.

---

## Docker

### docker — containers
Docker Engine plus the Compose v2 plugin.

```bash
docker compose up -d             # start the stack defined by docker-compose.yml
docker compose down
docker compose ps                # what is running
docker compose logs -f web       # follow one service
docker compose exec db psql -U myuser -d mydb
docker build -t myapp:latest .
docker ps / docker images / docker system df
```

Services behind Compose **profiles** do not start by default:

```bash
docker compose --profile tools up -d       # only the services in that profile
```

> **Note:** using `docker` without `sudo` requires the `docker` group, which only takes
> effect in a *new* login session. If you get a permission error on the socket, log out and
> back in, or run `newgrp docker` once.

### dive — inspect image layers
Shows what each layer added and how much space is wasted — the fastest way to work out
why an image is far bigger than it should be.

```bash
dive myapp:latest
```
`Tab` switches between the layer list and the file tree.

---

## Development

### watchexec — rerun a command when files change
```bash
watch-tests                              # aliased: watchexec -e py -- make test-fast
watchexec -e py -- pytest tests/test_thing.py
watchexec -e py,yaml --clear -- make lint
watchexec -w src -- npm run build        # watch one directory
```

### hyperfine — benchmarking that means something
Runs a command many times, discards warmup, and reports mean ± stddev, so you can tell a
real improvement from noise.

```bash
hyperfine 'make build'
hyperfine -w 3 './myprog --input data.json'           # 3 warmup runs first
hyperfine 'rg TODO' 'grep -r TODO .'                 # compare two commands
```

### direnv — per-directory environment
Loads a `.envrc` when you cd into a directory and unloads it when you leave. Good for
a per-project `DATABASE_URL` and API keys without polluting your shell.

```bash
echo 'export DATABASE_URL=sqlite:///./data/app.db' > .envrc
direnv allow      # required once, and again after every edit
```
Add `.envrc` to `.gitignore` if it holds anything secret.

### sd — find and replace, without sed's syntax
```bash
sd 'old_name' 'new_name' src/*.py
sd -p 'foo' 'bar' FILE                     # preview the diff, change nothing
fd -e py -x sd 'requests\.get' 'client.get'   # across the whole tree
```

---

## System

### btop — resource monitor
```bash
top     # aliased to btop
```
`m` sort by memory, `p` by CPU, `f` filter, `k` kill the selected process, `q` quit.

### procs — a modern `ps`
```bash
procs             # everything, coloured, with human columns
procs python      # filter by name
procs --tree      # parent/child hierarchy
procs --sortd cpu # sort descending by CPU
```

### dust — disk usage, biggest first
```bash
dust             # or the du2 alias
dust -d 2        # limit depth
dust -r          # reverse (biggest last)
```

### ncdu — interactive disk usage
Better than dust when you want to *delete* things, not just look.
```bash
ncdu .
```
Arrows navigate, `d` delete, `n`/`s` sort by name/size, `q` quit.

---

## AI coding agents

### claude — Claude Code
Anthropic's agentic coding tool: it reads and edits files, runs commands and drives git
from the terminal.

```bash
claude                  # start a session in the current directory
claude -c               # resume the most recent session
claude -p "..."         # one-shot, print the answer and exit
claude update           # update to the latest version
```
Run it once to authenticate. Inside a session, `/help` lists commands, `/config` opens
settings, and `Ctrl+C` interrupts whatever it is doing.

### herdr — terminal workspace manager for coding agents
Keeps several agent sessions alive side by side in one window, tracks what each one is
doing (working, idle, waiting for approval, asking a question), and survives disconnects
the way tmux does — but it understands agents rather than plain shells.

```bash
herdr                              # launch or attach to the persistent session
herdr --session myproject          # a named session, kept separate
herdr --remote user@host           # attach to a Herdr server over SSH
herdr status                       # client and server status
herdr machine add                  # save an SSH machine to manage from one window
herdr worktree <subcommand>        # git worktree helpers, for parallel agent branches
herdr update                       # self-update
herdr channel set preview          # switch to the preview release channel
```

Config lives at `~/.config/herdr/config.toml`, logs beside it at `herdr.log`
(plus `herdr-client.log` and `herdr-server.log`). `HERDR_CONFIG_PATH` overrides the
config location. `herdr --skill` prints an agent skill file describing its own API,
which is handy to hand to an agent working inside it.

Because it holds sessions open, it pairs naturally with `--remote`: run the server on
the box doing the work and attach from a laptop, and agents keep running when you
disconnect.

---

## Shell reference

| Key / alias | Does |
|---|---|
| `ctrl-t` | insert a file path into the current command |
| `ctrl-r` | fuzzy-search shell history |
| `alt-c` | cd into a subdirectory |
| `z DIR` / `zi` | jump by frecency / pick interactively |
| `y` / `yy` | yazi / yazi-then-cd |
| `lg` | lazygit |
| `ll` / `lt` | eza long+git / eza tree |
| `top` | btop |
| `du2` | dust |
| `http` | xh |
| `watch-tests` | rerun `make test-fast` on any `.py` change (assumes such a target) |
| `\cat` | the *real* `cat` — plain `cat` is aliased to bat |

---

## What the installer changes

**`~/.config/devbox/toolkit.sh`** — the aliases above, the fzf keybindings, the zoxide and
direnv init lines, `BAT_THEME`, `MANPAGER`, and the `yy` function.

**`~/.bashrc`** — a single line sourcing that file, under a `# devbox toolkit` marker.
Delete the marker and the line after it to undo the shell changes.

**`~/.local/bin`** — the `tools` script, plus `bat` → `batcat` and `fd` → `fdfind`
symlinks (Ubuntu ships those two under different names).

**Global git config:**

| Setting | Value |
|---|---|
| `core.pager` | `delta` |
| `interactive.diffFilter` | `delta --color-only` |
| `delta.navigate` | `true` |
| `delta.line-numbers` | `true` |
| `merge.conflictStyle` | `zdiff3` |
| `diff.colorMoved` | `default` |

**Group membership** — your user is added to `docker` (needs a new login session).

## Where each tool came from

- **apt (Ubuntu repos):** bat, fzf, tig, tree, fd-find, ncdu, mc, git-delta, eza, ripgrep,
  sqlite3, postgresql-client, lnav, hyperfine, zoxide, btop, sd, direnv
- **apt (Docker's official repo):** docker-ce, docker-ce-cli, containerd.io,
  docker-buildx-plugin, docker-compose-plugin
- **GitHub releases, into `/usr/local/bin`:** glow, lazygit, yazi, yq, jless, csvlens, xh,
  dust, procs, watchexec, dive
- **Vendor install scripts:** Claude Code (`claude.ai/install.sh`), herdr
  (`herdr.dev/install.sh` — resolves the build from `latest.json` and verifies its
  SHA-256), uv (`astral.sh/uv/install.sh`). All three install to `~/.local/bin`, no sudo.
- **uv tool:** mitmproxy (apt's version is four majors behind; upgrade with
  `uv tool upgrade mitmproxy`)

Updating: apt tools come with `sudo apt update && sudo apt upgrade`. The `/usr/local/bin`
binaries were installed by hand and do **not** auto-update — re-download from the project's
releases page when you want a newer one.

## Adding a tool to the `tools` command

Add one pipe-separated line to the `data()` heredoc in `~/.local/bin/tools`:

```
SECTION|command|what it does|how you use it
```

Layout and version detection are automatic. Only tools with unusual `--version` output
need a case added to the `ver()` function (yazi, lazygit, eza, ncdu, mc, procs, sqlite3,
psql, btop, docker and mitmproxy already have one).
