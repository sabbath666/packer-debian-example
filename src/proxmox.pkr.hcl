packer {
  required_plugins {
    proxmox = {
      version = " >= 1.0.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "proxmox-debian-11" {
  proxmox_url = "https://45.12.65.130:8006/api2/json"
  vm_name     = "new-sabbath-debian"
  iso_file    = "local:iso/debian-11.4.0-amd64-DVD-1.iso"
  iso_checksum = "32c7ce39dbc977ce655869c7bd744db39fb84dff1e2493ad56ce05c3540dfc40"
  username         = "${var.pm_user}"
  password         = "${var.pm_pass}"
  node             = "Poincare"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_user}"
  ssh_password           = "${var.ssh_pass}"
  ssh_timeout            = "20m"
  ssh_pty                = true
  ssh_handshake_attempts = 20

  http_directory       = "http"
  boot_command         = [
          "<esc><wait>",
          "auto <wait>",
          "netcfg/disable_dhcp=true ",
          "netcfg/disable_autoconfig=true ",
          "netcfg/use_autoconfig=false ",
          "netcfg/get_ipaddress=45.12.65.135 ",
          "netcfg/get_netmask=255.255.240.0 ",
          "netcfg/get_gateway=45.12.65.129 ",
          "netcfg/get_nameservers=188.93.16.19 8.8.8.8 ",
          "netcfg/confirn_static=true <wait> ",
          "debian-installer/allow_unauthenticated_ssl=true ",
          "preseed/url=https://raw.githubusercontent.com/sabbath666/packer-debian-example/master/src/http/preseed.cfg <wait>",
          "<enter><wait>"
        ]  
  boot_wait  = "2s"

  insecure_skip_tls_verify = true

  template_name        = "packer-debian-11"
  template_description = "packer generated debian-11.4.0-amd64"
  unmount_iso          = true
  
  pool       = "admins"
  memory     = 2048
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true
# disable_kvm = true
  disks {
    type              = "scsi"
    disk_size         = "15G"
    storage_pool      = "local"
    storage_pool_type = "lvm"
    format            = "raw"
  }
  network_adapters {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }
}

build {
  sources = ["source.proxmox-iso.proxmox-debian-11"]
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
      "ls /"
    ]
  }
}