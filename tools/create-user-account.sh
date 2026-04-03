#!/usr/bin/env bash
# create-user-account.sh — Create a userpass user account in Vault via IaC
# Usage: ./tools/create-user-account.sh <username> [policies]
# Example: ./tools/create-user-account.sh maciej "admin,default"
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

USERNAME="${1:?Usage: $0 <username> [policies]}"
POLICIES="${2:-}"

[[ ! "$USERNAME" =~ ^[a-z0-9_-]+$ ]] && { echo "✗ Username: a-z 0-9 - _ only"; exit 1; }

USER_FILE="${REPO_DIR}/users/${USERNAME}.tf.json"
[ -f "$USER_FILE" ] && { echo "✗ users/${USERNAME}.tf.json already exists"; exit 1; }

GITLAB_TOKEN="${GITLAB_TOKEN:-${GL_TOKEN:-}}"
[[ -z "$GITLAB_TOKEN" ]] && { echo "✗ Set GITLAB_TOKEN or GL_TOKEN"; exit 1; }

PROJECT_ID="78249750"
MODULE_SOURCE="git::https://gitlab.com/pl.rachuna-net/artifacts/opentofu/vault-userpass-account.git?ref=v1.0.0"

# --- Build .tf.json ---
python3 -c "
import json, sys
username = sys.argv[1]
policies = [p.strip() for p in sys.argv[2].split(',') if p.strip()] if len(sys.argv) > 2 and sys.argv[2] else []

data = {
    'module': {
        username: {
            'source': '$MODULE_SOURCE',
            'username': username,
            'default_password_kv_path': '\${local.default_password_kv_path}/' + username,
            'policies': policies
        }
    }
}

with open('$USER_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
print(f'✓ Created users/{username}.tf.json')
" "$USERNAME" "$POLICIES"

# --- Branch ---
BRANCH="feat/user-${USERNAME}"
cd "$REPO_DIR"
git checkout main >/dev/null 2>&1
git pull origin main --rebase >/dev/null 2>&1 || true
git checkout -B "$BRANCH" >/dev/null 2>&1
git add "$USER_FILE"
git commit -m "feat: add userpass user ${USERNAME}" >/dev/null
git push -u origin "$BRANCH" --force --quiet 2>/dev/null
echo "✓ Pushed branch ${BRANCH}"

# --- MR ---
python3 << 'PYEOF'
import json, os, subprocess

username = os.environ["USERNAME"]
token = os.environ["GITLAB_TOKEN"]
project_id = os.environ["PROJECT_ID"]
branch = os.environ["BRANCH"]

title = f"feat: add userpass user {username}"
desc = f"""## Co robi ten MR
Utworzenie użytkownika `{username}` w Vault przez userpass.

## Szczegóły
- Moduł: `vault-userpass-account` v1.0.0
- Hasło: generowane (24 znaki)
- Polityka: `users-{username}` (RW na KV namespace)

## Flow po mergu
1. `tofu apply` → user created
2. `tofu output -raw {username}_password` → get password
3. User changes password
4. Delete from KV: `vault kv delete users/...`
"""

data = json.dumps({
    "title": title,
    "source_branch": branch,
    "target_branch": "main",
    "description": desc,
    "labels": "operate"
})

result = subprocess.run([
    "curl", "-s", "--request", "POST",
    f"https://gitlab.com/api/v4/projects/{project_id}/merge_requests",
    "--header", f"PRIVATE-TOKEN: {token}",
    "--header", "Content-Type: application/json",
    "--data", data
], capture_output=True, text=True)

resp = json.loads(result.stdout)
iid = resp.get("iid", "?")
url = resp.get("web_url", "?")

print(f"\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"✓ MR !{iid} utworzony")
print(f"→ {url}")
print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
PYEOF

