# CLAUDE.md — iac-vault

This file documents critical information for working with this Infrastructure as Code project for HashiCorp Vault. Refer here before starting work.

---

## 📌 Project Overview

**iac-vault** is an OpenTofu/Terraform Infrastructure as Code repository that manages the complete configuration of HashiCorp Vault as code. The goal is **zero manual changes** — all Vault configuration (policies, auth methods, secrets engines, AppRoles, PKI) is defined in version-controlled `.tf.json` files.

### Quick Facts

| Property | Value |
|----------|-------|
| **Tool** | OpenTofu v1.11.5+ |
| **Format** | `.tf.json` (JSON, not HCL) |
| **Vault** | v1.21.4, https://vault-1023.rachuna-net.pl:8200 |
| **Storage** | Consul (HA 3-node cluster) |
| **State Backend** | GitLab HTTP (project 78249750, `production`) |
| **CI** | GitLab CI — validate, plan, apply, tflint |
| **Module Dependencies** | `vault ~> 5.0`, `random ~> 3.7` |

---

## 🏗️ Repository Structure

```
iac-vault/
├── main.tf.json                    # Root: modules (kv, users, auth)
├── providers.tf                    # vault, random providers
├── tools/
│   ├── create-user-account.sh      # Automated user + MR creation
│   ├── tofu-init.sh                # Initialize with GitLab backend
│   └── tofu-plan.sh                # Local plan (init + plan)
├── users/                          # Userpass user definitions
│   ├── locals.tf.json              # default KV path
│   └── <username>.tf.json          # Per-user config (1 file per user)
├── auth/                           # Auth methods
│   ├── userpass.tf.json            # ✅ ACTIVE — TTL 30 days
│   ├── approle.tf.json.txt         # 🚫 disabled
│   ├── jwt.tf.json.txt             # 🚫 disabled
│   └── token_builtin.tf.json.txt   # 🚫 disabled
├── kv/                             # KV mounts
├── pki/                            # PKI CA & certificates
├── policies/                       # ACL policies (26 files)
├── approles/                       # AppRole definitions
├── audit/                          # Audit device configuration
├── .gitlab/                        # GitLab CI pipelines
├── docs/                           # Documentation
├── README.md                       # Project overview
├── CONTRIBUTING.md                 # Contribution guidelines
└── LICENCE                         # CC BY-NC-SA 4.0

```

### Disabled Modules

Files with `.tf.json.txt` extension are **intentionally disabled** — OpenTofu ignores them. Rename back to `.tf.json` when ready to enable. Active modules as of last commit:

- ✅ `auth/userpass.tf.json` — Active
- ✅ `kv/` — Active
- ✅ `users/` — Active
- 🚫 `auth/approle.tf.json.txt` — Disabled
- 🚫 `auth/jwt.tf.json.txt` — Disabled
- 🚫 Other auth backends — Disabled

---

## 🔐 Security & Secrets

**CRITICAL: Never commit secrets to this repository. GitLab (gitlab.com) is public.**

### Rules

- ❌ **Never** store passwords, tokens, or API keys in `.tf.json` files
- ❌ **Never** commit the root token
- ✅ Use `random_password` resources for auto-generation
- ✅ Store generated passwords temporarily in KV v2 (`vault_kv_secret_v2`)
- ✅ Vault tokens: Only via environment variables (`$VAULT_TOKEN`, `$VAULT_ADDR`)
- ✅ `.terraform.lock.hcl` is in `.gitignore`

### State File Warning

Terraform state (`.tfstate`) **contains plaintext secrets**. The state is stored in the GitLab HTTP backend and is encrypted at rest — treat it as confidential.

---

## 📋 Working with OpenTofu

### Initialize & Plan

```bash
# Initialize with GitLab HTTP backend (requires $GITLAB_TOKEN)
export GITLAB_TOKEN="glpat-..."
./tools/tofu-init.sh

# Or manually:
tofu init -backend-config="address=https://gitlab.com/api/v4/projects/78249750/terraform/state/production"

# Plan (see what will change)
export VAULT_TOKEN="hvs...."
export VAULT_ADDR="https://vault-1023.rachuna-net.pl:8200"
tofu plan
```

