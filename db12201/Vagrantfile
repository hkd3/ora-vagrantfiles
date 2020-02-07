# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # build from latest Oracle Linux 7 box
  config.vm.box = "https://yum.oracle.com/boxes/oraclelinux/latest/ol7-latest.box"

  # node1
  config.vm.define :node1 do |node1|

    # hostname
    node1.vm.hostname = "node1"

    # host-only adapter (eth1)
    config.vm.network "private_network", ip: "192.168.56.101"

    # bridged adapter (eth2)
    # config.vm.network "public_network"

    # VirtualBox VM settings
    config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"                             # memory
      vb.customize ["modifyvm", :id, "--cpus", "1"]  # CPU
    end

  end # node1

  # execute setup script
  config.vm.provision :shell, :path => "setup_12201.sh"

end
