#!/bin/bash

# PREREQS:
# The files below must be present under /vagrant
# (the shared folder synced to the host machine Vagrant working dir)
# - linuxx64_12201_database.zip
# - 12cR2-install.rsp (Database OUI installer response file)
# - 12cR2-dbca.rsp (DBCA create database response file)

# variables for set up
########################################
ROOT_PASSWORD='welcome1'
ORACLE_PASSWORD='welcome1'
ORACLE_INSTALLMEDIADIR='/home/oracle'
ORACLE_INSTALLMEDIAFILE='linuxx64_12201_database.zip'
DB_OUI_RSPFILE='oui_db122.rsp'

# change this variable to create DB using another response file
DBCA_RSPFILE='dbca_createDB_db122_single_nonCDB.rsp'

# set up environment variables
########################################
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=${ORACLE_BASE}/product/12.2.0.1/dbhome_1
ORACLE_CHARACTERSET=AL32UTF8
ORACLE_SID=orcl

# check that files are present under /vagrant
########################################
if [[ $(ls /vagrant/${ORACLE_INSTALLMEDIAFILE} /vagrant/${DB_OUI_RSPFILE} /vagrant/${DBCA_RSPFILE} | wc -l) -ne 3 ]]; then
  echo "Required files not found under /vagrant"
  exit 1
fi

# install packages
########################################

# install packages
yum -y update
yum -y install oracle-database-server-12cR2-preinstall

# set up linux
########################################

# set up locale
localectl set-keymap jp106   # Japanese jp106 keymap

# alter sshd_config
su - root -c 'sed -i "s/^#PermitRootLogin yes$/PermitRootLogin yes/" /etc/ssh/sshd_config'
su - root -c 'sed -i "s/^PasswordAuthentication no$/PasswordAuthentication yes/" /etc/ssh/sshd_config'
su - root -c 'systemctl restart sshd.service'

# alter pam settings
su - root -c 'sed -i "s/^#auth.*required.*pam_wheel.so use_uid$/auth            required        pam_wheel.so use_uid/" /etc/pam.d/su'
su - root -c 'sed -i "s/^#account.*required.*pam_succeed_if.so user notin root:vagrant$/#account         required        pam_succeed_if.so user notin root:vagrant/" /etc/pam.d/su'

# set up user permissions and passwords
su - root -c "echo root:${ROOT_PASSWORD} | chpasswd"
su - root -c 'usermod -a -G wheel oracle'
echo oracle:${ORACLE_PASSWORD} | chpasswd


# install Oracle Database
########################################

# copy files from /vagrant to proper locations
su - oracle -c "unzip /vagrant/${ORACLE_INSTALLMEDIAFILE} -d ${ORACLE_INSTALLMEDIADIR}"
cp -p /vagrant/${DB_OUI_RSPFILE} ${ORACLE_INSTALLMEDIADIR}
cp -p /vagrant/${DBCA_RSPFILE} ${ORACLE_INSTALLMEDIADIR}
chown oracle:oinstall ${ORACLE_INSTALLMEDIADIR}/${DB_OUI_RSPFILE}
chown oracle:oinstall ${ORACLE_INSTALLMEDIADIR}/${DBCA_RSPFILE}
chmod 644 ${ORACLE_INSTALLMEDIADIR}/${DB_OUI_RSPFILE}
chmod 644 ${ORACLE_INSTALLMEDIADIR}/${DBCA_RSPFILE}

# create directories
mkdir -p ${ORACLE_HOME}
chown -R oracle:oinstall ${ORACLE_BASE}/..
chmod -R 775 ${ORACLE_BASE}/..

# set environment variables
cat << EOF >> /home/oracle/.oraenv_orcl
export LANG='en_US.utf-8'
export NLS_LANG='American_America.AL32UTF8'
export DISPLAY=localhost:10.0
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_HOME}
export ORACLE_SID=${ORACLE_SID}
export PATH=\$PATH:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH="\${ORACLE_HOME}/lib"

export PS1="[\u@\h(${ORACLE_SID}) \W]\$ "
alias sys='sqlplus / as sysdba'
EOF
chown oracle:oinstall /home/oracle/.oraenv_orcl

cat << EOF >> /home/oracle/.bash_profile
source /home/oracle/.oraenv_orcl
EOF

# install database
su - oracle -c "unzip ${ORACLE_INSTALLMEDIADIR}/${ORACLE_INSTALLMEDIAFILE} -d ${ORACLE_INSTALLMEDIADIR}"
su - oracle -c "${ORACLE_INSTALLMEDIADIR}/database/runInstaller -silent -showProgress -ignorePrereq -waitforcompletion -responseFile ${ORACLE_INSTALLMEDIADIR}/${DB_OUI_RSPFILE}"
su - root -c "${ORACLE_BASE}/../oraInventory/orainstRoot.sh"
su - root -c "${ORACLE_HOME}/root.sh"

# create listener
su - oracle -c "${ORACLE_HOME}/bin/netca -silent -responseFile ${ORACLE_HOME}/assistants/netca/netca.rsp"

# create database
su - oracle -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -responseFile ${ORACLE_INSTALLMEDIADIR}/${DBCA_RSPFILE}"

