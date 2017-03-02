#!/bin/bash

LOGS="/tmp/bkp_bacula_files-atualdv.log"
RM="/bin/rm"
MAIL="/usr/bin/mail"
EMAIL="douglas@confiservsolucoes.com.br"
RSYNC="/usr/bin/rsync"
MKDIR="/bin/mkdir"
CD="cd"
DU="/usr/bin/du"
BKP_DIR="root@10.21.0.198:/srv/backup/bacula-files-atualcard"
BKP_BACULA_DIR="${BKP_DIR}/etc"
BKP_CATALOG_DIR="${BKP_DIR}/var/lib"
SSH_CMD="ssh -p 22022"
BACULA_DIR="/etc/bacula"
CATALOG_DIR="/var/lib/bacula"

if [ -f  ${LOGS} ]; then
	${RM} -rf ${LOGS}
fi

echo "#### DATA START: $(date) ###" >> ${LOGS}
echo "### SIZE: $(${DU} -sh ${BACULA_DIR}) ###" >> ${LOGS}
echo "### SIZE: $(${DU} -sh ${CATALOG_DIR}) ###" >> ${LOGS}
${RSYNC} -avzPHe "${SSH_CMD}" ${BACULA_DIR} ${BKP_BACULA_DIR} >> ${LOGS}
${RSYNC} -avzPHe "${SSH_CMD}" ${CATALOG_DIR} ${BKP_CATALOG_DIR} >> ${LOGS}
echo "#### DATA END: $(date) ###" >> ${LOGS}

${MAIL} -s "Backup Bacula Files AtualCard to AtualDV" ${EMAIL} < ${LOGS}
