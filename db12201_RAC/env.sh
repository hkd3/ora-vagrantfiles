#!/bin/bash

# variables for set up
########################################
ROOT_PASSWORD='changeme'
ORACLE_PASSWORD='changeme'
GRID_PASSWORD='changeme'
SYS_PASSWORD='changeme'
DBSNMP_PASSWORD='changeme'
ORACLE_INSTALLMEDIADIR='/home/oracle'
ORACLE_INSTALLMEDIAFILE='linuxx64_12201_database.zip'
GRID_INSTALLMEDIAFILE='linuxx64_12201_grid_home.zip'
GI_OUI_RSPFILE='oui_gi122.rsp'
DB_OUI_RSPFILE='oui_db122.rsp'
#HOSTNAME="node${NODENUM}"

# change this variable to create DB using another response file
DBCA_RSPFILE='dbca_createDB_db122_RAC.rsp'

# set up environment variables for Oracle Grid Infrastructure
########################################
GRID_BASE="/u01/app/grid"
GRID_HOME="/u01/app/12.2.0.1/grid"
#GRID_SID="+ASM${NODENUM}"

# set up environment variables for Oracle Database
########################################
ORACLE_BASE="/u01/app/oracle"
ORACLE_HOME=${ORACLE_BASE}/product/12.2.0.1/dbhome_1
ORACLE_CHARACTERSET="AL32UTF8"
#ORACLE_SID="orcl${NODENUM}"
NLS_LANG="American_America.AL32UTF8"