### Apply Changes

```bash
# After review of tofu plan output:
tofu apply

# Check outputs (passwords for new users)
tofu output -raw <username>_password
```

### Useful Commands

```bash
# List state resources
tofu state list

# Show specific resource details
tofu state show module.users.<resource_name>

# Import existing Vault resource into state
tofu import module.auth.vault_auth_backend.userpass userpass

# Format JSON files (JSON only, no HCL)
tofu fmt -json

# Validate syntax
tofu validate
```

---

## 📝 File Naming & Conventions

### File Extensions

- `.tf.json` — **Active** OpenTofu configuration (will be loaded)
- `.tf.json.txt` — **Disabled** intentionally (OpenTofu ignores)
- **Never** use dotfiles like `.locals.tf.json` — OpenTofu ignores them! Use `locals.tf.json`

### Naming Conventions

| Category | Pattern | Example |
|----------|---------|---------|
| User files | `users/<username>.tf.json` | `users/jsmith.tf.json` |
| Modules | Declared in `main.tf.json` | `module "users" { ... }` |
| Disabled auth | `auth/*.tf.json.txt` | `auth/approle.tf.json.txt` |

### Commit Messages

Follow Conventional Commits:

```
feat: add <description>      # New feature
fix: <description>           # Bug fix
docs: <description>          # Documentation
chore: <description>         # Maintenance
```

Examples:
- `feat: add userpass user jsmith`
- `fix: correct KV policy path for users`
- `docs: update README with PKI setup`

---

## 🔀 Branch & MR Workflow

### Branch Naming

- `feat/<feature-name>` — New feature (e.g., `feat/pki-root`)
- `feat/user-<username>` — New user account (e.g., `feat/user-jsmith`)
- `fix/<bug-name>` — Bug fix (e.g., `fix/userpass-ttl`)
- `docs/<topic>` — Documentation (e.g., `docs/pki-setup`)

### MR Convention: 1 MR = 1 Issue

- **Never bundle unrelated changes** — one MR per issue
- Small, frequent MRs are preferred
- Label all MRs with `operate` for operational tasks
- Merge only after CI passes (`validate`, `plan`, `tflint`)
- Reviewer: @mrachuna

### Pre-Commit Checks

Before pushing:

```bash
# Validate syntax
tofu validate

# Format JSON
tofu fmt -json

# Lint (if tflint is available)
tflint
```

---

## 👥 Managing Users (userpass)

### Create a New User

```bash
# 1. Use the automated tool (creates branch + commit + MR)
export GITLAB_TOKEN="glpat-..."
./tools/create-user-account.sh jsmith

# 2. Review and merge the MR
# 3. Apply changes
tofu apply

# 4. Get the password
tofu output -raw jsmith_password

# 5. Give password to user (and ask them to change it)
# 6. User changes password in Vault
# 7. Delete the temporary password from KV
vault kv delete users/defaults_passwords/jsmith
```

### User Account Resource Details

Each user file uses the `vault-userpass-account` module (v1.1.0):

```json
{
  "module": {
    "users": {
      "source": "git::https://gitlab.com/pl.rachuna-net/vault-userpass-account?ref=v1.1.0",
      "default_password_kv_path": "users/defaults_passwords",
      "users": {
        "jsmith": {
          "policies": ["default", "admin"],
          "ttl": "720h"  // 30 days
        }
      }
    }
  }
}
```

Resources created per user:
- `random_password` — 24-char password with special chars
- `vault_generic_secret` — userpass user in auth backend
- `vault_policy` — KV v2 read/write policy
- `vault_kv_secret_v2` — temporary password storage
- `.keep` marker — prevents accidental deletion

---

## 🔑 KV v2 Policy Gotchas

KV v2 uses special paths. When writing policies, always include:

```hcl
path "users/data/<user>/*" {
  capabilities = ["create", "read", "update", "delete"]
}

path "users/metadata/<user>/*" {
  capabilities = ["list", "read", "delete"]
}

path "users/list" {
  capabilities = ["list"]
}
```

