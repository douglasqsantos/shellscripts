#!/bin/bash

LOGS="/tmp/bkp_bacula_files.log"
RM="/bin/rm"
MAIL="/usr/bin/mail"
EMAIL="douglas@confiservsolucoes.com.br"
RSYNC="/usr/bin/rsync"
MKDIR="/bin/mkdir"
CD="cd"
DU="/usr/bin/du"
BKP_DIR="/backup4/bacula-files"
BKP_BACULA_DIR="${BKP_DIR}/etc"
BKP_CATALOG_DIR="${BKP_DIR}/var/lib"
BACULA_DIR="/etc/bacula"
CATALOG_DIR="/var/lib/bacula"

if [ -f  ${LOGS} ]; then
	${RM} -rf ${LOGS}
fi

if [ ! -d ${BKP_DIR} ]; then
	${MKDIR} -pv ${BKP_DIR} >> ${LOGS}
fi

if [ ! -d ${BKP_BACULA_DIR} ]; then
        ${MKDIR} -pv ${BKP_BACULA_DIR} >> ${LOGS}
fi

if [ ! -d ${BKP_CATALOG_DIR} ]; then
        ${MKDIR} -pv ${BKP_CATALOG_DIR} >> ${LOGS}
fi

echo "#### DATA START: $(date) ###" >> ${LOGS}
echo "### SIZE: $(${DU} -sh ${BKP_DIR}) ###" >> ${LOGS}
${CD} ${BKP_DIR}
${RSYNC} -avzPH ${BACULA_DIR} ${BKP_BACULA_DIR} >> ${LOGS}
${RSYNC} -avzPH ${CATALOG_DIR} ${BKP_CATALOG_DIR} >> ${LOGS}
echo "### SIZE: $(${DU} -sh ${BKP_DIR}) ###" >> ${LOGS}
echo "#### DATA END: $(date) ###" >> ${LOGS}


${MAIL} -s "Backup Bacula Files AtualCard on /backup4" ${EMAIL} < ${LOGS}
