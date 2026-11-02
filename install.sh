#!/usr/bin/env bash
#
# Installs Nix if it's missing, then applies home-manager from this flake. No root needed if /nix is
# writable. `coder dotfiles` runs this on workspace start
#
#   ./install.sh [home-configuration]   by default dev-workspace-secrets if this machine can use it,
#                                       otherwise dev-workspace
#
set -euo pipefail

nix_version=2.35.4
secrets_repo=ssh://git@github.com/CertifiKate/nix-secrets.git

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export USER=${USER:-$(id -un)}
config=${1:-}

# Coder sets its own for git. Otherwise a missing key or unknown host would sit waiting on a prompt
export GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new}

PATH="$HOME/.nix-profile/bin:$PATH"

if ! command -v nix >/dev/null; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  # The installer's tarball needs xz, which stock Debian images don't have
  if ! command -v xz >/dev/null; then
    cat >"$tmp/xz" <<'EOF'
#!/bin/sh
exec python3 -c 'import lzma, shutil, sys; shutil.copyfileobj(lzma.open(sys.stdin.buffer), sys.stdout.buffer)'
EOF
    chmod +x "$tmp/xz"
    PATH="$tmp:$PATH"
  fi

  curl -fsSL "https://releases.nixos.org/nix/nix-$nix_version/install" |
    sh -s -- --no-daemon --no-channel-add --no-modify-profile
fi

# No sandbox, as that needs root
export NIX_CONFIG="experimental-features = nix-command flakes
sandbox = false
${NIX_CONFIG:-}"

# Lets a template hand over the home-manager age key, which is otherwise added by hand
if [ -n "${CERTIFIKATE_HOST_KEY:-}" ]; then
  mkdir -p "$HOME/.config"
  (umask 077 && printf '%s\n' "$CERTIFIKATE_HOST_KEY" >"$HOME/.config/sops-age.txt")
  chmod 600 "$HOME/.config/sops-age.txt"
  unset CERTIFIKATE_HOST_KEY
fi

if [ -z "$config" ]; then
  config=dev-workspace
  if [ -f "$HOME/.config/sops-age.txt" ] && timeout 20 git ls-remote "$secrets_repo" >/dev/null 2>&1; then
    config=dev-workspace-secrets
  fi
fi
echo "Applying $config"

generation=$(nix build --impure --no-link --print-out-paths "$repo#homeConfigurations.\"$config\".activationPackage")
HOME_MANAGER_BACKUP_EXT=backup "$generation/activate"

# Picked up by the login shell wrapper in Coder workspaces, see its template
ln -sfn "$HOME/.nix-profile/bin/zsh" "$HOME/.login-shell"
