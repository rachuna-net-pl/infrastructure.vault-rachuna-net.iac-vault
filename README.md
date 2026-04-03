# <img src="docs/tavatar.png" alt="avatar" height="20"/> Vault Infrastructure as Code

---

## Infrastructure as Code dla HashiCorp Vault — zarządzane przez OpenTofu.

---

## 📋 Description

Repozytorium zawiera pełną konfigurację HashiCorp Vault zapisaną w formacie `.tf.json` (OpenTofu/Terraform).

**Cel:** cała konfiguracja Vault (polityki, auth methods, secrets engines, AppRoles, PKI) zarządzana przez kod — zero ręcznych zmian.

---

## 🔗 Milestone

- **Vault in IaC:** https://gitlab.com/groups/pl.rachuna-net/-/milestones/13

---

## 🎯 Inwentaryzacja

| Obszar | Issue | Output | Status |
|--------|-------|--------|--------|
| Polityki ACL | #4 | `policies/*.tf.json` | ✅ |
| Secrets Engines — KV | #5 → #2 | `kv/*.tf.json` | ✅ MR !4 |
| Auth Methods | #6 | `auth/*.tf.json` | ⏳ |
| AppRoles | #7 | `approles/*.tf.json` | ⏳ |
| Users (userpass) | #8 | `users/*.tf.json` | ⏳ |
| PKI | #9 | `pki/*.tf.json` | ⏳ |
| JWT/OIDC | #10 | `auth/jwt.tf.json` | ⏳ |

---

## 🏗️ Struktura repozytorium

```
iac-vault/
├── policies/       # Polityki ACL (26 plików .tf.json)
├── kv/             # Secrets Engines — KV v2
├── auth/           # Auth methods (approle, userpass, jwt)
├── approles/       # AppRole definitions
├── users/          # Users (userpass)
├── pki/            # PKI mounts
├── main.tf         # Provider vault
├── variables.tf    # Zmienne
└── state/          # Terraform state
```

---

## 🚀 Quick Start

```bash
# 1. Ustaw token
export VAULT_TOKEN="hvs.xxx"

# 2. Inicjalizacja
tofu init

# 3. Plan (musi wyjść "No changes")
tofu plan

# 4. Apply (po review i akceptacji)
tofu apply
```

---

## ⚠️ Security

- **NIGDY** nie commituj sekretów/tokenów do repo (gitlab.com jest publiczne)
- Tokeny Vault tylko przez zmienne środowiskowe
- State zawiera sekrety — traktuj `.tfstate` jako poufny

---

## Contributions
Jeśli masz pomysły na ulepszenia, zgłoś problemy, rozwidl repozytorium lub utwórz Merge Request. Wszystkie wkłady są mile widziane!
[Contributions](CONTRIBUTING.md)

---

## License
[Licencja](LICENCE) oparta na zasadach Creative Commons BY-NC-SA 4.0, dostosowana do potrzeb projektu.

---

# Author Information
### &emsp; Maciej Rachuna
# <img src="docs/logo.png" alt="rachuna-net.pl" height="100"/>
