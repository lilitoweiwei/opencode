# Suzu OpenCode Workflow

This file is the canonical note for how Suzu carries local OpenCode changes, builds local binaries, and records Suzu-specific patches.

## Repository Layout

- `origin` points at the Suzu fork: `git@github.com:lilitoweiwei/opencode.git`
- `upstream` points at the official repo: `git@github.com:anomalyco/opencode.git`
- `upstream/dev` is the upstream integration base.
- `suzu-dev` is the long-lived Suzu branch. It is the branch that should contain all Suzu patches.
- `work/<slug>` branches are short-lived topic branches created from `suzu-dev` when a change needs isolated review.

Do not use `origin/dev` for Suzu patches. Keep it as a disposable mirror of the fork's `dev` line so that `suzu-dev` stays easy to reason about.

## Daily Workflow

Create a topic branch:

```bash
git checkout suzu-dev
git pull --ff-only upstream dev
git checkout -b work/<slug>
```

Land a change onto `suzu-dev`:

```bash
git checkout suzu-dev
git rebase work/<slug>
git push --force-with-lease origin suzu-dev
```

Refresh Suzu after upstream moves:

```bash
git fetch upstream
git checkout suzu-dev
git rebase upstream/dev
git push --force-with-lease origin suzu-dev
```

If the Suzu workspace manifest should follow the patched OpenCode branch, set that project revision to `suzu-dev`.

## Build Method

Suzu builds OpenCode inside Docker instead of relying on a host Bun install. This keeps the build environment stable across machines and avoids mutating the host runtime.

Use:

```bash
./script/suzu-build.sh
```

Default behavior:

- builds with `oven/bun:1.3.10`
- installs `git` into a small helper image
- copies the repo into a temporary container workdir so the host checkout stays untouched
- runs `bun install --ignore-scripts`
- runs `bun run --cwd packages/opencode build -- --single --skip-install`
- copies `packages/opencode/dist` back to the host

The default output for this host is:

```text
packages/opencode/dist/opencode-linux-x64/bin/opencode
```

Pass extra OpenCode build flags straight through:

```bash
./script/suzu-build.sh --single --baseline
./script/suzu-build.sh --single
```

Useful environment overrides:

```bash
OPENCODE_CHANNEL=suzu-dev ./script/suzu-build.sh
OPENCODE_BUILD_IMAGE=suzu-opencode-builder:1.3.10 ./script/suzu-build.sh
```

## Host And Deploy Compatibility

The current `linux-x64` build is reusable on both the host and the Incus deploy container.

Verified environment:

- host: Ubuntu 24.04, `x86_64`, glibc 2.39
- `suzu-deploy`: Ubuntu 24.04, `x86_64`, glibc 2.39
- built binary: `ELF 64-bit`, `x86-64`, dynamically linked against glibc

Verification result:

- host runs `packages/opencode/dist/opencode-linux-x64/bin/opencode --version`
- `suzu-deploy` runs the same binary after `incus file push` and reports the same version

This reuse assumption should be rechecked if either side moves to Alpine, musl, ARM, or an older glibc baseline.

## Local Patch Log

Keep all Suzu-specific OpenCode changes listed here so the branch purpose stays obvious.

- 2026-03-20: added `SUZU.md` and `script/suzu-build.sh`; no runtime behavior changes yet
