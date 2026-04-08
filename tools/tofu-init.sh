#!/usr/bin/env bash
# tofu-init.sh — Inicjalizacja OpenTofu z backendem GitLab Terraform State
set -euo pipefail

# Credentials should be set via environment variables, not hardcoded
# CI_JOB_TOKEN - GitLab token (set via GITLAB_TOKEN)
# VAULT_ADDR - Vault server address (set via environment)
# VAULT_TOKEN - Vault authentication token (set via environment)

CI_SERVER_URL="${CI_SERVER_URL:-https://gitlab.com}"
CI_PROJECT_ID="${CI_PROJECT_ID:-78249750}"
CI_JOB_TOKEN="${CI_JOB_TOKEN:-${GITLAB_TOKEN:-}}"
TF_STATE_NAME="${TF_STATE_NAME:-production}"

if [ -z "$CI_JOB_TOKEN" ]; then
  echo "❌ Brak tokena: ustaw GITLAB_TOKEN lub CI_JOB_TOKEN"
  exit 1
fi

echo "🔧 Initializing OpenTofu with GitLab backend..."
echo "   Project: ${CI_SERVER_URL}/-/projects/${CI_PROJECT_ID}"
echo "   State:   ${TF_STATE_NAME}"
echo "   Token:   ${CI_JOB_TOKEN}"

rm -fr .terraform*

tofu init \
  -backend-config="address=${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}" \
  -backend-config="lock_address=${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}/lock" \
  -backend-config="unlock_address=${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}/lock" \
  -backend-config="username=mrachuna" \
  -backend-config="password=${CI_JOB_TOKEN}" \
  -backend-config="lock_method=POST" \
  -backend-config="unlock_method=DELETE" \
  -backend-config="retry_wait_min=5"

echo "✅ OpenTofu initialized."
