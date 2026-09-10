#!/usr/bin/env bash
#
# devbox — install a console toolkit on a fresh Ubuntu machine.
# Idempotent: safe to re-run. See README.md.
#
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
OPT_BIN="/usr/local/bin"
CONFIG_DIR="$HOME/.config/devbox"
MARKER="# devbox toolkit"

DRY_RUN=0
ASSUME_YES=0
REQUESTED=""
SKIP=""

ALL_GROUPS="core git data http docker dev system agents"

# ---------------------------------------------------------------- output -----
if [ -t 1 ]; then
  B=$'\e[1m'; R=$'\e[0m'; GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; BLU=$'\e[34m'; DIM=$'\e[2m'
else B=""; R=""; GRN=""; YLW=""; RED=""; BLU=""; DIM=""; fi

say()  { printf '%s==>%s %s\n' "$BLU$B" "$R" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$GRN" "$R" "$*"; }
skip() { printf '  %s·%s %s%s%s\n' "$DIM" "$R" "$DIM" "$*" "$R"; }
warn() { printf '  %s!%s %s\n' "$YLW" "$R" "$*" >&2; }
die()  { printf '%sERROR:%s %s\n' "$RED$B" "$R" "$*" >&2; exit 1; }

run() {
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s %s\n' "$DIM" "$R" "$*"; return 0; fi
  "$@"
}

usage() {
  cat <<USAGE
${B}devbox${R} — console toolkit installer for Ubuntu 22.04/24.04 (x86_64)

  ./install.sh [options]

Options:
  -g, --groups LIST   comma-separated groups to install (default: all)
  -s, --skip LIST     comma-separated groups to skip
  -n, --dry-run       print what would happen, change nothing
  -y, --yes           don't prompt for confirmation
  -l, --list          list groups and exit
  -h, --help          this message

Groups:
  core      glow bat eza fd rg fzf tree yazi mc zoxide  (+ the 'tools' command)
  git       lazygit tig delta gh   (and git config: delta pager, zdiff3)
  data      sqlite3 psql yq jq jless csvlens
  http      xh mitmproxy lnav
  docker    docker engine + compose plugin, dive
  dev       watchexec hyperfine direnv sd uv
  system    btop procs dust ncdu
  agents    Claude Code, herdr        (alias: 'claude')

Examples:
  ./install.sh                          # everything
  ./install.sh -g core,git              # just the essentials
  ./install.sh --skip docker            # everything but docker
  ./install.sh --dry-run                # see the plan first
USAGE
}

# ------------------------------------------------------------------ args -----
while [ $# -gt 0 ]; do
  case "$1" in
    -g|--groups) REQUESTED="${2:-}"; shift 2 ;;
    -s|--skip)   SKIP="${2:-}"; shift 2 ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    -y|--yes)    ASSUME_YES=1; shift ;;
    -l|--list)   printf '%s\n' $ALL_GROUPS; exit 0 ;;
    -h|--help)   usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

# Build the group list word by word, so skipping never mangles a partial match.
_requested="${REQUESTED:-$ALL_GROUPS}"
SELECTED=""
for _g in ${_requested//,/ }; do
  [ "$_g" = "claude" ] && _g="agents"   # back-compat alias
  case " ${ALL_GROUPS} " in
    *" $_g "*) ;;
    *) printf 'ERROR: unknown group: %s (valid: %s)\n' "$_g" "$ALL_GROUPS" >&2; exit 2 ;;
  esac
  _drop=0
  for _s in ${SKIP//,/ }; do
    [ "$_s" = "claude" ] && _s="agents"
    [ "$_g" = "$_s" ] && _drop=1
  done
  [ "$_drop" = 1 ] || SELECTED="$SELECTED $_g"
done
SELECTED="${SELECTED# }"
[ -n "$SELECTED" ] || { printf 'ERROR: no groups left to install\n' >&2; exit 2; }

want() { case " $SELECTED " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------------------------------------------- preflight ---
preflight() {
  [ "$(id -u)" -ne 0 ] || die "run as a normal user, not root (the script calls sudo itself)"
  have sudo || die "sudo is required"
  . /etc/os-release 2>/dev/null || die "cannot read /etc/os-release"
  [ "${ID:-}" = "ubuntu" ] || [ "${ID_LIKE:-}" = "debian" ] \
    || die "this script targets Ubuntu/Debian; found ${PRETTY_NAME:-unknown}"
  ARCH="$(uname -m)"
  [ "$ARCH" = "x86_64" ] || die "only x86_64 is supported; found $ARCH.
The apt packages would work, but the pinned GitHub release binaries are amd64-only."
  UBUNTU_CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-noble}}"
  say "${PRETTY_NAME:-Linux} · $ARCH · groups: ${SELECTED// /, }"
  if [ "$DRY_RUN" = 0 ] && [ "$ASSUME_YES" = 0 ] && [ -t 0 ]; then
    printf 'Proceed? [y/N] '; read -r a; case "$a" in y|Y|yes) ;; *) die "aborted" ;; esac
  fi
  if [ "$DRY_RUN" = 0 ]; then sudo -v || die "sudo authentication failed"; fi
}

