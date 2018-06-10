variable "vsphere_server" {
  default = "192.168.81.50"
}

variable "vsphere_user" {
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  default = "C!5co123"
}

variable "vsphere_datacenter" {
  default = "uktme-01"
}

variable "vsphere_datastore" {
  default = "nvermand_esxi_nfs_datastore"
}

variable "vsphere_compute_cluster" {}
variable "front_net" {}
variable "back_net" {}

variable "vsphere_template" {
  default = "packer-ubuntu-xenial"
}

variable "vm_front_name" {}
variable "vm_back_name" {}

variable "domain_name" {
  default = "uktme.cisco.com"
}

variable "folder" {}

variable "ssh_user" {
  default = "nvermand"
}

variable "ssh_password" {
  default = "C1sco123"
}

variable "ssh_key_private" {
  default = "/home/nvermand/.ssh/id_rsa"
}

variable "ssh_key_public" {
  default = "/home/nvermand/.ssh/id_rsa.pub"
}

variable "gateway" {
  default = "10.10.0.1"
}

variable "backend_ip" {
  default = "10.10.60.1"
}

variable "net_base" {
  default = "10.10.50"
}

variable "dns_list" {
  default = [ "10.52.248.72", "10.52.248.73" ]
}

variable "dns_search" {
  default = [ "uktme.cisco.com" ]
}

output "frontend_ips" {
  value = [ "${vsphere_virtual_machine.vm_front.*.default_ip_address}" ]
}


