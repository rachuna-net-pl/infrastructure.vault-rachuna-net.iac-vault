# Audit Device — Vault

## Opis

Moduł włącza audit logging w HashiCorp Vault. Wszystkie request/response zapisywane są w pliku JSON — każdy wpis zawiera kto, co, kiedy, z jakim wynikiem.

## ⚠️ Przed `tofu apply`

Vault potrzebuje pliku z poprawnymi uprawnieniami. Wykonaj na KAŻDYM węźle Vault:

```bash
# Utwórz plik (jako root)
sudo touch /var/log/vault-audit.log

# Ustaw właściciela (user pod którym działa proces Vault)
sudo chown vault:vault /var/log/vault-audit.log

# Uprawnienia — tylko vault ma R/W
sudo chmod 0640 /var/log/vault-audit.log
```

Bez tego `tofu apply` zwróci `permission denied`.

## Co się loguje

| Typ zapytania | Przykład |
|--------------|----------|
| Auth | `POST /auth/userpass/login/mrachuna` |
| Read sekretu | `GET /users/data/mrachuna/db-password` |
| Zapis sekretu | `POST /users/data/mrachuna/api-key` |
| Zmiana polityki | `PUT /sys/policies/acl/admin` |
| Zmiana hasła | `PUT /auth/userpass/users/mrachuna/password` |

## Format logów

Każda linia = JSON z pełnym request + response:

```json
{
  "time": "2026-04-04T06:00:30Z",
  "type": "request",
  "auth": { "display_name": "userpass/mrachuna" },
  "request": {
    "path": "users/data/mrachuna/db-password",
    "operation": "read"
  },
  "response": { "status": 200 }
}
```

Wrażliwe dane (sekrety, hasła) są **hashowane** — audytor widzi że się zmieniły, ale nie widzi wartości.

## Rotacja logów

Paudit rośnie szybko. Skonfiguruj `logrotate`:

```bash
# /etc/logrotate.d/vault-audit
/var/log/vault-audit.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 vault vault
}
```

## Wyłączenie audit (nie zalecane)

```bash
# Usuń moduł z main.tf.json i run tofu apply
# LUB ręcznie:
vault audit disable file
```
