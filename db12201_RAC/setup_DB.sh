#!/bin/bash

# PREREQS:
# The files below must be present under /vagrant
# (the shared folder synced to the host machine Vagrant working dir)
# - linuxx64_12201_database.zip
# - oui_db122.rsp (Database OUI installer response file)
# - dbca_createDB_db122_RAC_nonCDB.rsp (DBCA create database response file)

# ARGS:
#   $1: node number

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
GRID_SID="+ASM${NODENUM}"
ORACLE_SID="orcl${NODENUM}"


# check that files are present under /vagrant
########################################
if [[ $(ls /vagrant/${ORACLE_INSTALLMEDIAFILE} \
           /vagrant/${DB_OUI_RSPFILE} \
           /vagrant/${DBCA_RSPFILE} \
           | wc -l) -ne 3 ]]; then
  echo "Not all of required files not found under /vagrant"
  echo "Please have all of the files below under /vagrant :"
  echo "- ${ORACLE_INSTALLMEDIAFILE}"
  echo "- ${DB_OUI_RSPFILE}"
  echo "- ${DBCA_RSPFILE}"
  exit 1
fi


# install Oracle Database
########################################
function install_oracle_database () {
  echo '[setup.sh] installing Oracle Database...'

  # unzip Oracle Database install files
  sudo -u oracle unzip /vagrant/${ORACLE_INSTALLMEDIAFILE} -d ${ORACLE_INSTALLMEDIADIR}

  # install database
  sudo -u oracle ${ORACLE_INSTALLMEDIADIR}/database/runInstaller -silent -showProgress -ignorePrereqFailure -waitforcompletion -responseFile /vagrant/${DB_OUI_RSPFILE}

  # root.sh
  sudo -u root ${ORACLE_HOME}/root.sh
  sudo -u oracle ssh oracle@${OTHERHOSTNAME} sudo ${ORACLE_HOME}/root.sh
}
if [[ ${NODENUM} == '1' ]]; then
  install_oracle_database
fi

# create DB
########################################
function create_database () {
  echo '[setup.sh] creating database...'

  # create database
  sudo -u oracle ${ORACLE_HOME}/bin/dbca -silent -createDatabase -ignorePreReqs -responseFile /vagrant/${DBCA_RSPFILE}
}
if [[ ${NODENUM} == '1' ]]; then
  create_database
fi

