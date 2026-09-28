# SDE Forge Sample TRE

A very basic and imcomplete Trusted Research Environment for the SDE Forge Workshop

## Tools

* [terraform](https://developer.hashicorp.com/terraform/install)
* [azcli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Running

### Setup

1. `az login`
1. Using `infra/terraform.tfvars.example` as a template, create an `infra/terraform.tfvars`
2. ```bash
   cd infra
   terraform init
   ```
3. When prompted to the container for state storage, enter something like `blob-sde-forge-user-<n>`, where n is your user number

### Managing the environment

You should probably do `terraform plan -out <filename>` and `terraform apply`.

tl/dr;

```bash
terraform apply
```