**Common mistakes:**
- ❌ `path "users/<user>/*"` — won't work for KV v2
- ✅ `path "users/data/<user>/*"` — correct
- ❌ Missing `/metadata/` — users can't see folder structure in Web UI
- ✅ Include `/list/` — enables folder listing

---

## 🚨 Troubleshooting

### State Out of Sync

**Symptom:** `tofu plan` shows `0 changes` locally, but CI shows `1 to add`.

**Cause:** State lives in the GitLab HTTP backend, not local files.

**Solution:**
```bash
# Refresh state from backend
tofu refresh

# Or import missing resource
tofu import <address> <id>

# Example:
tofu import module.auth.vault_auth_backend.userpass userpass
```

### Module Not Loaded

**Symptom:** `Error: resource not found`.

**Causes:**
- File extension is `.tf.json.txt` instead of `.tf.json`
- File is a dotfile like `.locals.tf.json` (OpenTofu ignores these)
- Module not declared in `main.tf.json`

**Solution:**
- Rename `.tf.json.txt` → `.tf.json` to enable
- Remove leading dot from filename
- Add module declaration to `main.tf.json`

### Permission Denied on Vault

**Symptom:** `Error: error requesting data from https://vault-1023.rachuna-net.pl:8200: *.`

**Causes:**
- `$VAULT_TOKEN` missing or expired
- `$VAULT_ADDR` not set
- Token lacks required policy

**Solution:**
```bash
# Check token
vault token lookup

# Validate address
echo $VAULT_ADDR

# List available auth methods
vault auth list
```

---

## 📚 Related Documentation

| Location | Purpose |
|----------|---------|
| [README.md](README.md) | Project overview & quick start |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| `.llm/architecture.md` | Detailed module structure |
| `.llm/context.md` | Project state & key files |
| `.llm/conventions.md` | Naming & style conventions |
| `.llm/skills.md` | Scripts & commands |

---

## 🎯 Key Contacts & Resources

| Item | Reference |
|------|-----------|
| **Author** | Maciej Rachuna (@mrachuna) |
| **GitLab Group** | https://gitlab.com/groups/pl.rachuna-net |
| **Milestone** | Vault in IaC #13 |
| **Module** | `vault-userpass-account` v1.1.0 |
| **Shared Module Repo** | gitlab.com/pl.rachuna-net/vault-userpass-account |

---

## ✅ Project Status

| Area | Status | Notes |
|------|--------|-------|
| **Policies (ACL)** | ✅ Complete | 26 policy files |
| **KV Secrets Engine** | ✅ Complete | Mount: `users/` |
| **Auth Methods (userpass)** | ✅ Complete | TTL: 30 days |
| **Users (userpass)** | ✅ Complete | Via vault-userpass-account module |
| **AppRoles** | ⏳ In Progress | Files ready, not enabled |
| **PKI (Root & Intermediates)** | ⏳ In Progress | `pki_root`, `pki_int_test`, `pki_int_prod` |
| **JWT/OIDC** | ⏳ Not Started | `auth/jwt.tf.json.txt` |
| **KV Cleanup** | ✅ Complete | 12 old mounts removed |

---

## 📖 Last Updated

- **Last Commit:** `9668961` — fix: Dodanie prod intermediate i SANs do certyfikatu vault
- **Current Branch:** `fix/state`
- **Status:** Clean working tree

---

## 🚀 Getting Started (First Time)

1. **Clone & setup:**
   ```bash
   cd /home/maciej-rachuna/repo/pl.rachuna-net/infrastructure/vault-rachuna-net/iac-vault
   export GITLAB_TOKEN="glpat-..."
   ./tools/tofu-init.sh
   ```

2. **Verify connection:**
   ```bash
   export VAULT_TOKEN="hvs...."
   tofu plan
   ```

3. **Make a change:**
   ```bash
   git checkout -b feat/my-feature
   # ... edit files ...
   tofu plan
   git add -A && git commit -m "feat: description"
   git push origin feat/my-feature
   ```

4. **Create MR & merge after review**

5. **Apply in CI or locally:**
   ```bash
   tofu apply
   ```

---

*This file is a reference guide for all interactions with iac-vault via Claude Code. Keep it up-to-date as the project evolves.*
