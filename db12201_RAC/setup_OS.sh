#!/bin/bash

# PREREQS:
# The files below must be present under /vagrant
# (the shared folder synced to the host machine Vagrant working dir)
# - linuxx64_12201_database.zip
# - linuxx64_12201_grid_home.zip
# - oui_db122.rsp (Database OUI installer response file)
# - oui_gi122.rsp (Grid InfrastructureOUI installer response file)
# - dbca_createDB_db122_RAC_nonCDB.rsp (DBCA create database response file)

NODENUM=${1}
OTHERNUM='0'
if [[ "${NODENUM}" -eq "1" ]];
  then OTHERNUM='2'
  else OTHERNUM='1'
fi

# read variables
########################################
if [[ $(ls /vagrant/env.sh | wc -l) -ne 1 ]]; then
  echo "Error: Please make sure '/vagrant/env.sh' exists"
  exit 1
fi

source /vagrant/env.sh
HOSTNAME="node${NODENUM}"
OTHERHOSTNAME="node${OTHERNUM}"
GRID_SID="+ASM${NODENUM}"
ORACLE_SID="orcl${NODENUM}"

# check that files are present under /vagrant
########################################
if [[ $(ls /vagrant/${ORACLE_INSTALLMEDIAFILE} \
           /vagrant/${GRID_INSTALLMEDIAFILE} \
           /vagrant/${DB_OUI_RSPFILE} \
           /vagrant/${GI_OUI_RSPFILE} \
           /vagrant/${DBCA_RSPFILE} \
           | wc -l) -ne 5 ]]; then
  echo "Not all of required files not found under /vagrant"
  echo "Please have all of the files below under /vagrant :"
  echo "- ${ORACLE_INSTALLMEDIAFILE}"
  echo "- ${GRID_INSTALLMEDIAFILE}"
  echo "- ${DB_OUI_RSPFILE}"
  echo "- ${GI_OUI_RSPFILE}"
  echo "- ${DBCA_RSPFILE}"
  exit 1
fi

# install packages
########################################
echo '[setup_OS.sh] updating yum packages and installing 12cR2 preinstall rpm...'

# install packages
yum -y update
yum -y install oracle-database-server-12cR2-preinstall perl ntp dnsmasq sshpass


# resource limits /etc/security/limits.conf
########################################
echo "[setup_OS.sh] setting resource limits (/etc/security/limits.conf)..."

su - root -c 'cat >> /etc/security/limits.conf << EOF
oracle soft nofile 1024
grid   soft nofile 1024
oracle hard nofile 65536
grid   hard nofile 65536
oracle soft nproc  2047
grid   soft nproc  2047
oracle hard nproc  16384
grid   hard nproc  16384
oracle soft stack  10240
grid   soft stack  10240
oracle hard stack  32768
grid   hard stack  32768
EOF
'


# host resolution
########################################
echo "[setup_OS.sh] setting up host resolution..."

# append to /etc/hosts
su - root -c "echo '192.168.56.10${NODENUM} node${NODENUM} node${NODENUM}' >> /etc/hosts"
su - root -c "echo '192.168.56.10${OTHERNUM} node${OTHERNUM} node${OTHERNUM}' >> /etc/hosts"
su - root -c "echo '192.168.56.11${NODENUM} node${NODENUM}-vip node${NODENUM}-vip' >> /etc/hosts"
su - root -c "echo '192.168.56.11${OTHERNUM} node${OTHERNUM}-vip node${OTHERNUM}-vip' >> /etc/hosts"
su - root -c "echo '192.168.56.121 rac122-scan rac122-scan' >> /etc/hosts"
su - root -c "echo '192.168.56.122 rac122-scan rac122-scan' >> /etc/hosts"
su - root -c "echo '192.168.56.123 rac122-scan rac122-scan' >> /etc/hosts"

