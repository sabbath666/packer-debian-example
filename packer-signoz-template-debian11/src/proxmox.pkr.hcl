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
  vm_name     = "destory-debian"
  iso_file    = "local:iso/debian-11.4.0-amd64-netinst.iso"
  iso_checksum = "32c7ce39dbc977ce655869c7bd744db39fb84dff1e2493ad56ce05c3540dfc40"
  username         = "${var.pm_user}"
  password         = "${var.pm_pass}"
  node             = "Poincare"
  iso_storage_pool = "local"

  ssh_username           = "${var.ssh_user}"
  ssh_password           = "${var.ssh_pass}"
  ssh_timeout            = "10m"
  ssh_pty                = true
  ssh_handshake_attempts = 10

  http_directory       = "http"
  boot_command         = [
          "<esc><wait>",
          "auto <wait>",
          "netcfg/disable_dhcp=true ",
          "netcfg/disable_autoconfig=true ",
          "netcfg/use_autoconfig=false ",
          "netcfg/get_ipaddress=45.12.65.138 ",
          "netcfg/get_netmask=255.255.240.0 ",
          "netcfg/get_gateway=45.12.65.129 ",
          "netcfg/get_nameservers=188.93.16.19 8.8.8.8 ",
          "netcfg/confirn_static=true <wait> ",
          "debian-installer/allow_unauthenticated_ssl=true ",
          "preseed/url=https://raw.githubusercontent.com/Hexacosidedroid/packer-signoz-template-debian11/master/src/http/preseed-debian.cfg <wait>",
          "<enter><wait>"
        ]  
  boot_wait  = "2s"

  insecure_skip_tls_verify = true

  template_name        = "debian-11-signoz-template"
  template_description = "packer generated debian-11.4.0-amd64"
  unmount_iso          = true
  
  pool       = "admins"
  memory     = 2048
  cores      = 1
  sockets    = 1
  os         = "l26"
  qemu_agent = true

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
    execute_command = "{{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    inline = [
      "apt-get update",
      "apt-get remove --purge apache2 apache2-utils -y",
      "apt-get install ca-certificates curl gnupg lsb-release -y",
      "mkdir -p /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "echo \\",
      "\"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \\",
      "$(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "apt-get update",
      "apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y",
      "groupadd docker || true",
      "usermod -aG docker packer",
      "apt-get install git",
      "git clone -b main https://github.com/SigNoz/signoz.git",
      "cd signoz/deploy/",
      "docker swarm init",
      "docker stack deploy -c docker-swarm/clickhouse-setup/docker-compose.yaml signoz",
      "docker stack services signoz",
      "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out /etc/ssl/nginx.crt -keyout /etc/ssl/nginx.key -subj '/C=RU/ST=Denial/L=Rostov-on-Don/O=CIB/CN=localhost'"
    ]
  }
}