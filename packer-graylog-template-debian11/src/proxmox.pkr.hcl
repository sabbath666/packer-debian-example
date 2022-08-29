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
          "netcfg/get_ipaddress=45.12.65.139 ",
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

  template_name        = "debian-11-graylog-template"
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
      "apt-get update && apt-get upgrade",
      "apt-get install software-properties-common ca-certificates apt-transport-https openjdk-11-jre-headless uuid-runtime pwgen dirmngr gnupg wget -y",
      "wget -O- https://www.mongodb.org/static/pgp/server-5.0.asc | gpg --dearmor | tee /usr/share/keyrings/mongodb.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/mongodb.gpg] http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "apt-get update && apt-get install -y mongodb-org",
      "systemctl daemon-reload",
      "systemctl enable mongod.service",
      "systemctl restart mongod.service",
      "systemctl --type=service --state=active | grep mongod",
      "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main\" | tee /etc/apt/sources.list.d/elastic-8.x.list",
      "apt-get update && apt-get install elasticsearch-oss -y",
      "tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null << EOT \\",
      "cluster.name: graylog \\",
      "action.auto_create_index: false \\",
      "EOT",
      "systemctl daemon-reload",
      "systemctl enable elasticsearch.service",
      "systemctl restart elasticsearch.service",
      "wget https://packages.graylog2.org/repo/packages/graylog-4.2-repository_latest.deb",
      "dpkg -i graylog-4.2-repository_latest.deb",
      "apt-get update",
      "apt-get install graylog-server graylog-enterprise-plugins graylog-integrations-plugins graylog-enterprise-integrations-plugins -y",
      "echo -n \"Enter Password: \" && head -1 </dev/stdin | tr -d '\\n' | sha256sum | cut -d\" \" -f1",
      "systemctl daemon-reload",
      "systemctl enable graylog-server.service",
      "systemctl start graylog-server.service",
      "systemctl --type=service --state=active | grep graylog",
      "openssl req -newkey rsa:4096 -x509 -sha256 -days 3650 -nodes -out /etc/ssl/nginx.crt -keyout /etc/ssl/nginx.key -subj '/C=RU/ST=Denial/L=Rostov-on-Don/O=CIB/CN=localhost'"
    ]
  }
}