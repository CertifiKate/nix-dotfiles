#!/usr/bin/env bash
set -euo pipefail

if ! incus image list cluster: --format csv | grep -q "${IMAGE_ALIAS}.*VIRTUAL-MACHINE"; then
  RESULT_IMAGE=$(nix build "${FLAKE_PATH}#nixosConfigurations.golden-incus-vm.config.system.build.qemuImage" --no-link --print-out-paths)
  RESULT_METADATA=$(nix build "${FLAKE_PATH}#nixosConfigurations.golden-incus-vm.config.system.build.metadata" --no-link --print-out-paths)
  incus image import "$RESULT_METADATA"/tarball/*.tar.xz "$RESULT_IMAGE"/*.qcow2 cluster: --alias "${IMAGE_ALIAS}"
fi