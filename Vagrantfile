# -*- mode: ruby -*-
# vi: set ft=ruby :

# usage:
#   vagrant up
#   vagrant halt
#   vagrant ssh
#   vagrant destroy

Vagrant.configure("2") do |config|
  config.vm.box = "https://yum.oracle.com/boxes/oraclelinux/latest/ol7-latest.box"

  # host-only adapter (eth1)
  config.vm.network "private_network", ip: "192.168.56.11"

  # bridged adapter (eth2)
  config.vm.network "public_network"

  # VirtualBox VM settings
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end

  # setup script
  config.vm.provision :shell, :path => "setup.sh"

end
