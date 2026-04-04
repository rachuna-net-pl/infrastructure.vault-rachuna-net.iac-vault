# Conventions — iac-vault

## 1 MR = 1 Issue
- Never bundle unrelated changes
- Small, frequent MRs
- Label `operate` for operational tasks

## File Naming
- `.tf.json` — active OpenTofu config
- `.tf.json.txt` — **disabled** (intentionally ignored)
- **No dotfiles** — OpenTofu ignores `.*.tf.json`. Use `locals.tf.json`, not `.locals.tf.json`
- User files: `users/<username>.tf.json`

## JSON Style
```json
{
  "resource": {
    "vault_policy": {
      "my_policy": {
        "name": "my-policy",
        "policy": "path \"secret/*\" {\n  capabilities = [\"read\"]\n}"
      }
    }
  }
}
```

## Commit Messages
```
feat: add userpass user mrachuna
fix: correct policy path
docs: update sprint notes
```

## Modules
- **External:** Use tags `?ref=v1.0.0`, not branches
- **Local:** `"./path/"` syntax
- Keep in `main.tf.json` root-level

## Secrets (NEVER EVER)
- ❌ Passwords in repo
- ❌ Root token in repo
- ❌ API tokens in `.tf.json`
- ✅ `random_password` resource
- ✅ KV v2 for password storage (temporary)
- ✅ `.gitignore` for `.terraform.lock.hcl`

## User Account Flow
1. `./tools/create-user-account.sh <username>` → auto branch + commit + push + MR
2. Merge MR
3. `tofu apply`
4. `tofu output -raw <username>_password` → get password
5. User changes password → delete from KV

## Auth Backends Status
| Backend | File | Status |
|---------|------|--------|
| userpass | userpass.tf.json | ✅ ACTIVE |
| approle | approle.tf.json.txt | 🚫 disabled |
| jwt | jwt.tf.json.txt | 🚫 disabled |
| token | token_builtin.tf.json.txt | 🚫 disabled |

## Vault KV v2 Policy Gotcha
- `/data/` — CRUD on secrets
- `/metadata/` — CRUD on metadata + list for sub-folders
- `/list/` — folder visibility in Web UI
- `users/{{user}}/*` does NOT work for KV v2!
