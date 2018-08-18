# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set for each project
project = "uragames"
ip = "192.168.33.21"

hostname = project + ".dev"
synced_folders = {
  "docker" => "/home/bargee/share/" + project,
}

module VagrantPlugins
  module GuestLinux
    class Plugin < Vagrant.plugin("2")
      guest_capability("linux", "change_host_name") { Cap::ChangeHostName }
      guest_capability("linux", "configure_networks") { Cap::ConfigureNetworks }
    end
  end
end

Vagrant.configure(2) do |config|
  config.vm.box = "ailispaw/barge"
  config.vm.hostname = hostname
  config.vm.network "private_network", ip: ip
  synced_folders.each{|from, to|
    config.vm.synced_folder from, to
  }

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 1
    vb.customize [
      "modifyvm", :id,
      "--hwvirtex", "on",
      "--nestedpaging", "on",
      "--largepages", "on",
      "--ioapic", "on",
      "--pae", "on",
      "--paravirtprovider", "kvm",
    ]
  end

  # Docker Release Notes | Docker Documentation
  # https://docs.docker.com/release-notes/
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo mkdir -m 777 /home/bargee/mysql
    sudo ln -s /home/bargee/mysql /var/lib/mysql
    sudo mkdir -m 777 /home/bargee/dynamodb
    sudo ln -s /home/bargee/dynamodb /var/lib/dynamodb
    sudo pkg install tzdata
    sudo cp -L /usr/share/zoneinfo/Japan /etc/localtime
    sudo pkg install locales
    sudo localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
    sudo echo "export LANG=ja_JP.UTF-8" >> /home/bargee/.bash_profile
    sudo wget https://github.com/docker/compose/releases/download/1.21.2/docker-compose-`uname -s`-`uname -m` -P /tmp
    sudo mv /tmp/docker-compose-Linux-x86_64 /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose
    docker-compose --version
    sudo /etc/init.d/docker restart 18.03.1-ce
    # /home/bargee/share/"#{project}"/compose.sh down
    # /home/bargee/share/"#{project}"/compose.sh up
  SHELL

end
