#!/bin/bash
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
CAT="/bin/cat"
BACULA_BASE="/etc/bacula"
BACULA_WD="/var/lib/bacula"
BACULA_PID="/var/run/bacula"
BACULA_LOG="/var/log/bacula"
BACULA_ST="/backup3"
BBCLIENTS="${BACULA_BASE}/keys/clients"
TAR="/bin/tar"
CD="cd"
RM="/bin/rm"
CP="/bin/cp"
MKDIR="/bin/mkdir"
OPENSSL="/usr/bin/openssl"
BACULA_DIR="172.17.0.198"
CLIENT_PASSWORD=$(makepasswd --chars 35)
MONITOR_PASSWORD=$(makepasswd --chars 35)
BC_PASSWORD="hNWTCApqGHKTD6PbCpiYfqDXaUxVNu3WWFa"
BSD_PASSWORD="ixYRtYWabTR7byXSSDqqx7RNBULdN5MaKr7"
DOMAIN="dqs.lan"
FILESET="WebServer-Linux"
CLIENT_IP="172.31.0.201"
CLIENT="servername"
CAP_NAME=$(echo $CLIENT | tr [A-Z] [a-z] | sed -e 's/^./\U&/g; s/ ./\U&/g')
SCHEDULE="Weekly-Cycle-Linux"
#Aqui podemos setar weekly or monthly
RETENTION="weekly"

if [ ! -z ${CLIENT} ]; then
${CAT} << EOF > ${BACULA_BASE}/keys/server.cnf
[ req ]
default_bits = 1024
encrypt_key = yes
distinguished_name = req_dn
x509_extensions = cert_type
prompt = no

[ req_dn ]
C=BR
ST=Parana
L=Curitiba
O=GPB
OU=IT
CN=${CLIENT}.${DOMAIN}
emailAddress=douglas@${DOMAIN}

[ cert_type ]
nsCertType = server

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints=CA:true
EOF

BASE="${BBCLIENTS}/${CLIENT}"

if [ ! -d ${BASE} ]; then
        mkdir ${BASE}
fi

${CD} ${BASE}
${MKDIR} keys
${CD} keys
${OPENSSL} genrsa -out ${CLIENT}-fd.key 2048 || { echo "${RED}FALHA AO GERAR A CHAVE MASTER PARA O BACULA ${CLOSE}"; exit 1; }
${OPENSSL} req -new -x509 -out ${CLIENT}-fd.cert -key ${CLIENT}-fd.key -config ${BACULA_BASE}/keys/server.cnf -extensions v3_ca || { echo "${RED}FALHA AO ASSINAR A CHAVE MASTER PARA O BACULA-FD ${CLOSE}"; exit 1; }
${CAT} ${CLIENT}-fd.key ${CLIENT}-fd.cert > ${CLIENT}-fd.pem
${CP} -Rfa ${BACULA_BASE}/keys/master.cert .


#CREATING CONFIGURATION FILE FOR CLIENT
${CAT} << EOF > ${BASE}/bacula-fd.conf
# LIST DIRECTORS WHO ARE PERMITTED TO CONTACT THIS FILE DAEMON
Director {
  Name = bacula-dir
  Password = "${CLIENT_PASSWORD}"
}

# RESTRICTED DIRECTOR, USED BY TRAY-MONITOR TO GET THE
#   STATUS OF THE FILE DAEMON
Director {
  Name = bacula-mon
  Password = "${MONITOR_PASSWORD}"
  Monitor = yes
}

# "GLOBAL" FILE DAEMON CONFIGURATION SPECIFICATIONS
FileDaemon {
  Name = ${CLIENT}-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /var/run/bacula
  Maximum Concurrent Jobs = 20
  FDAddress = 0.0.0.0
  PKI Signatures = Yes
  PKI Encryption = Yes
  PKI Keypair = "/etc/bacula/keys/${CLIENT}-fd.pem"
  PKI Master Key = "/etc/bacula/keys/master.cert"
}

# SEND ALL MESSAGES EXCEPT SKIPPED FILES BACK TO DIRECTOR
Messages {
  Name = Standard
  director = bacula-dir = all, !skipped, !restored
}
EOF

