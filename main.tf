# https://github.com/hashicorp/terraform-azurerm-terraform-enterprise/tree/master/examples/basic

provider "azurerm" {
  version = "~>1.32.1"
}

module "bootstrap" {
  #source                    = "github.com/Diaxion/private-terraform-enterprise/examples/bootstrap-azure"
  source                    = "github.com/Diaxion/private-terraform-enterprise//examples/bootstrap-azure?ref=develop-ausfestivus"
  #source                    = "github.com/Diaxion/private-terraform-enterprise/tree/develop-ausfestivus/examples/bootstrap-azure"
  # source              = "./terraform-private/examples/bootstrap-azure" # currently unusable due to https://github.com/hashicorp/private-terraform-enterprise/pull/22
  prefix                    = "${var.prefix}"
  location                  = "${var.location}"
  address_space             = "${var.address_space}"
  subnet_address_space      = "${var.subnet_address_space}"
  additional_tags           = "${var.additional_tags}"
  address_space_allowlist   = "${var.address_space_allowlist}"  
  key_vault_tenant_id       = "${var.key_vault_tenant_id}"
  key_vault_object_id       = "${var.key_vault_object_id}"
  application_id            = "${var.application_id}"
}

# https://github.com/hashicorp/terraform-azurerm-terraform-enterprise/tree/master/examples/basic
module "tfe_cluster" {
  # source  = "hashicorp/terraform-enterprise/azurerm"
  # version = "0.1.0"
  source                       = "github.com/Diaxion/terraform-azurerm-terraform-enterprise?ref=master"
  #source                       = "/Users/abest/github/terraform-azurerm-terraform-enterprise/"
  resource_group_name          = "${module.bootstrap.resource_group_name}"
  virtual_network_name         = "${module.bootstrap.virtual_network_name}"
  subnet                       = "${module.bootstrap.subnet}"
  domain                       = "${var.dns_domain}"
  key_vault_name               = "${module.bootstrap.key_vault_name}"
  license_file                 = "${var.license_path}"
  tls_pfx_certificate          = "${var.certificate_path}"
  tls_pfx_certificate_password = "${var.certificate_pass}"

  # Optional VARs here - comment out the ones below if you want to return to defaults.
  domain_resource_group_name   = "${var.domain_resource_group_name}"
  #primary_vm_size              = "${var.primary_vm_size}" # Default is `Standard_D4s_v3`
  tls_pfx_certificate_key_size = "${var.tls_pfx_certificate_key_size}" # Default is 4096
  additional_tags              = "${var.additional_tags}"
}