APT_UPDATED=0
apt_update_once() {
  [ "$APT_UPDATED" = 1 ] && return 0
  say "Refreshing apt index"
  run sudo apt-get update -qq
  APT_UPDATED=1
}

# Install apt packages, skipping any already present.
apt_install() {
  local pending=()
  for p in "$@"; do
    if dpkg -s "$p" >/dev/null 2>&1; then skip "$p already installed"; else pending+=("$p"); fi
  done
  [ ${#pending[@]} -eq 0 ] && return 0
  apt_update_once
  say "apt install: ${pending[*]}"
  run sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${pending[@]}"
  for p in "${pending[@]}"; do ok "$p"; done
}

# gh_bin <command> <repo> <version> <url> [archive-member]
# Downloads a release asset, extracts it, installs the named binary to /usr/local/bin.
gh_bin() {
  local cmd="$1" repo="$2" version="$3" url="$4"
  if have "$cmd"; then skip "$cmd already installed ($("$cmd" --version 2>&1 | head -1 | tr -d '\n' | cut -c1-40))"; return 0; fi
  say "Installing $cmd $version from $repo"
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s download %s\n' "$DIM" "$R" "$url"; return 0; fi

  # NB: no `trap ... RETURN` here. That trap stays armed after this function
  # returns and would then fire on an unrelated return with $tmp unset, which
  # `set -u` turns into a fatal error. Clean up explicitly instead.
  local tmp file found rc=0
  tmp="$(mktemp -d)" || { warn "mktemp failed"; return 1; }
  file="$tmp/${url##*/}"

  if curl -fsSL --retry 3 -o "$file" "$url"; then
    case "$file" in
      *.tar.gz|*.tgz) tar xzf "$file" -C "$tmp" || rc=1 ;;
      *.tar.xz)       tar xf  "$file" -C "$tmp" || rc=1 ;;
      *.zip)          unzip -oq "$file" -d "$tmp" || rc=1 ;;
      *)              chmod +x "$file" && sudo install -m755 "$file" "$OPT_BIN/$cmd" || rc=1
                      [ "$rc" = 0 ] && ok "$cmd"
                      rm -rf "$tmp"; return "$rc" ;;
    esac
    if [ "$rc" = 0 ]; then
      found="$(find "$tmp" -type f -name "$cmd" -perm -u+x 2>/dev/null | head -1)"
      [ -n "$found" ] || found="$(find "$tmp" -type f -name "$cmd" 2>/dev/null | head -1)"
      if [ -n "$found" ]; then
        sudo install -m755 "$found" "$OPT_BIN/$cmd" && ok "$cmd" || rc=1
      else
        warn "could not find '$cmd' inside ${url##*/}"; rc=1
      fi
    fi
  else
    warn "download failed: $url"; rc=1
  fi

  rm -rf "$tmp"
  return "$rc"
}

# ------------------------------------------------------------------ core -----
install_core() {
  apt_install bat fzf tree fd-find ripgrep eza mc ncdu zoxide unzip curl ca-certificates
  gh_bin glow charmbracelet/glow v3.0.0 \
    "https://github.com/charmbracelet/glow/releases/download/v3.0.0/glow_3.0.0_Linux_x86_64.tar.gz"
  gh_bin yazi sxyazi/yazi v26.9.1 \
    "https://github.com/sxyazi/yazi/releases/download/v26.9.1/yazi-x86_64-unknown-linux-gnu.zip"
  # Ubuntu renames these two; restore the conventional names.
  run mkdir -p "$LOCAL_BIN"
  if have batcat; then run ln -sf "$(command -v batcat)" "$LOCAL_BIN/bat"; ok "bat -> batcat"; fi
  if have fdfind; then run ln -sf "$(command -v fdfind)" "$LOCAL_BIN/fd";  ok "fd -> fdfind"; fi
  return 0
}

