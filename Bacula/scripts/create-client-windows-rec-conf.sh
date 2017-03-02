#!/bin/bash
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
CAT="/bin/cat"
BACULA_BASE="/etc/bacula"
BACULA_WD="/var/lib/bacula"
BACULA_PID="/var/run/bacula"
BACULA_LOG="/var/log/bacula"
BACULA_ST="/srv/backup"
BBCLIENTS="${BACULA_BASE}/keys/clients"
TAR="/bin/tar"
CD="cd"
CHMOD="/bin/chmod"
CHOWN="/bin/chown"
RM="/bin/rm"
CP="/bin/cp"
MKDIR="/bin/mkdir"
BSD_PASSWORD="f18e94153dda5183aaf203dc12e5033f"
CLIENT_PASSWORD="3c271f47b2278beaa2d450b7d6ad8db3"
DOMAIN="atualdv.local"
BACULA_DIR="127.0.0.1"
CLIENT_IP="127.0.0.1"
CLIENT="servername"
CAP_NAME=$(echo $CLIENT | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g')
FILESET="Recovery-${CAP_NAME}-Windows"
SCHEDULE="Weekly-Cycle-Recovery-Windows"
#Aqui podemos setar three-days/weekly or monthly
RETENTION="three-days"
SS_BKP="/srv/backup/SystemState/${CAP_NAME}"

if [ ! -d ${SS_BKP} ]; then
	${MKDIR} -p ${SS_BKP}
	${CHMOD} -R 777 ${SS_BKP}
	${CHOWN} -R bacula:tape ${SS_BKP}
fi

${CAT} << EOF > ${BACULA_BASE}/filesets/recovery-${CLIENT}-windows.conf
#Configuration file for default-windows
FileSet {
        Name = "${FILESET}"
# Arquivos que serao incluidos para serem copiados ao backup
        Include {
                 Options {
                         signature = SHA1
                         compression = GZIP
                         verify = pin1
                         onefs = no
                }
                 File = /srv/backup/SystemState/${CAP_NAME}

                }
}
EOF


${CAT} << EOF > ${BACULA_BASE}/clients-jobs/${CLIENT}-recovery-jobs.conf
#Configuration to Jobs on ${CLIENT}
Job {
        Name = "${CAP_NAME}-Rec-Backup"                            # Nome do Job para Backup do Cliente
        JobDefs = "Default-Windows"                             # JObDefs Definido
        Client = ${CLIENT}-Rec-fd                                # Cliente fd
        Storage = ${CAP_NAME}-Rec-Storage
        Pool = ${CAP_NAME}-Rec-Pool
        FileSet = "${FILESET}"
        Schedule = "${SCHEDULE}"
	ClientRunAfterJob = "/etc/bacula/scripts/clean-${CLIENT}.sh"  # Acao executada antes da operacao
}

Client {
  Name = ${CLIENT}-Rec-fd                                        # Cliente fd
  Address = ${CLIENT_IP}
  Password = "${CLIENT_PASSWORD}"     # Senha do Director do Bacula que foi configurado no cliente na primeira sessão Director
  Maximum Concurrent Jobs = 10 #Habilita o cliente a executar mais de um job por vez
  @/etc/bacula/clients-jobs/${RETENTION}-client  # Arquivo onde contem informacoes sobre o cliente.
}
EOF

${CAT} << EOF > ${BACULA_BASE}/devices/${CLIENT}-recovery-device.conf
#Configuration to Device on ${CLIENT}
Device {
  Name = ${CAP_NAME}-Rec-Device               # Nome do Device
  Media Type = File                       # Tipo de Midia (DVD, CD, HD, FITA)
  Archive Device = ${BACULA_ST}/${CLIENT}-rec  # Diretorio onde serao salvos os volumes de backup
  LabelMedia = yes;                       # Midias de Etiquetamento do Bacula
  Random Access = Yes;                    #
  AutomaticMount = yes;                   # Montar Automaticamente
  RemovableMedia = no;                    # Midia Removivel
  AlwaysOpen = no;                        # Manter Sempre Aberto
}
EOF

${CAT} << EOF > ${BACULA_BASE}/pools/${CLIENT}-recovery-pool.conf
#Configuration for Pool ${CLIENT}
Pool {
  Name = ${CAP_NAME}-Rec-Pool             # o Job de Backup por padrao aponta para o 'File'
  Pool Type = Backup                  # O Tipo do Pool = Backup, Restore, Etc.
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 4 days           # Retencao de Volume = 1 Mes
  Volume Use Duration = 3 days        # Duracao de um volume aberto
  Maximum Volume Bytes = 20 Gb        # Tamanho maximo de um volume
  Maximum Volumes      = 30           # Volume Bytes X Volumes <= Dispositivo de backup
  LabelFormat          = "volume-${CLIENT}-recovery-"     # Nome Default do Volume
}
EOF

${CAT} << EOF > ${BACULA_BASE}/storages/${CLIENT}-recovery-storage.conf
#Configuration for storage client01
Storage {
  Name = ${CAP_NAME}-Rec-Storage
  Address = ${BACULA_DIR}                            # Pode ser usado Nome ou IP
  SDPort = 9103                                      # Porta de Comunicação do Storage
  Password = "${BSD_PASSWORD}"                       # Senha Storage Bacula
  Device = ${CAP_NAME}-Rec-Device                        # Device de Storage
  Media Type = File                                  # Tipo de Midia (Fita, DVD, HD)
  Maximum Concurrent Jobs = 10                       # Num. Maximo de Jobs executados nessa Storage.
}
EOF

${CAT} << EOF > /etc/bacula/scripts/clean-${CLIENT}.sh
#!/bin/bash

## Variables
RM="/bin/rm"
CLI_PATH="/srv/backup/SystemState/${CAP_NAME}/*"

## Cleaning up the Path
\${RM} -rf \${CLI_PATH}
EOF

${CHMOD} -R 777 /etc/bacula/scripts/clean-${CLIENT}.sh

if [ ! -d ${BACULA_ST}/${CLIENT}-rec ]; then
        ${MKDIR} -p ${BACULA_ST}/${CLIENT}-rec
fi
        ${CHOWN} -R bacula:tape ${BACULA_ST}/${CLIENT}-rec
        ${CHOWN} -R bacula:bacula ${BACULA_BASE}

/etc/init.d/bacula-dir force-reload
/etc/init.d/bacula-sd force-reload
