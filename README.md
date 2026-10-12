# SDE Forge Sample TRE

A very basic and imcomplete Trusted Research Environment for the SDE Forge Workshop

## Tools

* [terraform](https://developer.hashicorp.com/terraform/install)
* [azcli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Running

### Setup

1. `az login`
1. Using `infra/terraform.tfvars.example` as a template, create an `infra/terraform.tfvars`

1. ```bash
   cd infra
   terraform init
   ```

1. When prompted to the container for state storage, enter something like `blob-sde-forge-user-<n>`, where n is your user number

### Managing the environment

You should probably do `terraform plan -out <filename>` and `terraform apply`.

tl/dr;

```bash
terraform apply
```

## Accessing the VM

The VM is accessed via the Bastion, which is accessed via [the azure portal](https://portal.azure.com)

Two users are created:

* azureadmin (default admin user)
* analyst

The SSH keys for both are stored the created Key Vault.
The password for the analyst users is also storged in the keyvault.