# ------------------------------------------------------------------- git -----
install_git() {
  apt_install git tig git-delta
  gh_bin lazygit jesseduffield/lazygit v0.65.0 \
    "https://github.com/jesseduffield/lazygit/releases/download/v0.65.0/lazygit_0.65.0_linux_x86_64.tar.gz"

  # GitHub CLI, from GitHub's own apt repo (Ubuntu's is often behind).
  if have gh; then skip "gh already installed ($(gh --version | head -1))"; else
    say "Adding the GitHub CLI apt repository"
    run sudo install -m 0755 -d /etc/apt/keyrings
    if [ "$DRY_RUN" = 0 ]; then
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    fi
    APT_UPDATED=0
    apt_install gh
  fi

  say "Configuring git"
  if have delta; then
    run git config --global core.pager "delta"
    run git config --global interactive.diffFilter "delta --color-only"
    run git config --global delta.navigate true
    run git config --global delta.line-numbers true
    ok "delta wired in as the diff pager"
  fi
  run git config --global merge.conflictStyle zdiff3
  run git config --global diff.colorMoved default
  ok "merge.conflictStyle=zdiff3, diff.colorMoved=default"
}

# ------------------------------------------------------------------ data -----
install_data() {
  apt_install sqlite3 postgresql-client jq
  gh_bin yq mikefarah/yq v4.53.6 \
    "https://github.com/mikefarah/yq/releases/download/v4.53.6/yq_linux_amd64"
  # jless links against X11 clipboard libraries.
  apt_install libxcb-render0 libxcb-shape0 libxcb-xfixes0
  gh_bin jless PaulJuliusMartinez/jless v0.9.0 \
    "https://github.com/PaulJuliusMartinez/jless/releases/download/v0.9.0/jless-v0.9.0-x86_64-unknown-linux-gnu.zip"
  gh_bin csvlens YS-L/csvlens v0.15.1 \
    "https://github.com/YS-L/csvlens/releases/download/v0.15.1/csvlens-x86_64-unknown-linux-gnu.tar.xz"
}

# ------------------------------------------------------------------ http -----
install_http() {
  apt_install lnav
  # upstream ships no glibc x86_64 build; the musl one is static and fine
  gh_bin xh ducaale/xh v0.26.2 \
    "https://github.com/ducaale/xh/releases/download/v0.26.2/xh-v0.26.2-x86_64-unknown-linux-musl.tar.gz"
  if have xh && [ "$DRY_RUN" = 0 ]; then sudo ln -sf "$OPT_BIN/xh" "$OPT_BIN/xhs"; fi
  install_uv
  if have mitmproxy; then skip "mitmproxy already installed"
  else
    say "Installing mitmproxy (uv tool — apt's build is several majors behind)"
    run uv tool install mitmproxy && ok "mitmproxy"
  fi
}

# ---------------------------------------------------------------- docker -----
install_docker() {
  if have docker; then skip "docker already installed ($(docker --version))"; else
    say "Adding Docker's official apt repository"
    run sudo install -m 0755 -d /etc/apt/keyrings
    if [ "$DRY_RUN" = 0 ]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
      echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    fi
    APT_UPDATED=0
    apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  run sudo systemctl enable --now docker
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    skip "$USER already in the docker group"
  else
    run sudo usermod -aG docker "$USER"
    warn "added $USER to the docker group — log out and back in (or run 'newgrp docker') before using docker without sudo"
  fi
  gh_bin dive wagoodman/dive v0.13.1 \
    "https://github.com/wagoodman/dive/releases/download/v0.13.1/dive_0.13.1_linux_amd64.tar.gz"
}

# ------------------------------------------------------------------- dev -----
install_uv() {
  if have uv; then skip "uv already installed ($(uv --version))"; return 0; fi
  say "Installing uv"
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s curl -LsSf https://astral.sh/uv/install.sh | sh\n' "$DIM" "$R"; return 0; fi
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 || { warn "uv install failed"; return 1; }
  export PATH="$LOCAL_BIN:$PATH"
  if have uv; then ok "uv"; else warn "uv not on PATH after install"; fi
  return 0
}

install_dev() {
  apt_install hyperfine direnv sd make
  gh_bin watchexec watchexec/watchexec v2.7.2 \
    "https://github.com/watchexec/watchexec/releases/download/v2.7.2/watchexec-2.7.2-x86_64-unknown-linux-gnu.tar.xz"
  install_uv
}

# ---------------------------------------------------------------- system -----
install_system() {
  apt_install btop ncdu
  gh_bin dust bootandy/dust v1.2.5 \
    "https://github.com/bootandy/dust/releases/download/v1.2.5/dust-v1.2.5-x86_64-unknown-linux-gnu.tar.gz"
  gh_bin procs dalance/procs v0.14.12 \
    "https://github.com/dalance/procs/releases/download/v0.14.12/procs-v0.14.12-x86_64-linux.zip"
}

