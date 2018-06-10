provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_datastore" "ds" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cl" {
  name          = "${var.vsphere_compute_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "front_net" {
  name          = "${var.front_net}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "back_net" {
  name          = "${var.back_net}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm_front" {
  count            = 4
  name             = "${var.vm_front_name}-${count.index + 1}"
  resource_pool_id = "${data.vsphere_compute_cluster.cl.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.front_net.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size  = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  folder = "${var.folder}"

  clone {
    linked_clone  = "true"
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.vm_front_name}-${count.index + 1}"
        domain    = "${var.domain_name}"
      }

      network_interface {
        ipv4_address = "${var.net_base}.${count.index + 1}"
        ipv4_netmask = "16"
      }

    ipv4_gateway  = "${var.gateway}"
    dns_server_list = "${var.dns_list}"
    dns_suffix_list = "${var.dns_search}"   

    }
  }

  provisioner "remote-exec" {
    inline = ["sleep 1"]

    connection {
      type     = "ssh"
      user     = "${var.ssh_user}"
      password = "${var.ssh_password}"
    }
  }

  provisioner "local-exec" {
    command = "sshpass -p ${var.ssh_password} ssh-copy-id -i ${var.ssh_key_public} -o StrictHostKeyChecking=no ${var.ssh_user}@${self.guest_ip_addresses.0}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.guest_ip_addresses.0},' --extra-vars backend_ip=${vsphere_virtual_machine.vm_back.guest_ip_addresses.0} --private-key ${var.ssh_key_private} front.yml"
  }
}

resource "vsphere_virtual_machine" "vm_back" {
  name             = "${var.vm_back_name}-${count.index + 1}"
  resource_pool_id = "${data.vsphere_compute_cluster.cl.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.back_net.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label = "disk0"
    size  = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  folder = "${var.folder}"

  clone {
    linked_clone  = "true"
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.vm_back_name}"
        domain    = "${var.domain_name}"
      }

      network_interface {
        ipv4_address = "${var.backend_ip}"
        ipv4_netmask = "16"
      }

    ipv4_gateway = "${var.gateway}"
    dns_server_list = "${var.dns_list}"
    dns_suffix_list = "${var.dns_search}"

    }
  }

  provisioner "remote-exec" {
    inline = []

    connection {
      type     = "ssh"
      user     = "${var.ssh_user}"
      password = "${var.ssh_password}"
    }
  }

  provisioner "local-exec" {
    command = "sshpass -p ${var.ssh_password} ssh-copy-id -i ${var.ssh_key_public} -o StrictHostKeyChecking=no ${var.ssh_user}@${self.guest_ip_addresses.0}"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i '${self.guest_ip_addresses.0},' --private-key ${var.ssh_key_private} back.yml"
  }
}
