# ora-vagrantfiles : db12201_RAC
Vagrant scripts for Oracle DB test environments

The scripts will create 2 Oracle Linux 7 VMs,
install Oracle Grid Infrastructure 12.2 and
Oracle Database 12.2.

*** The scripts are still a work-in-progress. :( ***

## About the VMs:
- OS
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
  - locale: Japan
- DB (planned)
  - Oracle Database 12.2.0.1
  - DB name: orcl
  - SID: orcl
  - PDB name: pdb1 (if CDB)

## To create new VM:
1. Create a directory for this environment's vagrant files
2. cd into the directory and do `vagrant init`
3. Download contents of this repository into the directory
4. Download linuxx64_12201_grid_home.zip and linuxx64_12201_database.zip from [here](https://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html) and put them in the current directory
5. `vagrant up`

## To destroy the VM:
1. cd into the vagrant directory for the environment
2. `vagrant destroy`
