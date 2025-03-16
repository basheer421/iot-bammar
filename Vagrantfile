# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
    config.vm.box = "generic/debian12"
    config.vm.box_version = "4.3.12"
    config.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end

    # SSH
    config.ssh.insert_key = true
    config.vm.synced_folder "./shared", "/shared"

    $ssh_setup_script = <<-SCRIPT
      mkdir -p /home/vagrant/.ssh
      chmod 700 /home/vagrant/.ssh

      cat /shared/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
    SCRIPT
    
    config.vm.define "bammarS" do |server|
      server.vm.hostname = "bammarS"
      server.vm.network "private_network", ip: "192.168.56.110"

      server.vm.provision "shell", inline: $ssh_setup_script
    end
    
    config.vm.define "bammarSW" do |worker|
      worker.vm.hostname = "bammarSW"
      worker.vm.network "private_network", ip: "192.168.56.111"

      worker.vm.provision "shell", inline: $ssh_setup_script
    end
  end