# ---------------------------------------------------------------- agents -----
install_claude() {
  if have claude; then skip "claude already installed ($(claude --version 2>&1 | head -1))"; return 0; fi
  say "Installing Claude Code"
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s curl -fsSL https://claude.ai/install.sh | bash\n' "$DIM" "$R"; return 0; fi
  curl -fsSL https://claude.ai/install.sh | bash || { warn "Claude Code install failed"; return 1; }
  export PATH="$LOCAL_BIN:$PATH"
  if have claude; then ok "claude — run 'claude' once to authenticate"; else warn "claude not on PATH after install"; fi
  return 0
}

install_herdr() {
  if have herdr; then skip "herdr already installed ($(herdr --version 2>&1 | head -1))"; return 0; fi
  say "Installing herdr"
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s curl -fsSL https://herdr.dev/install.sh | sh\n' "$DIM" "$R"; return 0; fi
  # Official installer: picks the build for this platform from herdr.dev/latest.json,
  # verifies it against the manifest's SHA-256, installs to ~/.local/bin. No sudo.
  curl -fsSL https://herdr.dev/install.sh | sh || { warn "herdr install failed"; return 1; }
  export PATH="$LOCAL_BIN:$PATH"
  if have herdr; then ok "herdr — 'herdr update' self-updates it later"; else warn "herdr not on PATH after install"; fi
  return 0
}

install_agents() {
  install_claude
  install_herdr
  return 0
}

# ------------------------------------------------------------------ shell ----
install_shell() {
  say "Installing the 'tools' command and shell config"
  run mkdir -p "$LOCAL_BIN" "$CONFIG_DIR"
  run install -m755 "$REPO_DIR/bin/tools" "$LOCAL_BIN/tools"
  ok "$LOCAL_BIN/tools"
  run install -m644 "$REPO_DIR/shell/toolkit.sh" "$CONFIG_DIR/toolkit.sh"
  ok "$CONFIG_DIR/toolkit.sh"

  local rc="$HOME/.bashrc"
  [ -f "$rc" ] || run touch "$rc"

  # Remove any earlier inline blocks so definitions aren't duplicated.
  if grep -q "^# --- console toolkit (claude) ---\|^# --- extras toolkit (claude) ---" "$rc" 2>/dev/null; then
    if [ "$DRY_RUN" = 0 ]; then
      cp "$rc" "$rc.devbox-backup.$(date +%Y%m%d%H%M%S)"
      sed -i '/^# --- console toolkit (claude) ---$/,/^# --- end console toolkit ---$/d; /^# --- extras toolkit (claude) ---$/,/^# --- end extras toolkit ---$/d' "$rc"
    fi
    ok "removed earlier inline toolkit blocks (backup saved next to .bashrc)"
  fi

  if grep -qF "$MARKER" "$rc" 2>/dev/null; then
    skip "$rc already sources the toolkit"
  else
    if [ "$DRY_RUN" = 0 ]; then
      printf '\n%s\n[ -f "%s/toolkit.sh" ] && . "%s/toolkit.sh"\n' \
        "$MARKER" "$CONFIG_DIR" "$CONFIG_DIR" >> "$rc"
    fi
    ok "added one source line to ~/.bashrc"
  fi

  run mkdir -p "$HOME/.local/share/devbox"
  run cp "$REPO_DIR/docs/TOOLS.md" "$HOME/.local/share/devbox/TOOLS.md"
  ok "reference copied to ~/.local/share/devbox/TOOLS.md"
}

# ------------------------------------------------------------------- main ----
main() {
  preflight
  if want core;   then say "GROUP: core";   install_core;   fi
  if want git;    then say "GROUP: git";    install_git;    fi
  if want data;   then say "GROUP: data";   install_data;   fi
  if want http;   then say "GROUP: http";   install_http;   fi
  if want docker; then say "GROUP: docker"; install_docker; fi
  if want dev;    then say "GROUP: dev";    install_dev;    fi
  if want system; then say "GROUP: system"; install_system; fi
  if want agents; then say "GROUP: agents"; install_agents; fi
  install_shell

  echo
  say "Done."
  printf '  Restart your shell (or: %ssource ~/.bashrc%s) then run %stools%s.\n' "$B" "$R" "$B" "$R"
  if want docker && ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    printf '  %sDocker needs a new login session before it works without sudo.%s\n' "$YLW" "$R"
  fi
  return 0
}

main "$@"
