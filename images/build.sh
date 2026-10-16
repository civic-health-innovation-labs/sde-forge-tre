#!/bin/bash

SUFFIX=$(date +%Y.%m%d.%H%M)

PKR_VAR_version=${SUFFIX} packer init basic.pkr.hcl
PKR_VAR_version=${SUFFIX} packer build basic.pkr.hcl

PKR_VAR_base_version="${SUFFIX}" PKR_VAR_subscription_id=`az account list --query "[?isDefault].id" --output tsv` packer build analysis.pkr.hcl