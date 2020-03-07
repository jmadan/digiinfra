variable "droplet_user" {}

resource "digitalocean_droplet" "dubuntu" {
  image              = "ubuntu-19-10-x64"
  name               = "zeus"
  region             = "sfo2"
  size               = "s-4vcpu-8gb"
  monitoring         = true
  ipv6               = true
  private_networking = true
  ssh_keys           = [var.ssh_fingerprint]

  provisioner "local-exec" {
    // doesn't listen for a little while after API gives the all-clear
    command = "sleep 20s"
  }


  provisioner "remote-exec" {
    connection {
      user    = "root"
      type    = "ssh"
      host    = digitalocean_droplet.dubuntu.ipv4_address
      agent   = true
      timeout = "2m"
    }
    inline = [
      "export PATH=$PATH:/usr/bin",
      "sudo apt-get update",
      "sysctl -p",
      "adduser --disabled-password --gecos '' ${var.droplet_user}",
      "usermod -aG admin ${var.droplet_user}",
      "mkdir -p /home/${var.droplet_user}/.ssh",
      "chmod 0700 /home/${var.droplet_user}/.ssh",
      "cp /root/.ssh/authorized_keys /home/${var.droplet_user}/.ssh",
      "chmod 0600 /home/${var.droplet_user}/.ssh/authorized_keys",
      "chown -R ${var.droplet_user}:${var.droplet_user} /home/${var.droplet_user}",
      "sed -i -e '/Defaults\\s\\+env_reset/a Defaults\\texempt_group=admin/' /etc/sudoers",
      "sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers",
      "visudo -cf /etc/sudoers",
      "sed -i -e 's/#PubkeyAuthentication/PubkeyAuthentication/g' /etc/ssh/sshd_config",
      "sed -i -e 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config",
      "/usr/sbin/sshd -t && systemctl reload sshd",
      "ufw allow OpenSSH",
      "echo 'y' | ufw enable",
      "sudo apt install postgresql-11 -y"
    ]
  }
}

# resource "digitalocean_firewall" "dbuntu-ufw" {
#   name = "only-22-80-and-443"

#   droplet_ids = [digitalocean_droplet.dubuntu.id]

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "22"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "80"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }

#   inbound_rule {
#     protocol         = "tcp"
#     port_range       = "443"
#     source_addresses = ["0.0.0.0/0", "::/0"]
#   }
# }

output "ip" {
  value = "${digitalocean_droplet.dubuntu.ipv4_address}"
}
