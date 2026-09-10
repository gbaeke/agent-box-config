# devbox

One script that turns a fresh Ubuntu box into a comfortable terminal working
environment: 30-odd modern CLI tools, Docker, the GitHub CLI, and the agent
tooling (Claude Code and herdr).

```bash
git clone <this-repo> devbox && cd devbox
./install.sh
```

Then restart your shell and run `tools` for a cheatsheet of everything that was
installed.

---

## What you get

| Group | Tools |
|---|---|
| `core` | glow, bat, eza, fd, ripgrep, fzf, tree, yazi, mc, zoxide, ncdu |
| `git` | lazygit, tig, delta, **gh** (+ git configured to use delta) |
| `data` | sqlite3, psql, yq, jq, jless, csvlens |
| `http` | xh, mitmproxy, lnav |
| `docker` | Docker Engine + Compose plugin, dive |
| `dev` | watchexec, hyperfine, direnv, sd, uv, make |
| `system` | btop, procs, dust, ncdu |
| `agents` | **Claude Code**, **herdr** (alias: `claude`) |

Every tool is described — what it does, why you'd use it, and worked examples —
in **[docs/TOOLS.md](docs/TOOLS.md)**. Read it rendered with `glow docs/TOOLS.md`
once the `core` group is installed.

## Usage

```bash
./install.sh                      # everything (default)
./install.sh --dry-run            # print the plan, change nothing
./install.sh -g core,git          # only those groups
./install.sh --skip docker        # everything except docker
./install.sh --list               # list group names
./install.sh --help
```

`--dry-run` requires no sudo and touches nothing, so it is a safe first move on an
unfamiliar machine.

### Re-running is safe

The script is idempotent. Anything already present is detected and skipped rather
than reinstalled, so you can re-run it after adding a group, or on a machine that
is half set up already. Re-running is also how you adopt changes after a `git pull`.

## Requirements

- Ubuntu 22.04 or 24.04 (or a Debian derivative), **x86_64**
- A normal user account with `sudo` — do *not* run the script as root
- Outbound HTTPS to apt, github.com, astral.sh, claude.ai and herdr.dev

The script refuses to run on other architectures rather than installing a broken
mix: the apt packages are fine anywhere, but the pinned release binaries are
amd64-only. On arm64, install the `core` apt packages by hand and fetch aarch64
builds for the rest.

## What it changes on the machine

Everything it touches, so you can undo it:

| Path | What |
|---|---|
| `/usr/local/bin/` | binaries fetched from GitHub releases (glow, lazygit, yazi, yq, jless, csvlens, xh, dust, procs, watchexec, dive) |
| `~/.local/bin/tools` | the cheatsheet command |
| `~/.local/bin/bat`, `~/.local/bin/fd` | symlinks, because Ubuntu ships these as `batcat` and `fdfind` |
| `~/.config/devbox/toolkit.sh` | aliases, fzf keybindings, zoxide/direnv init, the `yy` function |
| `~/.bashrc` | **one** line sourcing the file above |
| `~/.local/share/devbox/TOOLS.md` | a copy of the reference doc |
| `/etc/apt/sources.list.d/` | the Docker and GitHub CLI apt repos, with keyrings in `/etc/apt/keyrings/` |
| global git config | `core.pager=delta`, `interactive.diffFilter`, `delta.navigate`, `delta.line-numbers`, `merge.conflictStyle=zdiff3`, `diff.colorMoved=default` |
| groups | adds you to `docker` |

Shell configuration lives in its own file rather than being pasted into
`~/.bashrc`, so updating it is a `git pull` plus a re-run, and removing it is one
line. If the script finds inline blocks from an earlier manual setup it strips
them (after backing `~/.bashrc` up beside itself) so nothing ends up defined twice.

### Uninstalling

```bash
sed -i '/# devbox toolkit/,+1d' ~/.bashrc     # stop sourcing the shell config
rm -rf ~/.config/devbox ~/.local/bin/tools
sudo rm -f /usr/local/bin/{glow,lazygit,yazi,ya,yq,jless,csvlens,xh,xhs,dust,procs,watchexec,dive}
rm -f ~/.local/bin/{claude,herdr}   # and ~/.config/herdr, ~/.claude if you want them gone
```
apt packages come off with `sudo apt remove`, and git settings with
`git config --global --unset <key>`.

## After installing

1. **Restart your shell** (or `source ~/.bashrc`) — aliases and keybindings need it.
2. **Docker needs a new login session.** Group membership doesn't apply to shells
   that are already open. Log out and back in, or `newgrp docker` once, otherwise
   you'll get a permission error on the socket.
3. **`claude`** — run it once to authenticate.
4. **`herdr`** — launches or attaches to the persistent agent workspace; it
   self-updates later with `herdr update`.
5. **`gh auth login`** — authenticate the GitHub CLI.
6. **`tools`** — the cheatsheet.

## Design notes

**Versions are pinned.** Each GitHub-release binary is fetched at a known version
rather than resolving "latest" at install time, so two machines built a month
apart get the same thing and a broken upstream release can't silently land on your
box. Bump them in `install.sh` when you want to move.

**Sources are chosen per tool, not by dogma.** apt where the packaged version is
current, upstream repos for Docker and gh (Ubuntu's lag badly), GitHub releases for
tools apt doesn't carry, `uv tool` for mitmproxy (apt's build is several major
versions behind), and the vendors' own install scripts for Claude Code, herdr and
uv. Those three install into `~/.local/bin` without sudo, and herdr's checks the
download against a SHA-256 from its release manifest.

**The agent tools update themselves.** `claude update` and `herdr update` are the
right way to move those forward, so the script pins nothing for them — it only
installs them when missing.

**`xh` is the musl build.** Upstream publishes no glibc x86_64 binary. It's
statically linked and works fine.

**`jless` needs X11 clipboard libraries** (`libxcb-render0`, `libxcb-shape0`,
`libxcb-xfixes0`) even headless, or it fails at startup with a missing-shared-object
error. The script installs them.

## Layout

```
install.sh        the installer
bin/tools         the cheatsheet command, installed to ~/.local/bin
shell/toolkit.sh  aliases and shell integration, installed to ~/.config/devbox
docs/TOOLS.md     full reference for every tool
```

### Adding a tool

Add it to the relevant `install_*` function in `install.sh` — `apt_install NAME`
for apt, or `gh_bin CMD REPO VERSION URL` for a GitHub release (the helper handles
`.tar.gz`, `.tar.xz`, `.zip` and bare binaries, and skips the work if the command
already exists). Then add a line to the `data()` heredoc in `bin/tools`:

```
SECTION|command|what it does|how you use it
```

and a section to `docs/TOOLS.md`.
