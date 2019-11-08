# Azure Keyvault Troubleshooting

## Problem Statement Thursday

When this Terraform code is run it eventually spits out this error:

```shell
Error: Error applying plan:

1 error occurred:
	* module.tfe_cluster.module.common.azurerm_key_vault_certificate.ptfe: 1 error occurred:
	* azurerm_key_vault_certificate.ptfe: keyvault.BaseClient#ImportCertificate: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="Forbidden" Message="Access denied. Caller was not found on any access policy.\r\nCaller: appid=04b07795-8ddb-461a-bbee-02f9e1bf7b46;oid=731b021b-d6c0-41f7-b417-9874875730dc;numgroups=2;iss=https://sts.windows.net/a5aa424e-5d6f-47c9-bf70-a1310f4be302/\r\nVault: demoTFE;location=australiaeast" InnerError={"code":"AccessDenied"}
```

## Work Journal

After a whole lot of google phoo turned up almost nothing and hitting this error a few times over the past few weeks I posted a an issue.
[https://github.com/hashicorp/terraform-azurerm-terraform-enterprise/issues/47](https://github.com/hashicorp/terraform-azurerm-terraform-enterprise/issues/47)

I also had a search through the Terraform AzureRM Provider repo issues for [stuff related to Keyvault](https://github.com/terraform-providers/terraform-provider-azurerm/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+keyvault). I found a few items of interest:

* [https://github.com/terraform-providers/terraform-provider-azurerm/issues/1569](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1569) which has a link to
  * [https://github.com/terraform-providers/terraform-provider-azurerm/issues/1034](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1034)

  In that article above, [Tom Harvey](https://github.com/tombuildsstuff) [states](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1034#issuecomment-376865458) that your TF code must also give the SP you're running TF with access to the Keyvault. He provides a sample of code that can help do that.

The question now is, does this TFE module use the same pattern for handling an Azure Keyvault secret insertion? Short answer *NO* because the Azure Keyvault creation is done in the `bootstrap` module, a fork of which I have [here](https://github.com/Diaxion/private-terraform-enterprise/blob/master/examples/bootstrap-azure/key_vault.tf)

First, the bootstrap `key_vault.tf` is using the correct approach to creating a Keyvault and setting policies, per the warning at the top of the page for using this part of the provider (TL;DR - dont mix policy definitions with `azurerm_key_vault` and `azurerm_key_vault_access_policy` resource blocks.)

So, at this point I need to update the bootstrap code. Done in this my branch [here](https://github.com/Diaxion/private-terraform-enterprise/tree/develop-ausfestivus) 

* [commit 1](https://github.com/Diaxion/private-terraform-enterprise/commit/e17be74fda2c3ceba714323201e665ce2c91705a)
* [commit 2](https://github.com/Diaxion/private-terraform-enterprise/commit/b46f3c834f7b38c95d5e577b3f9e9cc30a7899d2)

-----

New Day, new problem.

## Problem Statement Friday

I got a successful build this morning.
I destroyed everything.
I fixed the ref in the bootstrap module to use my branch.
I reran the build.
We got this problem again.

```shell
Error: Error applying plan:

1 error occurred:
	* module.tfe_cluster.module.common.azurerm_key_vault_certificate.ptfe: 1 error occurred:
	* azurerm_key_vault_certificate.ptfe: keyvault.BaseClient#ImportCertificate: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="Forbidden" Message="Access denied. Caller was not found on any access policy.\r\nCaller: appid=4456059e-7d58-4bc2-b391-8c4a0ff1b8f7;oid=0b01321b-93ba-43e2-94ac-3ad44108c3e3;numgroups=1;iss=https://sts.windows.net/a5aa424e-5d6f-47c9-bf70-a1310f4be302/\r\nVault: demoTFE;location=australiaeast" InnerError={"code":"AccessDenied"}
```

reran the plan and apply.
Success.

```shell
Apply complete! Resources: 4 added, 1 changed, 0 destroyed.
```

Now, ive seen a GH issue about this behaviour. Where was it?

Its possible due the issue described [here](https://github.com/terraform-providers/terraform-provider-azurerm/issues/1569#issuecomment-456035861) by [James Bannan](https://github.com/jamesbannan)

> I had this same issue. Using the data source approach as mentioned by @bpoland worked, but only using the access_policy block in the azurerm_key_vault resource. If I used the same policy configuration but using the azurerm_key_vault_access_policy resource, the Key Vault Access Policies were created successfully, but it seemed like the permissions had not taken hold by the time terraform attempted to create the secrets using the service principal which it had just assigned permissions to. Re-running the plan after the first failed attempt succeeded, as the Access Policies were already in place.

In the above quote, James is stating that if he specifies the `access_policy` block within the `azurerm_key_vault` resource he doesnt need to run the `terraform plan` a second time.

When you look at the code for the `modules` repo you can see it is using the split `resource "azurerm_key_vault" "new" {` and `resource "azurerm_key_vault_access_policy" "tf-user" {` method. Im going to change that in my fork and see what the result of a fresh build is.
Done. Pushed to my fork of the repo. Ran a rebuild.

Build succeeds on first go.

-----

For Reference:

* [Bootstrap Module for TFE](https://github.com/hashicorp/private-terraform-enterprise)
  * [My fork of the bootstrap module](https://github.com/Diaxion/private-terraform-enterprise)
* [TFE Module](https://github.com/hashicorp/terraform-azurerm-terraform-enterprise)
  * I dont have a fork of this module and I dont want one.

* [AzureRM Keyvault Documentation](https://www.terraform.io/docs/providers/azurerm/r/key_vault.html)
