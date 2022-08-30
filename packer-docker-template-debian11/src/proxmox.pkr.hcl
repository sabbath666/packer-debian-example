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
          "netcfg/get_ipaddress=45.12.65.137 ",
          "netcfg/get_netmask=255.255.240.0 ",
          "netcfg/get_gateway=45.12.65.129 ",
          "netcfg/get_nameservers=188.93.16.19 8.8.8.8 ",
          "netcfg/confirn_static=true <wait> ",
          "debian-installer/allow_unauthenticated_ssl=true ",
          "preseed/url=https://raw.githubusercontent.com/sabbath666/packer-debian-example/feature/diffent-templates/packer-docker-template-debian11/src/http/preseed-debian.cfg <wait>",
          "<enter><wait>"
        ]  
  boot_wait  = "2s"

  insecure_skip_tls_verify = true

  template_name        = "debian-11-docker-template"
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
      "apt-get install auditd audispd-plugins",
      "service auditd start",
      "auditctl -a exit,always -F path=/etc/passwd -F perm=wa",
      "auditctl -a exit,always -F path=/usr/bin/dockerd -F perm=wa",
      "auditctl -a exit,always -F path=/var/lib/docker -F perm=wa",
      "auditctl -a exit,always -F path=/etc/docker -F perm=wa",
      "auditctl -a exit,always -F path=/etc/default/docker -F perm=wa",
      "auditctl -a exit,always -F path=/etc/sysconfig/docker -F perm=wa || true",
      "auditctl -a exit,always -F path=/etc/docker/daemon.json -F perm=rwa",
      "auditctl -a exit,always -F path=/usr/bin/containerd -F perm=wa",
      "auditctl -a exit,always -F path=/usr/sbin/runc -F perm=wa",
      "auditctl -a exit,always -F path=/lib/systemd/system/docker.service -F perm=rwa",
      "auditctl -a exit,always -F path=/lib/systemd/system/docker.socket -F perm=rwa",
      "service auditd restart",
      "docker pull hello-world",
      "docker run -d --name hello-world hello-world",
      "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out /etc/ssl/nginx.crt -keyout /etc/ssl/nginx.key -subj '/C=RU/ST=Denial/L=Rostov-on-Don/O=CIB/CN=localhost'"
    ]
  }
}