# /etc/resolv.conf
if [[ "${NODENUM}" -eq "1" ]];
  then su - root -c "sed -i \"s/^nameserver .*$/nameserver 192.168.56.10${NODENUM}/\" /etc/resolv.conf"
  else su - root -c "sed -i \"s/^nameserver .*$/nameserver 192.168.56.10${OTHERNUM}/\" /etc/resolv.conf"
fi

# services
########################################
echo "[setup_OS.sh] setting up services..."

# alter sshd_config
su - root -c 'sed -i "s/^#PermitRootLogin yes$/PermitRootLogin yes/" /etc/ssh/sshd_config'
su - root -c 'sed -i "s/^PasswordAuthentication no$/PasswordAuthentication yes/" /etc/ssh/sshd_config'
su - root -c 'systemctl restart sshd.service'

# alter pam settings
su - root -c 'sed -i "s/^#auth.*required.*pam_wheel.so use_uid$/auth            required        pam_wheel.so use_uid/" /etc/pam.d/su'
su - root -c 'sed -i "s/^#account.*required.*pam_succeed_if.so user notin root:vagrant$/#account         required        pam_succeed_if.so user notin root:vagrant/" /etc/pam.d/su'

# stop firewall
su - root -c 'systemctl stop firewalld'
su - root -c 'systemctl disable firewalld.service'

# configure ntpd
echo 'OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid"' > /etc/sysconfig/ntpd
su - root -c 'systemctl start ntpd'
su - root -c 'systemctl enable ntpd'

# set up dnsmasq
su - root -c 'systemctl restart dnsmasq'
su - root -c 'systemctl enable dnsmasq'

# set SELinux to permissive
su - root -c 'setenforce Permissive'
su - root -c 'sed -i "s/^SELINUX=enforcing$/SELINUX=permissive/" /etc/selinux/config'

# tweak sudoers to allow wheel to sudo without password
su - root -c "echo '%wheel        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers"


# locale
########################################
echo "[setup_OS.sh] setting up locale..."

# set up locale
sudo localectl set-keymap jp106   # Japanese jp106 keymap

# set up timezone
sudo timedatectl set-timezone Asia/Tokyo


# users and groups
########################################
echo "[setup_OS.sh] setting up users and groups..."

# create groups
if ( grep -q '^oinstall:' /etc/group )
  then su - root -c "groupmod -g 1001 oinstall"
  else su - root -c "groupadd -g 1001 oinstall"
fi
if ( grep -q '^dba:' /etc/group )
  then su - root -c "groupmod -g 1002 dba"
  else su - root -c "groupadd -g 1002 dba"
fi
if ( grep -q '^oper:' /etc/group )
  then su - root -c "groupmod -g 1003 oper"
  else su - root -c "groupadd -g 1003 oper"
fi
if ( grep -q '^asmdba:' /etc/group )
  then su - root -c "groupmod -g 1004 asmdba"
  else su - root -c "groupadd -g 1004 asmdba"
fi
if ( grep -q '^asmoper:' /etc/group )
  then su - root -c "groupmod -g 1005 asmoper"
  else su - root -c "groupadd -g 1005 asmoper"
fi
if ( grep -q '^asmadmin:' /etc/group )
  then su - root -c "groupmod -g 1006 asmadmin"
  else su - root -c "groupadd -g 1006 asmadmin"
fi

# create users
if ( grep -q '^oracle:' /etc/passwd )
  then su - root -c "usermod -u 1001 -g oinstall -G dba,asmdba,oper,wheel oracle"
  else su - root -c "useradd -u 1001 -g oinstall -G dba,asmdba,oper,wheel oracle"
fi
if ( grep -q '^grid:' /etc/passwd )
  then su - root -c "usermod -u 1002 -g oinstall -G dba,asmdba,asmadmin,asmoper,wheel grid"
  else su - root -c "useradd -u 1002 -g oinstall -G dba,asmdba,asmadmin,asmoper,wheel grid"
fi


# ASM disk devices
########################################

# partition device for ASM
if [[ ${NODENUM} == '1' ]]; then
  su - root -c 'fdisk /dev/sdc << EOF
