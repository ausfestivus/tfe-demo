
# tfe-demo

A basic demo of the [TFE module](https://registry.terraform.io/modules/hashicorp/terraform-enterprise/azurerm/0.1.0/examples/basic). The complete Terraform Enterprise documentation is available from [https://www.terraform.io/docs/enterprise/index.html](https://www.terraform.io/docs/enterprise/index.html).

## Introduction

This repo will build you a demo environment for Terraform Enterprise in Azure. It uses two modules:

1. The Terraform Enterprise Bootstrap repo for Azure available [here](https://github.com/hashicorp/private-terraform-enterprise)
  CAVEATS: Due to some issues in the above repo with Azure Keyvault, the code in here currently pulls from [my fork](https://github.com/Diaxion/private-terraform-enterprise) of the above.
2. The Terraform Enterprise Module repo is available [here](https://github.com/hashicorp/terraform-azurerm-terraform-enterprise)

## Preparation

### Certificate creation

The `tfe_cluster` module expects a cert with KeySize of 4096.

The following commands will create the necessary self-signed certs for use.

```shell
mkdir tls && cd tls
openssl req -x509 -days 365 -newkey rsa:4096 -keyout key.pem -out cert.pem
openssl pkcs12 -export -in cert.pem -inkey key.pem -out cert.pfx
```

Dont lose the passwords you select!

You can inspect the Key Size on a private key with this: `openssl rsa -in key.pem -text -noout | grep "Private-Key"`

### Sign in to the SP you use with terraform for building

To build this, you must login to your terminal using your Service Principle credentials. You *MUST* achieve this using TF Environment vars. Using `az login --service-principle` will not work. See [the doco](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html#configuring-the-service-principal-in-terraform)

What I do to make this useful is create a bash script for myself that allows me to quickly set the necessary environment vars we need. Replace the XX values with your own values.

```bash
Terraform environment variables can be found at:
# https://www.terraform.io/docs/configuration/environment-variables.html

echo "Setting environment variables for Terraform"
export ARM_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export ARM_CLIENT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export ARM_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export ARM_CLIENT_SECRET=SECRET_HERE
echo "Setting environment variables for TF var file"
export TF_VAR_subscription_id=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export TF_VAR_client_id=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export TF_VAR_tenant_id=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
export TF_VAR_secret_access_key=SECRET_HERE
```

Save the bash script, make it executable and run `source PATH/SCRIPTNAME`.

### AAD

* Create a new `App Registration`. This will give you the information you need for the SP to access the KV. Record the following details about the `App Registration` you create.
  * Name: `tfedemo-keyvault-sp` (eg)
  * key_vault_object_id: `XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
  * key_vault_tenant_id: `XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
  * application_id:      `XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

* Enterprise App details for the SP
  * Name: `tfedemo-keyvault-sp`
  * Application ID: `aXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
  * Object ID: `XXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`

## Running TF locally for the build

As at 20191108 the module used only supports installation with terraform 0.11.

```shell
cd /Users/abest/github/tfe-demo
/usr/local/opt/terraform\@0.11/bin/terraform init
/usr/local/opt/terraform\@0.11/bin/terraform plan -out outfile -var-file ./customerDemo.tfvars
/usr/local/opt/terraform\@0.11/bin/terraform apply outfile
```

When the build completes you will be give some output that looks like this:

```shell
Apply complete! Resources: 49 added, 0 changed, 0 destroyed.

Outputs:

tfe_cluster = {
  application_endpoint = <URL>
  application_health_check = <URL>
  install_id = <RANDOM>
  installer_dashboard_endpoint = <URL>
  installer_dashboard_password = <WORDS>
  primary_public_ip = <IPADDRESS
  ssh_config_file = <PATH TO SSH CONFIG FILE>
  ssh_private_key = <PATH TO PRIVATE KEY>
}
```

Ensure you take a copy of these details. You will need them later.

You may need to wait 10-15 minutes for the `installer_dashboard_endpoint` to become available.

## Completing the app install

Once you are able to access the `installer_dashboard_endpoint` you can use the instructions at [https://www.terraform.io/docs/enterprise/install/config.html](https://www.terraform.io/docs/enterprise/install/config.html) to complete the installation.
