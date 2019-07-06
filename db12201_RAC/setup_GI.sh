#!/bin/bash

# PREREQS:
# The files below must be present under /vagrant
# (the shared folder synced to the host machine Vagrant working dir)
# - linuxx64_12201_grid_home.zip
# - oui_gi122.rsp (Grid InfrastructureOUI installer response file)

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
OTHERHOSTNAME="node${OTHERNUM}"
GRID_SID="+ASM${NODENUM}"
ORACLE_SID="orcl${NODENUM}"


# check that files are present under /vagrant
########################################
if [[ $(ls /vagrant/${GRID_INSTALLMEDIAFILE} \
           /vagrant/${GI_OUI_RSPFILE} \
           | wc -l) -ne 2 ]]; then
  echo "Not all of required files not found under /vagrant"
  echo "Please have all of the files below under /vagrant :"
  echo "- ${GRID_INSTALLMEDIAFILE}"
  echo "- ${GI_OUI_RSPFILE}"
  exit 1
fi


# install Oracle Grid Infrastructure
########################################
function install_grid_infrastructure () {
  echo '[setup_GI.sh] installing Oracle Grid Infrastructure...'

  # unzip Grid into Grid Home
  sudo -u grid unzip /vagrant/${GRID_INSTALLMEDIAFILE} -d ${GRID_HOME}

  # install grid infrastructure
  sudo -u grid ${GRID_HOME}/gridSetup.sh -silent -ignorePrereqFailure -waitforcompletion -responseFile /vagrant/${GI_OUI_RSPFILE}

  # orainstRoot.sh
  sudo -u root /u01/app/oraInventory/orainstRoot.sh
  sudo -u grid ssh grid@${OTHERHOSTNAME} sudo /u01/app/oraInventory/orainstRoot.sh

  # root.sh
  sudo -u root ${GRID_HOME}/root.sh
  sudo -u grid ssh grid@${OTHERHOSTNAME} sudo ${GRID_HOME}/root.sh
}
if [[ ${NODENUM} == '1' ]]; then
  install_grid_infrastructure
fi


# customize GI to reduce overhead
########################################
function reduce_grid_overhead () {
  echo '[setup_GI.sh] customizing GI to reduce overhead...'

  # disable GIMR (mgmtdb)
  sudo -u grid ${GRID_HOME}/bin/srvctl stop mgmtdb
  sudo -u grid ${GRID_HOME}/bin/srvctl disable mgmtdb
  sudo -u grid ${GRID_HOME}/bin/srvctl stop mgmtlsnr
  sudo -u grid ${GRID_HOME}/bin/srvctl disable mgmtlsnr

  # disable QoS (qosmserver)
  sudo -u grid ${GRID_HOME}/bin/srvctl stop qosmserver
  sudo -u grid ${GRID_HOME}/bin/srvctl disable qosmserver

  # disable diagsnap
  sudo -u grid ${GRID_HOME}/bin/oclumon manage -disable diagsnap
}
if [[ ${NODENUM} == '1' ]]; then
  reduce_grid_overhead
fi