n
p
1


w
EOF
'
fi

# edit udev
su - root -c 'cat > /etc/udev/rules.d/99-oracle.rules << EOF
KERNEL=="sd[b-z]1",ACTION=="add|change",OWNER="grid",GROUP="asmadmin",MODE="0660"
EOF
'

# apply udev rules
su - root -c 'udevadm control --reload-rules && udevadm trigger'

# directories
########################################
echo "[setup_OS.sh] setting up directories..."

# create directories
mkdir -p ${ORACLE_BASE}
mkdir -p ${ORACLE_HOME}
mkdir -p ${GRID_BASE}
mkdir -p ${GRID_HOME}
chown -R grid:oinstall /u01
chown -R oracle:oinstall ${ORACLE_BASE}
chmod -R 775 /u01


# env files
########################################
echo "[setup_OS.sh] creating env files..."

# set environment variables (grid)
cat << EOF >> /home/grid/.gridenv
export LANG='en_US.utf-8'
export DISPLAY=localhost:10.0
export ORACLE_BASE=${GRID_BASE}
export ORACLE_HOME=${GRID_HOME}
export ORACLE_SID=${GRID_SID}
export PATH=\$PATH:\${ORACLE_HOME}/bin
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib"
export NLS_LANG=${NLS_LANG}

export PS1="[\u@\h(\${ORACLE_SID}) \W]\$ "
alias sys='sqlplus / as sysasm'
alias csrt='${GRID_HOME}/bin/crsctl stat res -t'
alias ccrs='${GRID_HOME}/bin/crsctl check crs'
EOF
chown grid:oinstall /home/grid/.gridenv

cat << EOF >> /home/grid/.bash_profile
source /home/grid/.gridenv
EOF

# set environment variables (oracle)
cat << EOF >> /home/oracle/.oraenv_${ORACLE_SID}
export LANG='en_US.utf-8'
export DISPLAY=localhost:10.0
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${ORACLE_SID}
export PATH=\$PATH:\${ORACLE_HOME}/bin
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib"
export NLS_LANG=${NLS_LANG}

export PS1="[\u@\h(\${ORACLE_SID}) \W]\$ "
alias sys='sqlplus / as sysdba'
alias pdb='sqlplus sys/${SYS_PASSWORD}@pdb as sysdba'
alias csrt='${GRID_HOME}/bin/crsctl stat res -t'
EOF
chown oracle:oinstall /home/oracle/.oraenv_${ORACLE_SID}

cat << EOF >> /home/oracle/.bash_profile
source /home/oracle/.oraenv_${ORACLE_SID}
EOF


# passwords
########################################
echo "[setup_OS.sh] setting up passwords..."

su - root -c "echo root:${ROOT_PASSWORD} | chpasswd"
echo oracle:${ORACLE_PASSWORD} | chpasswd
echo grid:${GRID_PASSWORD} | chpasswd


# place setup scripts
########################################

sudo cp -p /vagrant/setup_GI.sh /home/grid
sudo chmod 744 /home/grid/setup_GI.sh
sudo chown grid:oinstall /home/grid/setup_GI.sh

sudo cp -p /vagrant/setup_DB.sh /home/oracle
sudo chmod 744 /home/oracle/setup_DB.sh
sudo chown oracle:oinstall /home/oracle/setup_DB.sh


# SSH passwordless authentication and user equivalency
########################################

