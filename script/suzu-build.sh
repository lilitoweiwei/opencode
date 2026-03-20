#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
image=${OPENCODE_BUILD_IMAGE:-suzu-opencode-builder:1.3.10}
channel=${OPENCODE_CHANNEL:-$(git -C "$root" branch --show-current 2>/dev/null || printf 'dev')}
out="$root/packages/opencode/dist"

args=("$@")
if [ ${#args[@]} -eq 0 ]; then
  args=(--single --skip-install)
fi

cmd="set -euo pipefail; rm -rf /tmp/work; mkdir -p /tmp/work; cp -a /src/. /tmp/work; chmod -R u+w /tmp/work; cd /tmp/work; bun install --ignore-scripts; bun run --cwd packages/opencode build --"
for arg in "${args[@]}"; do
  cmd+=" $(printf '%q' "$arg")"
done
cmd+="; rm -rf /out/*; cp -a packages/opencode/dist/. /out/"

if ! docker image inspect "$image" >/dev/null 2>&1; then
  docker build -t "$image" - <<'EOF'
FROM oven/bun:1.3.10
RUN apt-get update >/dev/null && apt-get install -y git >/dev/null && rm -rf /var/lib/apt/lists/*
EOF
fi

mkdir -p "$out"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp/opencode-builder \
  -e GIT_DISCOVERY_ACROSS_FILESYSTEM=1 \
  -e OPENCODE_CHANNEL="$channel" \
  -v "$root:/src:ro" \
  -v "$out:/out" \
  -w /tmp \
  "$image" \
  sh -lc "$cmd"

printf 'Built %s\n' "$out"
