# Architecture — iac-vault

## Overview

OpenTofu IaC repo for HashiCorp Vault at `vault-1022.rachuna-net.pl:8200` (v1.21.4, Consul storage, HA 3-node cluster).

## Repositories

| Repo | Purpose | URL |
|------|---------|-----|
| `iac-vault` | Main IaC repo | `gitlab.com/.../iac-vault` |
| `vault-userpass-account` | Shared module: userpass user creation | `gitlab.com/.../vault-userpass-account` (tag `v1.0.0`) |

## IaC Structure

```
iac-vault/
├── main.tf.json            # Root: module "kv", "users", "auth"
├── providers.tf            # vault ~> 5.0, random ~> 3.7
├── tools/
│   ├── create-user-account.sh  # 1 cmd = 1 user + MR
│   ├── tofu-init.sh            # GitLab HTTP backend init
│   └── tofu-plan.sh            # Local plan
├── users/                  # LOCAL module wrapping vault-userpass-account
│   ├── locals.tf.json      # local.default_password_kv_path = "defaults_passwords"
│   └── <username>.tf.json  # 1 file per user
├── auth/
│   ├── userpass.tf.json    # ✅ ACTIVE — TTL 30d (720h)
│   └── *.tf.json.txt       # 🚫 disabled (appprole, jwt, token_builtin)
├── kv/                     # KV mounts (users/)
├── approles/               # 🚫 Disabled in main.tf.json
├── policies/               # 🚫 Disabled in main.tf.json
└── pki/                    # 🚫 Disabled in main.tf.json
```

## Module Graph

```
main.tf.json
 ├── module "kv"     → ./kv/               (KV mount: users/)
 ├── module "users"  → ./users/             (local → vault-userpass-account)
 └── module "auth"   → ./auth/              (userpass TTL 30d)
```

## Users Flow

```
users/<name>.tf.json  → module vault-userpass-account v1.0.0
   ├─ random_password       (24 chars, special)
   ├─ vault_generic_secret  (userpass user)
   ├─ vault_policy          (KV v2 RW)
   ├─ vault_kv_secret_v2    (password storage, optional)
   └─ vault_kv_secret_v2    (.keep marker)
```

## State & CI

- **Backend:** GitLab HTTP Terraform State (project 78249750, `production`)
- **Pipeline:** validate → plan → publish (apply), + tflint
- **MR convention:** 1 MR = 1 issue, label `operate`

## Auth Convention: `.tf.json.txt`

Files renamed from `.tf.json` → `.tf.json.txt` are **intentionally disabled**.
Terraform/OpenTofu ignores `.tf.json.txt` extension.
Rename back to `.tf.json` when ready to enable.