if [[ ${NODENUM} == '2' ]]; then

  echo "[setup_OS.sh] creating RSA keys at node2 and distributing..."

  # node2: create RSA keys (grid) and distribute
  echo ${GRID_PASSWORD} | su - grid -c 'ssh-keygen -b 2048 -t rsa -q -N "" -f /home/grid/.ssh/id_rsa'
  echo ${GRID_PASSWORD} | su - grid -c "ssh-keyscan ${OTHERHOSTNAME} >> /home/grid/.ssh/known_hosts"
  echo ${GRID_PASSWORD} | su - grid -c "sshpass -p${GRID_PASSWORD} ssh-copy-id -i /home/grid/.ssh/id_rsa.pub grid@${OTHERHOSTNAME} -p 22"
  echo ${GRID_PASSWORD} | su - grid -c "ssh-keyscan ${HOSTNAME} >> /home/grid/.ssh/known_hosts"
  echo ${GRID_PASSWORD} | su - grid -c "sshpass -p${GRID_PASSWORD} ssh-copy-id -i /home/grid/.ssh/id_rsa.pub grid@${HOSTNAME} -p 22"

  # node2: create RSA keys (oracle) and distribute
  echo ${ORACLE_PASSWORD} | su - oracle -c 'ssh-keygen -b 2048 -t rsa -q -N "" -f /home/oracle/.ssh/id_rsa'
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh-keyscan ${OTHERHOSTNAME} >> /home/oracle/.ssh/known_hosts"
  echo ${ORACLE_PASSWORD} | su - oracle -c "sshpass -p${ORACLE_PASSWORD} ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub oracle@${OTHERHOSTNAME} -p 22"
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh-keyscan ${HOSTNAME} >> /home/oracle/.ssh/known_hosts"
  echo ${ORACLE_PASSWORD} | su - oracle -c "sshpass -p${ORACLE_PASSWORD} ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub oracle@${HOSTNAME} -p 22"

  echo "[setup_OS.sh] creating RSA keys at node1 and distributing..."

  # node1: create RSA keys (grid) and distribute
  echo ${GRID_PASSWORD} | su - grid -c "ssh grid@${OTHERHOSTNAME} 'ssh-keygen -b 2048 -t rsa -q -N \"\" -f /home/grid/.ssh/id_rsa'"
  # node1: distribute to node2
  echo ${GRID_PASSWORD} | su - grid -c "ssh grid@${OTHERHOSTNAME} \"ssh-keyscan ${HOSTNAME} >> /home/grid/.ssh/known_hosts\""
  echo ${GRID_PASSWORD} | su - grid -c "ssh grid@${OTHERHOSTNAME} \"sshpass -p${GRID_PASSWORD} ssh-copy-id -i /home/grid/.ssh/id_rsa.pub grid@${HOSTNAME} -p 22\""
  # node1: distribute to node1
  echo ${GRID_PASSWORD} | su - grid -c "ssh grid@${OTHERHOSTNAME} \"ssh-keyscan ${OTHERHOSTNAME} >> /home/grid/.ssh/known_hosts\""
  echo ${GRID_PASSWORD} | su - grid -c "ssh grid@${OTHERHOSTNAME} \"sshpass -p${GRID_PASSWORD} ssh-copy-id -i /home/grid/.ssh/id_rsa.pub grid@${OTHERHOSTNAME} -p 22\""

  # node1: create RSA keys (oracle)
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh oracle@${OTHERHOSTNAME} 'ssh-keygen -b 2048 -t rsa -q -N \"\" -f /home/oracle/.ssh/id_rsa'"
  # node1: distribute to node2
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh oracle@${OTHERHOSTNAME} \"ssh-keyscan ${HOSTNAME} >> /home/oracle/.ssh/known_hosts\""
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh oracle@${OTHERHOSTNAME} \"sshpass -p${ORACLE_PASSWORD} ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub oracle@${HOSTNAME} -p 22\""
  # node1: distribute to node1
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh oracle@${OTHERHOSTNAME} \"ssh-keyscan ${OTHERHOSTNAME} >> /home/oracle/.ssh/known_hosts\""
  echo ${ORACLE_PASSWORD} | su - oracle -c "ssh oracle@${OTHERHOSTNAME} \"sshpass -p${ORACLE_PASSWORD} ssh-copy-id -i /home/oracle/.ssh/id_rsa.pub oracle@${OTHERHOSTNAME} -p 22\""

fi # end if [[ ${NODENUM} == '2' ]]

