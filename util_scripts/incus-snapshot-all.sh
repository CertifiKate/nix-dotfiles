#!/usr/bin/env bash
#
# Snapshots every Incus instance, so there's something to roll back to before risky changes
#
#   util_scripts/incus-snapshot-all.sh [name]   name defaults to manual-<date>-<time>
#
set -u

remote=cluster
name=${1:-manual-$(date +%Y%m%d-%H%M)}

instances=$(incus list "$remote:" -f csv -c n) || exit 1
if [ -z "$instances" ]; then
  echo "No instances found on $remote"
  exit 1
fi

failed=()
for instance in $instances; do
  if incus snapshot create "$remote:$instance" "$name" --no-expiry; then
    echo "ok    $instance"
  else
    echo "FAIL  $instance"
    failed+=("$instance")
  fi
done

echo
if [ "${#failed[@]}" -ne 0 ]; then
  echo "Failed: ${failed[*]}"
  exit 1
fi
echo "Snapshotted everything as $name"
