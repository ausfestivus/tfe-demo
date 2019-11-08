
#
# variables for module bootstrap
# https://github.com/Diaxion/private-terraform-enterprise/tree/master/examples/bootstrap-azure
#
variable "prefix" {
  description = "The prefix to use on all resources, will generate one if not set."
  default     = ""
}

variable "location" {
  description = "The Azure location to build resources in."
  default     = "Central US"
}

variable "address_space" {
  description = "CIDR block range to use for the network."
  default     = "10.0.0.0/16"
}

variable "subnet_address_space" {
  description = "CIDR block range to use for the subnet if a subset of `address_space`. Defaults to `address_space`"
  default     = ""
}

variable "additional_tags" {
  type        = "map"
  description = "A map of additional tags to attach to all resources created."
  default     = {}
}

variable "address_space_allowlist" {
  description = "CIDR block range to use to allow traffic from"
  default     = "*"
}

variable "key_vault_tenant_id" {
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault."
}

variable "key_vault_object_id" {
  description = "The object ID of the service principal for the vault."
}

variable "application_id" {
  description = "The application ID of the service principal for the vault."
}

variable "owner_name" {
  description = "Displayed as a tag on resources created by bootstrap."

}

#
# Variables for module tfe_cluster
#
# variable "resource_group" {
#   description = "Azure resource group the vnet, key vault, and dns domain exist in."
# }

# variable "vnet_name" {
#   description = "Azure virtual network name to deploy in."
# }

# variable "subnet_name" {
#   description = "Azure subnet within the virtual network to deploy in."
# }

variable "dns_domain" {
  description = "Azure hosted DNS domain"
}

# variable "key_vault_name" {
#   description = "Azure hosted Key Vault resource."
# }

variable "certificate_path" {
  description = "Path to a TLS wildcard certificate for the domain in PKCS12 format."
}

variable "certificate_pass" {
  description = "The Password for the PKCS12 Certificate."
}

variable "license_path" {
  description = "Path to the RLI lisence file for Terraform Enterprise."
}

#
# Optional variables
#

variable "domain_resource_group_name" {
  description = "Use this var when the domain your using is in a different resource group."
}

variable "primary_vm_size" {
  description = "The Azure VM size to use. Full list at https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes"
  default = "Standard_D4s_v3"
}

variable "tls_pfx_certificate_key_size" {
  description = "Specify the key length used in the TLS certificate."
  default = "4096"
}