${CAT} << EOF > ${BACULA_BASE}/clients-jobs/${CLIENT}-jobs.conf
#Configuration to Jobs on ${CLIENT}
Job {
        Name = "${CAP_NAME}-Backup"                            # Nome do Job para Backup do Cliente
        JobDefs = "Default-Linux"                             # JObDefs Definido
        Client = ${CLIENT}-fd                                # Cliente fd
        Storage = ${CAP_NAME}-Storage
        Pool = ${CAP_NAME}-Pool
        FileSet = "${FILESET}"
        Schedule = "${SCHEDULE}"
}

Client {
  Name = ${CLIENT}-fd                                        # Cliente fd
  Address = ${CLIENT_IP}
  Password = "${CLIENT_PASSWORD}"     # Senha do Director do Bacula que foi configurado no cliente na primeira sessão Director
  Maximum Concurrent Jobs = 10 #Habilita o cliente a executar mais de um job por vez
  @/etc/bacula/clients-jobs/${RETENTION}-client  # Arquivo onde contem informacoes sobre o cliente.
}
EOF

${CAT} << EOF > ${BACULA_BASE}/devices/${CLIENT}-device.conf
#Configuration to Device on ${CLIENT}
Device {
  Name = ${CAP_NAME}-Device               # Nome do Device
  Media Type = File                       # Tipo de Midia (DVD, CD, HD, FITA)
  Archive Device = ${BACULA_ST}/${CLIENT}  # Diretorio onde serao salvos os volumes de backup
  LabelMedia = yes;                       # Midias de Etiquetamento do Bacula
  Random Access = Yes;                    #
  AutomaticMount = yes;                   # Montar Automaticamente
  RemovableMedia = no;                    # Midia Removivel
  AlwaysOpen = no;                        # Manter Sempre Aberto
}
EOF

${CAT} << EOF > ${BACULA_BASE}/pools/${CLIENT}-pool.conf
#Configuration for Pool client01
Pool {
  Name = ${CAP_NAME}-Pool             # o Job de Backup por padrao aponta para o 'File'
  Pool Type = Backup                  # O Tipo do Pool = Backup, Restore, Etc.
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 8 days           # Retencao de Volume = 1 Mes
  Volume Use Duration = 7 days        # Duracao de um volume aberto
  Maximum Volume Bytes = 20 Gb        # Tamanho maximo de um volume
  Maximum Volumes      = 10           # Volume Bytes X Volumes <= Dispositivo de backup
  LabelFormat          = "volume-${CLIENT}-"     # Nome Default do Volume
}
EOF

${CAT} << EOF > ${BACULA_BASE}/storages/${CLIENT}-storage.conf
#Configuration for storage client01
Storage {
  Name = ${CAP_NAME}-Storage
  Address = ${BACULA_DIR}                            # Pode ser usado Nome ou IP
  SDPort = 9103                                      # Porta de Comunicação do Storage
  Password = "${BSD_PASSWORD}"                       # Senha Storage Bacula
  Device = ${CAP_NAME}-Device                        # Device de Storage
  Media Type = File                                  # Tipo de Midia (Fita, DVD, HD)
  Maximum Concurrent Jobs = 10                       # Num. Maximo de Jobs executados nessa Storage.
}
EOF

${CAT} << EOF > ${BASE}/bconsole.conf
#CONFIGURATION FOR BCONSOLE
Director {
  Name = bacula-dir
  DIRport = 9101
  address = ${BACULA_DIR}
  Password = "${BC_PASSWORD}"
}
EOF

if [ ! -d ${BACULA_ST}/${CLIENT} ]; then
        mkdir -p ${BACULA_ST}/${CLIENT}
fi
        chown -R bacula:tape ${BACULA_ST}/${CLIENT}
        chown -R bacula:bacula ${BACULA_BASE}

#GERA O PACOTE
${CD} ${BASE}
${TAR} -cJvf ${CLIENT}.tar.xz *

/etc/init.d/bacula-dir force-reload
/etc/init.d/bacula-sd force-reload

else
echo "Usage: ./gera.sh client_name"
fi
