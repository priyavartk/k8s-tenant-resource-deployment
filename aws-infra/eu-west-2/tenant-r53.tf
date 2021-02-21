variable "tenant" {
   type = string
}
module "tenant_dns" {
   source = "./modules/tenant-dns" 
   tenant = "${var.tenant}"
}
