#!/usr/bin/env bash
set -euo pipefail

if ! incus image list cluster: --format csv | grep -q "${IMAGE_ALIAS}.*CONTAINER"; then
  RESULT_IMAGE=$(nix build "${FLAKE_PATH}#nixosConfigurations.golden-lxc.config.system.build.squashfs" --no-link --print-out-paths)
  RESULT_METADATA=$(nix build "${FLAKE_PATH}#nixosConfigurations.golden-lxc.config.system.build.metadata" --no-link --print-out-paths)
  incus image import "$RESULT_METADATA"/tarball/*.tar.xz "$RESULT_IMAGE"/*.squashfs cluster: --alias "${IMAGE_ALIAS}" --reuse
fi