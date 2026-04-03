# Skills — iac-vault

## Available Scripts

### `tools/create-user-account.sh`

Create a userpass user account automatically.

```bash
# Simple user
./tools/create-user-account.sh <username>

# User with policies
./tools/create-user-account.sh <username> "admin,default"
```

Requires: `$GITLAB_TOKEN` or `$GL_TOKEN` env var.

What it does:
1. Validates username (a-z, 0-9, -, _)
2. Creates `users/<username>.tf.json`
3. Creates branch `feat/user-<username>`
4. Commits + pushes
5. Opens MR via GitLab API
6. Prints MR link

### `tools/tofu-init.sh`

Initialize OpenTofu with GitLab HTTP backend.

```bash
GITLAB_TOKEN=xxx ./tools/tofu-init.sh
```

### `tools/tofu-plan.sh`

Init + plan for local testing.

```bash
GITLAB_TOKEN=xxx ./tools/tofu-plan.sh
```

## OpenTofu Commands

```bash
# Plan (see what will change)
tofu plan

# Apply (make changes)
tofu apply

# Output sensitive value
tofu output -raw mrachuna_password

# Check state
tofu state list

# Import existing resource
tofu import module.auth.vault_auth_backend.userpass userpass
```

## Vault Commands

```bash
# Check health
vault status -address=https://vault-1022.rachuna-net.pl:8200

# List auth backends
vault auth list

# Get user password from KV
vault kv get users/defaults_passwords/mrachuna

# Delete password after user changes it
vault kv delete users/defaults_passwords/mrachuna

# List users in KV
vault kv list users/

# Check userpass user
vault read auth/userpass/users/mrachuna
```

## Gotchas

### Local vs Remote State
- If you `tofu plan` locally and it shows `0 changes` but CI shows `1 to add` — **state is out of sync**
- State lives in GitLab HTTP backend, not local files
- Import adds resources to state: `tofu import <address> <id>`

### Module Loading
- Only `.tf.json` files are loaded (not `.tf.json.txt`, not `.*.tf.json`)
- Modules must be declared in `main.tf.json`
- Local modules: `./path/` directory with `*.tf.json` files inside

### KV v2 Policy Paths
- Always use `users/data/<user>/*` not `users/<user>/*`
- Need `users/metadata/` and `users/list` for visibility
