# ora-vagrantfiles
Vagrant scripts for Oracle DB test environments

The scripts will create an Oracle Linux 7 VM, install Oracle DB 12.2 and
create a DB instance.

## About the VM:
- OS
  - Oracle Linux 7 (latest box)
  - Network: NAT for eth0, host-only adapter for eth1 (192.168.56.11)
  - locale: Japan
- DB
  - Oracle Database 12.2.0.1 (choose response file to use for CDB/non-CDB)
  - DB name: orcl
  - SID: orcl
  - PDB name: pdb1 (if CDB)
  - Listener: LISTENER (192.168.56.11:1521)

## To create new VM:
1. Create a directory for this environment's vagrant files
2. cd into the directory and do `vagrant init`
3. Download contents of this repository into the directory
4. Download Oracle Database 12.2 (https://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html) from https://www.oracle.com/technetwork/database/enterprise-edition/downloads/oracle12c-linux-12201-3608234.html
5. `vagrant up`

## To destroy the VM:
1. cd into the vagrant directory for the environment
2. `vagrant destroy`


