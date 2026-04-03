terraform {
  required_version = ">= 1.10.5"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
  backend "http" {}
}

provider "vault" {
  address         = var.vault_address
  skip_tls_verify = true
}

variable "vault_address" {
  description = "Vault server URL"
  type        = string
  default     = "https://vault-1022.rachuna-net.pl:8200"
}
