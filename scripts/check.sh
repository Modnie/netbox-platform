#!/usr/bin/env bash

set -euo pipefail

repository_root="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
  pwd
)"

cd "${repository_root}"

printf '\n==> Git whitespace check\n'
git diff --check

printf '\n==> ShellCheck\n'
shellcheck scripts/check.sh

printf '\n==> YAML lint\n'
yamllint \
  .yamllint.yml \
  .ansible-lint \
  ansible \
  .github/workflows

printf '\n==> Ansible lint\n'
ansible-lint \
  ansible/playbooks/bootstrap.yml

printf '\n==> Markdown lint\n'
npm run lint:markdown

printf '\n==> OpenTofu formatting\n'
tofu -chdir=tofu fmt -check

printf '\n==> OpenTofu validation\n'
tofu -chdir=tofu validate

printf '\nAll checks passed.\n'
