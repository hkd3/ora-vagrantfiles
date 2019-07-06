# ora-vagrantfiles : db12201_RAC
Vagrant scripts for Oracle DB test environments on VirtualBox

The scripts will create 2 Oracle Linux 7 VMs,
install Oracle Grid Infrastructure 12.2 and
Oracle Database 12.2, and create a database.

Make sure the host computer has at least
16 GB of memory and at least 100 GB of free disk space.

## About the VMs:
- OS
  - Memory: 6 GB
  - Oracle Linux 7.6
  - Network:
    - NAT for eth0
    - host-only adapter as public LAN for eth1
      - node1: 192.168.56.101
      - node1-vip: 192.168.56.111
      - node2: 192.168.56.102
      - node2-vip: 192.168.56.112
    - private network as ASM/RAC interconnect LAN for eth2
      - node1: 192.168.100.101
      - node2: 192.168.100.102
  - Locale: Japan
- DB (CDB)
  - Oracle Database 12.2.0.1
  - DB name: orcl
  - SID: orcl1, orcl2
- Storage
  - 36.5 GB local disk (thin provisioned) for each VM as local storage
  - 15.7 GB local disk (thin provisioned) for each VM as additional
    local storage (comes with the box, not used)
  - 40 GB shared disk for ASM (thick provisioned)

## To create new VM:
0. Install Vagrant and VirtualBox
   - [Vagrant (HashiCorp)](https://www.vagrantup.com/)
   - [VirtualBox (Oracle)](https://www.virtualbox.org/)
1. Create a directory for this environment's vagrant files
2. Download contents of this repository into the directory
3. Download linuxx64_12201_grid_home.zip and linuxx64_12201_database.zip from [here](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html) and put them in the current directory
   - Make sure to read and agree to Oracle's OTN License Agreement!
4. cd into the directory and execute `vagrant up`

## To destroy the VM:
1. cd into the vagrant directory of the environment
2. `vagrant destroy`

## Tips
- Vagrantfile
  - Specify where you want to create your thick-provisioned ASM disk (40 GB)
    in the `--filename` option of the `createmedium` command.
    Otherwise, it will be created in the working directory of the Vagrant
    environment.
- Grid Infrastructure install
  - Some pre-requisites are ignored, such as memory size, swap size,
    NTP setting, and SCAN resolution.
- Database install
  - Some pre-requisites are ignored, such as memory size, swap size,
    NTP setting, and SCAN resolution.
- Database creation
  - Some pre-requisites are ignored, such as memory size, swap size,
    NTP setting, and SCAN resolution.

