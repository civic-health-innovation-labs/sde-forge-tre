# SDE Forge Sample TRE

A very basic and imcomplete Trusted Research Environment for the SDE Forge Workshop

## Tools

* [terraform](https://developer.hashicorp.com/terraform/install)
* [azcli](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

## Running

### Setup

Using `infra/terraform.tfvars.example` as a template, create an `infra/terraform.tfvars`

```bash
cd infra
terraform init
```

This will ask for the container for state storage, which will look like `blob-sde-forge-user-<n>`, where n is your user number

### Managing the environment

You should probably do `terraform plan -out <filename>` and `terraform apply`.

tl/dr;

```bash
terraform apply
```
