#!/bin/bash
DB_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
MYSQL_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BDMON_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BCONSOLE_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BFD_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BFDMON_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BSD_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BSDMON_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
BACULA_IP="127.0.0.1"
#BACULA_IP=$(hostname -i)
BACULA_BASE="/etc/bacula"
BACULA_WD="/var/lib/bacula"
BACULA_PID="/var/run/bacula"
BACULA_LOG="/var/log/bacula"
BACULA_ST="/srv/backup"
BACULA_PKG="/srv/packages"
MYSQLADMIN="/usr/bin/mysqladmin"
MYSQL="/usr/bin/mysql"
BBCLIENTS="${BACULA_BASE}/keys/clients"
CLIENTS="/srv/Clients-Windows/"
CAT="/bin/cat"
CD="cd"
RM="/bin/rm"
OPENSSL="/usr/bin/openssl"
CLIENT="bacula-fd"
DOMAIN="gpb.local"
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
APTITUDE="/usr/bin/aptitude"
SED="/bin/sed"

echo "PASSWORDS " >> passwords.txt
echo "MySQL:  ${MYSQL_PASSWORD}" >> passwords.txt
echo "Bacula on MySQL:  ${DB_PASSWORD}" >> passwords.txt
echo "Bacula-mon: ${BDMON_PASSWORD}" >> passwords.txt
echo "Bconsole: ${BCONSOLE_PASSWORD}" >> passwords.txt
echo "Bacula-fd: ${BFD_PASSWORD}" >> passwords.txt
echo "Bacula-fd-mon: ${BFDMON_PASSWORD}" >> passwords.txt
echo "Bacula-sd: ${BSD_PASSWORD}" >> passwords.txt
echo "Bacula-sd-mon: ${BSDMON_PASSWORD}" >> passwords.txt

#SETANDO VARIAVEIS
export DEBIAN_PRIORITY=critical
export DEBIAN_FRONTEND=noninteractive

${APTITUDE} update || { echo "${RED}FALHA AO ATUALIZAR O APTITUDE ${CLOSE}"; exit 1; }
${APTITUDE} install libreadline-dev libreadline6-dev mysql-client mysql-common mysql-server mysql-server-core libmysqld-dev liblzo2-2 liblzo2-dev \
libreadline6-dev libreadline6 lib32readline6 lib32readline6-dev makepasswd libclass-dbi-pg-perl libcompress-zlib-perl zlib-bin zlib1g-dev \
libio-compress-zlib-perl libghc-zlib-dev libssl-dev acl-dev libacl1-dev -y || { echo "${RED}FALHA AO INSTALAR DEPENDENCIAS ${CLOSE}"; exit 1; }

#VOLTANDO VARIAVEIS
unset DEBIAN_PRIORITY
unset DEBIAN_FRONTEND


#DEFININDO SENHA DO MYSQL
${MYSQLADMIN} -u root password "${MYSQL_PASSWORD}"

#CRIANDO USUARIO BANCO
${CAT} << EOF > /tmp/base.sql
CREATE DATABASE bacula;
GRANT ALL PRIVILEGES ON bacula.* TO bacula@localhost IDENTIFIED BY "${DB_PASSWORD}";
EOF

#IMPORTANDO SQL BASE
${MYSQL} -u root -p${MYSQL_PASSWORD} < /tmp/base.sql || { echo "${RED}FALHA AO CARREGAR O BANCO DE DADOS ${CLOSE}"; exit 1; }

mkdir ${BACULA_WD}
mkdir ${BACULA_PID}
mkdir ${BACULA_LOG}
mkdir ${BACULA_PKG}
mkdir -p ${BACULA_BASE}/scripts
mkdir ${BACULA_BASE}/{clients-jobs,devices,filesets,jobsdef,keys,pools,schedules,storages}
mkdir ${BACULA_BASE}/keys/clients
mkdir -p ${CLIENTS}

useradd -s /bin/bash -d ${BACULA_WD}  bacula
chown -R bacula:bacula ${BACULA_WD} ${BACULA_PID} ${BACULA_LOG} ${BACULA_BASE}


cd /usr/src
wget -c  http://www.douglas.wiki.br/Downloads/misc/bacula-7.0.5.tar.gz || { echo "${RED}FALHA AO OBTER O BACULA ${CLOSE}"; exit 1; }

tar -xzvf bacula-7.0.5.tar.gz
cd bacula-7.0.5

CFLAGS="-g -Wall" ./configure --with-openssl=yes --enable-smartalloc --with-mysql  --with-db-name=bacula --with-db-user=bacula --with-db-password=${DB_PASSWORD} --with-db-port=3306 --with-working-dir=${BACULA_WD} --with-pid-dir=${BACULA_PID} --with-logdir=${BACULA_LOG} --with-readline=/usr/include/readline  --disable-conio --enable-lockmgr --with-scriptdir=${BACULA_BASE}/scripts

make
make install
make install-autostart
chown -R bacula:bacula ${BACULA_BASE}
su - bacula -c "${BACULA_BASE}/scripts/make_mysql_tables -u bacula -p${DB_PASSWORD}" || { echo "${RED}FALHA AO CARREGAR AS TABELAS PARA O BACULA ${CLOSE}"; exit 1; }
usermod -s /bin/false bacula
mkdir /usr/src/olds
cp -Rfa ${BACULA_BASE} /usr/src/olds

mkdir -p ${BACULA_ST}/default
chown bacula:tape ${BACULA_ST}
chown -R bacula:bacula ${BACULA_BASE}


cat << EOF > ${BACULA_BASE}/bacula-dir.conf
### MAIN CONFIGURATION FOR BACULA-DIR ###
### DEFINE CONFIGURATION FOR DIRECTOR SERVER ###
Director {
  Name = bacula-dir
  DIRport = 9101                                      # Porta de Comunicacao do Bacula
  QueryFile = "${BACULA_BASE}/scripts/query.sql"         # Script de Query
  WorkingDirectory = "${BACULA_WD}"                # Diretório de Trabalho do Bacula
  PidDirectory = "${BACULA_PID}"                    # PID do Bacula
  Maximum Concurrent Jobs = 20                        # Maximo de Backups em Execucao
  Password = "${BCONSOLE_PASSWORD}"                   # Senha para ajustar no Bconsole
  Messages = Daemon                                   # Nivel de mensagens
}

### DATABASE CONFIGURATION FOR CATALOG SERVICE ###
Catalog {
  Name = Catalogo  				   # Nome do Catalogo
  dbname = "bacula"; dbaddress = "localhost";  dbuser = "bacula"; dbpassword = "${DB_PASSWORD}"  # Configuracoes do MySQL
}

### DEFINE AS MESSAGES WILL BE DELIVERED ###
Messages {
  Name = Standard
  mailcommand = "/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: %t %e of %c %l\" %r"
  operatorcommand = "/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: Intervention needed for %j\" %r"
  mail = root@localhost = all, !skipped
  operator = root@localhost = mount
  console = all, !skipped, !saved
  append = "${BACULA_LOG}/bacula.log" = all, !skipped
  catalog = all
}

### DEFINE AS MESSAGES WILL BE DELIVERED FOR DAEMON MESSAGES DON'T JOB ###
Messages {
  Name = Daemon
  mailcommand = "/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula daemon message\" %r"
  mail = root@localhost = all, !skipped
  console = all, !skipped, !saved
  append = "${BACULA_LOG}/bacula.log" = all, !skipped
}

### RESTRICTED CONSOLE USED BY TRAY-MONITOR TO GET THE STATUS OF THE DIRECTOR ###
Console {
  Name = bacula-mon
  Password = "${BDMON_PASSWORD}"
  CommandACL = status, .status
}

### PLEASE PUT ALL INCLUDE FILES BELOW ###

#Including other configuration files about clients and jobs
@|"sh -c 'for f in ${BACULA_BASE}/clients-jobs/*.conf ; do echo @\${f} ; done'"

#Including other configuration files about pools
@|"sh -c 'for f in ${BACULA_BASE}/pools/*.conf ; do echo @\${f} ; done'"

#Including other configuration files about storages
@|"sh -c 'for f in ${BACULA_BASE}/storages/*.conf ; do echo @\${f} ; done'"

#Including other configuration files about jobsdef
@|"sh -c 'for f in ${BACULA_BASE}/jobsdef/*.conf ; do echo @\${f} ; done'"

#Including other configuration files about schedules
@|"sh -c 'for f in ${BACULA_BASE}/schedules/*.conf ; do echo @\${f} ; done'"

#Including other configuration files about filesets
@|"sh -c 'for f in ${BACULA_BASE}/filesets/*.conf ; do echo @\${f} ; done'"
EOF


cat << EOF > ${BACULA_BASE}/bacula-fd.conf
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = bacula-dir                                  # Nome do Director
  Password = "${BFD_PASSWORD}"   # ESTA SENHA ESTA DEFINIDA NO ARQUIVO DE CLIENTE EM /ETC/BACULA/BACULA-DIR-CLIENTS-AND-JOBS.CONF
}

#
# Restricted Director, used by tray-monitor to get the
#   status of the file daemon
#
Director {
  Name = bacula-mon
  Password = "${BFDMON_PASSWORD}"    # ESTA SENHA E UTILIZADO PELO BACULA-MONITOR
  Monitor = yes
}

#
# "Global" File daemon configuration specifications
#
FileDaemon {
  Name = bacula-fd                                  # Nome do Bacula-fd
  FDport = 9102                                     # Porta de Comunicacao do bacula-fd
  WorkingDirectory = "${BACULA_WD}"                # Diretorio de trabalho
  Pid Directory = "${BACULA_PID}"               # Diretorio de Pid
  Maximum Concurrent Jobs = 20                      # Numero maximo de jobs executados no bacula
  FDAddress = 0.0.0.0	                    # COMENTAR OU REMOVER ESSA LINHA PARA QUE ELE POSSA 'OUVIR' CONEXOES EM TODAS AS INTERFACES
  PKI Signatures = Yes            # Habilita a assinatura dos dados
  PKI Encryption = Yes            # Habilita a criptografia dos dados
  PKI Keypair = "${BACULA_BASE}/keys/clients/${CLIENT}/bacula-fd.pem"    # Arquivo que contem a chave publica e privada
  PKI Master Key = "${BACULA_BASE}/keys/master.cert"    # Arquivo com a chave publica do servidor
}

# Send all messages except skipped files back to Director
Messages {
  Name = Standard
  director = bacula-dir = all, !skipped, !restored        # AS MENSAGEM SAO ENCAMINHADAS PARA O 'BACULA-DIR' DEFINIDO NESSA LINHA
}
EOF

cat << EOF > ${BACULA_BASE}/bacula-sd.conf
### MAIN CONFIGURATION FOR BACULA-SD ###
Storage {
  Name = bacula-sd                                # Nome do Storage
  SDPort = 9103                                   # Porta do Director
  WorkingDirectory = "${BACULA_WD}"            # Diretorio de Trabalho
  Pid Directory = "${BACULA_PID}"               # Pid do Bacula
  Maximum Concurrent Jobs = 20                    # Maximo de Backups em Execucao
  SDAddress = 0.0.0.0                             # Nome ou IP do Storage do Bacula
}

#
# List Directors who are permitted to contact Storage daemon
#
Director {
  Name = bacula-dir
  Password = "${BSD_PASSWORD}"
}

#
# Restricted Director, used by tray-monitor to get the
#   status of the storage daemon
# Usado pelo tray-monitor do bacula para obter status do servidor
Director {
  Name = bacula-mon
  Password = "${BSDMON_PASSWORD}"
  Monitor = yes
}

# Send all messages to the Director,
# mount messages also are sent to the email address
Messages {
  Name = Standard
  director = bacula-dir = all
}

#Including other configuration files about devices
@|"sh -c 'for f in ${BACULA_BASE}/devices/*.conf ; do echo @\${f} ; done'"
EOF


cat << EOF > ${BACULA_BASE}/bconsole.conf
#Configuração do Bacula console (bconsole)
Director {
  Name = bacula-dir #Nome do servidor que é o bacula director
  DIRport = 9101 #Porta que o bacula director está escutando
  address = ${BACULA_IP} #endereço do servidor bacula director
  Password = "${BCONSOLE_PASSWORD}" #senha do bacula director
}
EOF




cat << EOF > ${BACULA_BASE}/clients-jobs/monthly-client
##########################################################
## ARQUIVO PARA CONFIGURACAO DE CLIENTE LINUX NO BACULA ##
##########################################################

        Catalog = Catalogo				# Nome do Catalogo definido
        File Retention = 30 days                        # Tempo de Retencao do Backup
        Job Retention = 1 months                        # Tempo de Retencao do Job
        AutoPrune = yes                                 # Prune de Jobs/Arquivos Expirados
EOF

cat << EOF > ${BACULA_BASE}/clients-jobs/weekly-client
##########################################################
## ARQUIVO PARA CONFIGURACAO DE CLIENTE LINUX NO BACULA ##
##########################################################

        Catalog = Catalogo				# Nome do Catalogo definido
        File Retention = 7 days                         # Tempo de Retencao do Backup
        Job Retention = 7 days                          # Tempo de Retencao do Job
        AutoPrune = yes                                 # Prune de Jobs/Arquivos Expirados
EOF

cat << EOF > ${BACULA_BASE}/clients-jobs/director-jobs.conf
#Configuration for Director
Job {
        Name = "Catalog-Backup"                                                # Nome do Job Para Backup do Catalogo
        JobDefs = "Default-Linux"                                              # JobDefs usado para operacao
        Level = Full                                                           # Nivel do Job (Full, Incremental, Diferencial)
        FileSet = "Catalog"                                                    # File Set Definido para Esse Job
        Schedule = "Catalog-Cycle"                                             # Agendamento Definido para Esse Job
        RunBeforeJob = "${BACULA_BASE}/scripts/make_catalog_backup.pl Catalogo"   # Acao executada antes da operacao
        Write Bootstrap = "${BACULA_WD}/%c.bsr"                             # Arquivo gerado pelo Bacula para armazenar informacoes de backups feitos em seus clientes.
        Priority = 11                                                              # Executar depois do Backup - ajustar prioridade
}

# JOB DE RESTAURACAO - (RESTORE) - SO E PRECISO ESSE JOBS PARA RESTAURACAO DE BACKUP #
Job {
        Name = "Restore-Files"                                                # Nome do Job Para Restore
        Type = Restore                                                        # Tipo de Job (Backup, Restore, Verificacao)
        Client = bacula-fd                                                    # Nome do Cliente FD
        FileSet = "Default-Linux"                                             # File Set Definido para Esse Job
        Storage = Default-Storage                                             # Agendamento Definido para Esse Job
        Pool = Default-Pool                                                   # Define a Pool
        Messages = Standard                                                   # Nivel de mensagens
        Where = /tmp/bacula-restores                                          # Diretorio onde o bacula ira restaurar os arquivos nos clientes
}

Job {
        Name = "Director-Backup"                           # Nome do Job para Backup do Director (Proprio Servidor Bacula)
        JobDefs = "Default-Linux"                           # JObDefs Definido
        Client = bacula-fd                                # Cliente fd
        Storage = Default-Storage
        Pool = Default-Pool
}

Client {
        Name = bacula-fd                                        # Cliente fd
        Address = ${BACULA_IP}                                     # Ajustado no /etc/hosts
        Password = "${BFD_PASSWORD}"                            # Senha do Director do Bacula
        @${BACULA_BASE}/clients-jobs/monthly-client                # Arquivo onde contem informacoes sobre o cliente.
}
EOF


cat << EOF > ${BACULA_BASE}/devices/default-device.conf
#Device default for all clients
Device {
  Name = Default-Device                   # Nome do Device
  Media Type = File                       # Tipo de Midia (DVD, CD, HD, FITA)
  Archive Device = ${BACULA_ST}/default    # Diretorio onde serao salvos os volumes de backup
  LabelMedia = yes;                       # Midias de Etiquetamento do Bacula
  Random Access = Yes;                    #
  AutomaticMount = yes;                   # Montar Automaticamente
  RemovableMedia = no;                    # Midia Removivel
  AlwaysOpen = no;                        # Manter Sempre Aberto
}
EOF


cat << EOF > ${BACULA_BASE}/filesets/catalog.conf
#Configuration file for catalog
FileSet {
        Name = "Catalog"
# Arquivos que serao incluidos para serem copiados ao backup
        Include {
                Options {
                        signature = SHA1
                        compression = GZIP
                        verify = pin1
                        onefs = no
                }
                File = "${BACULA_WD}/bacula.sql"
                }
}
EOF

cat << EOF > ${BACULA_BASE}/filesets/default-linux.conf
#Configuration file for default-linux
FileSet {
        Name = "Default-Linux"                                       # Nome do FileSets
# Arquivos que serao incluidos para serem copiados ao backup
        Include {
                Options {
                        signature = SHA1
                        compression = GZIP
                        verify = pin1
                        onefs = no
                }
                File = /etc
                File = /root
                File = /var/log
                File = /home
		File = /srv
                }
# Arquivos que serao ignorados ao backup
        Exclude {
                File = ${BACULA_WD}
                File = /proc
                File = /tmp
                File = /.journal
                File = /.fsck
		File = /srv/backup
                }
}
EOF


cat << EOF > ${BACULA_BASE}/filesets/default-windows.conf
#Configuration file for default-windows
FileSet {
        Name = "Default-Windows"
	#Habilita o Volume shadow copy service
	Enable VSS = yes
# Arquivos que serao incluidos para serem copiados ao backup
        Include {
#               Plugin = "alldrivers"
                        Options {
                                signature = SHA1
                                Compression = GZIP
                                OneFS = no
                                }
                        File = "C:/"
                }
}
EOF

cat << EOF > ${BACULA_BASE}/jobsdef/default-linux.conf
# JOB PADRAO PARA O BACULA SERVER #
JobDefs {
        Name = "Default-Linux"                          # Nome do Job Padrao
        Type = Backup                                   # Tipo de Job (Backup, Restore, Verificacao)
        Level = Incremental                             # Nivel do Job (Full, Incremental, Diferencial)
        Client = bacula-fd                             # Nome do Cliente FD
        FileSet = "Default-Linux"                       # File Set Definido para Esse Job
        Schedule = "Monthly-Cycle-Linux"                # Agendamento Definido para Esse Job
        Storage = Default-Storage                       # Define Storage
        Messages = Standard                             # Nivel de mensagens
        Pool = Default-Pool                             # Define a Pool
        Priority = 10                                   # Qual o nivel de Prioridade
        Write Bootstrap = "${BACULA_WD}/%c.bsr"      # Arquivo gerado pelo Bacula para armazenar informacoes de backups feitos em seus clientes.
        Allow Mixed Priority = yes			# this means a high priority job will not have to wait for other jobs to finish before starting
# AS OPCOES ABAIXO EVITAM QUE SEJAM DUPLICADO JOBS NO SERVIDOR, CASO TENHA UM JOB DUPLICADO O MESMO E CANCELADO
        Allow Duplicate Jobs = no                       # Permite Jobs Duplicados
        Cancel Lower Level Duplicates = yes             # Cancela niveis inferiores duplicados
}
EOF

cat << EOF > ${BACULA_BASE}/jobsdef/default-windows.conf
# JOB DE BACKUP PARA OS SERVIDORES WINDOWS SERVER #
JobDefs {
        Name = "Default-Windows"                        # Nome do Job Para Servidores Windows
        Type = Backup                                   # Tipo de Job (Backup, Restore, Verificacao)
        Level = Incremental                             # Nivel do Job (Full, Incremental, Diferencial)
        Client = bacula-fd                              # Nome do Cliente FD
        FileSet = "Default-Windows"                     # File Set Definido para Esse Job
        Schedule = "Monthly-Cycle-Linux"                # Agendamento Definido para Esse Job
        Storage = Default-Storage                       # Define Storage
        Messages = Standard                             # Nivel de mensagens
        Pool = Default-Pool                             # Define a Pool
        Priority = 10                                   # Qual o nivel de Prioridade
        Write Bootstrap = "${BACULA_WD}/%c.bsr"      # Arquivo gerado pelo Bacula para armazenar informacoes de backups feitos em seus clientes.
# AS OPCOES ABAIXO EVITAM QUE SEJAM DUPLICADO JOBS NO SERVIDOR, CASO TENHA UM JOB DUPLICADO O MESMO E CANCELADO
        Allow Duplicate Jobs = no                       # Permite Jobs Duplicados
        Cancel Lower Level Duplicates = yes             # Cancela niveis inferiores duplicados
}
EOF

cat << EOF > ${BACULA_BASE}/pools/default-pool.conf
#Default Pool
Pool {
  Name = Default-Pool                 # o Job de Backup por padrao aponta para o 'File'
  Pool Type = Backup		      # O Tipo do Pool = Backup, Restore, Etc.
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 1 month          # Retencao de Volume = 1 Mes
  Volume Use Duration = 7 days      # Duracao de um volume aberto
  Maximum Volume Bytes = 20 Gb        # Tamanho maximo de um volume
  Maximum Volumes      = 10           # Volume Bytes X Volumes <= Dispositivo de backup
  LabelFormat          = "volume-default-"     # Nome Default do Volume
}
EOF

cat << EOF > ${BACULA_BASE}/pools/scratch.conf
# Scratch pool definition
# Volumes que serao emprestado a alguma Pool temporariamente
Pool {
  Name = Scratch
  Pool Type = Backup
}
EOF

cat << EOF > ${BACULA_BASE}/schedules/catalog.conf
# DEFINICOES DE AGENDAMENTO DO BACKUP DOS CATALOGOS #
#        FEITO SEMPRE DEPOIS DOS BACKUPS            #
Schedule {
  Name = "Catalog-Cycle"
  Run = Level=Full sun-sat at 09:15
}
EOF

cat << EOF > ${BACULA_BASE}/schedules/monthly-cycle-linux.conf
# AGENDAMENTO PADRAO DO BACULA - CICLO MENSAL DE BACKUP #
Schedule {
  Name = "Monthly-Cycle-Linux"                        # Ciclo Semanal de Backup
  Run = Level=Full 1st sun at 09:00                   # Backup Full no Primeiro Domingo do Mes as 23:05 hrs
  Run = Level=Incremental mon-sat at 19:00            # Backup Incremental de Seg. a Sabado as 23:05 hrs
}
EOF

cat << EOF > ${BACULA_BASE}/schedules/weekly-cycle-linux.conf
# AGENDAMENTO PADRAO DO BACULA - CICLO SEMANAL DE BACKUP #
Schedule {
  Name = "Weekly-Cycle-Linux"                        # Ciclo Semanal de Backup
  Run = Level=Full sun at 09:00                       # Backup Full no Primeiro Domingo do Mes as 23:05 hrs
  Run = Level=Incremental mon-sat at 19:00            # Backup Incremental de Seg. a Sabado as 23:05 hrs
}
EOF

cat << EOF > ${BACULA_BASE}/schedules/monthly-cycle-windows.conf
# AGENDAMENTO PARA SERVIDOR WINDOWS SERVER - CICLO SEMANAL DE BACKUP #
Schedule {
  Name = "Monthly-Cycle-Windows"                      # Ciclo Mensal de Backup
  Run = Level=Full 1st sun at 09:00                   # Backup Full no Primeiro Domingo do Mes as 23:05 hrs
  Run = Level=Incremental mon-sat at 19:00            # Backup Incremental de Seg. a Sabado as 23:05 hrs
}
EOF

cat << EOF > ${BACULA_BASE}/storages/default-storage.conf
#Configuration for Default storage
Storage {
  Name = Default-Storage
  Address = ${BACULA_IP}                             # Pode ser usado Nome ou IP
  SDPort = 9103                                      # Porta de Comunicação do Storage
  Password = "${BSD_PASSWORD}"                       # Senha Storage Bacula
  Device = Default-Device                            # Device de Storage
  Media Type = File                                  # Tipo de Midia (Fita, DVD, HD)
  Maximum Concurrent Jobs = 10                       # Num. Maximo de Jobs executados nessa Storage.
}
EOF


### GERA SSL
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
CN=$CLIENT.${DOMAIN}
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

#Making the master.key
${CD} ${BACULA_BASE}/keys/
${OPENSSL} genrsa -out master.key 2048 || { echo "${RED}FALHA AO GERAR A CHAVE MASTER PARA O BACULA ${CLOSE}"; exit 1; }
${OPENSSL} req -new -x509 -out master.cert -key master.key -config ${BACULA_BASE}/keys/server.cnf -extensions v3_ca || { echo "${RED}FALHA AO ASSINAR A CHAVE MASTER PARA O BACULA ${CLOSE}"; exit 1; }

${CD} ${BASE}
${OPENSSL} genrsa -out ${CLIENT}.key 2048 || { echo "${RED}FALHA AO GERAR A CHAVE MASTER PARA O BACULA-FD ${CLOSE}"; exit 1; }
${OPENSSL} req -new -x509 -out ${CLIENT}.cert -key ${CLIENT}.key -config ${BACULA_BASE}/keys/server.cnf -extensions v3_ca || { echo "${RED}FALHA AO ASSINAR A CHAVE MASTER PARA O BACULA-FD ${CLOSE}"; exit 1; }
${CAT} ${CLIENT}.key ${CLIENT}.cert > ${CLIENT}.pem


#changing permissions for bacula
chown -R bacula:bacula ${BACULA_BASE}
chown -R bacula:tape ${BACULA_ST}


#Amending daemon files
${CAT} << EOF > bacula-dir.patch
--- bacula-dir	2014-08-19 09:48:44.886820180 -0300
+++ /etc/init.d/bacula-dir	2014-08-19 09:50:36.562959071 -0300
@@ -41,6 +41,10 @@

 PIDFILE=${BACULA_PID}/\${NAME}.\${BPORT}.pid

+if [ ! -d ${BACULA_PID} ]; then
+	mkdir -p ${BACULA_PID}
+fi
+
 if [ "x\${BUSER}" != "x" ]; then
    USERGRP="--chuid \${BUSER}"
    if [ "x\${BGROUP}" != "x" ]; then
EOF

${CAT} << EOF > bacula-fd.patch
--- bacula-fd	2014-08-19 09:48:44.886820180 -0300
+++ /etc/init.d/bacula-fd	2014-08-19 09:51:04.820824428 -0300
@@ -41,6 +41,10 @@

 PIDFILE=${BACULA_PID}/\${NAME}.\${BPORT}.pid

+if [ ! -d ${BACULA_PID} ]; then
+        mkdir -p ${BACULA_PID}
+fi
+
 if [ "x\${BUSER}" != "x" ]; then
    USERGRP="--chuid \${BUSER}"
    if [ "x\${BGROUP}" != "x" ]; then
EOF

${CAT} << EOF > bacula-sd.patch
--- bacula-sd	2014-08-19 09:48:44.886820180 -0300
+++ /etc/init.d/bacula-sd	2014-08-19 09:50:50.823825743 -0300
@@ -41,6 +41,10 @@

 PIDFILE=${BACULA_PID}/\${NAME}.\${BPORT}.pid

+if [ ! -d ${BACULA_PID} ]; then
+        mkdir -p ${BACULA_PID}
+fi
+
 if [ "x\${BUSER}" != "x" ]; then
    USERGRP="--chuid \${BUSER}"
    if [ "x\${BGROUP}" != "x" ]; then
EOF

patch -p1 /etc/init.d/bacula-dir -i bacula-dir.patch
patch -p1 /etc/init.d/bacula-sd  -i bacula-sd.patch
patch -p1 /etc/init.d/bacula-fd  -i bacula-fd.patch

rm -rf bacula-dir.patch bacula-sd.patch bacula-fd.patch

/etc/init.d/bacula-dir restart
/etc/init.d/bacula-sd restart
/etc/init.d/bacula-fd restart


aptitude install apache2 php5 php5-mysql php5-gd php5-mcrypt sudo php5-cli -y
cd /var/www/
rm -rf index.html
mkdir bacula-web
cd bacula-web
wget http://www.bacula-web.org/files/bacula-web.org/downloads/bacula-web-latest.tgz
tar -xvf bacula-web-latest.tgz
rm -rf bacula-web-latest.tgz
chown -R www-data:www-data /var/www
cd /var/www/application/config/

cat << EOF > /var/www/bacula-web/application/config/config.php
<?php

// Show inactive clients (false by default)
\$config['show_inactive_clients'] = true;

// Hide empty pools (displayed by default)
\$config['hide_empty_pools'] = false;

// Jobs per page (Jobs report page)
\$config['jobs_per_page'] = 25;

// Translations
\$config['language'] = 'pt_BR';

// en_US -> English - maintened by Davide Franco (bacula-dev@dflc.ch)
// es_ES -> Spanish - Mantained by Juan Luis Franc�s Jim�nez
// it_IT -> Italian - Mantained by Gian Domenico Messina (gianni.messina AT c-ict.it)
// fr_FR -> French - Mantained by Morgan LEFIEUX (comete AT daknet.org)
// de_DE -> German - Mantained by Florian Heigl
// sv_SV -> Swedish - Maintened by Daniel Nylander (po@danielnylander.se)
// pt_BR -> Portuguese Brazil - Last updated by J. Ritter (condector@gmail.com)
// nl_NL -> Dutch - last updated by Dion van Adrichem

// MySQL bacula catalog
\$config[0]['label'] = 'Prod Server';
\$config[0]['host'] = 'localhost';
\$config[0]['login'] = 'bacula';
\$config[0]['password'] = '${DB_PASSWORD}';
\$config[0]['db_name'] = 'bacula';
\$config[0]['db_type'] = 'mysql';
\$config[0]['db_port'] = '3306';

?>
EOF

cat << EOF > /etc/apache2/sites-available/bacula-web
<VirtualHost *:80>
        ServerAdmin webmaster@${DOMAIN}
	ServerName bacula-web@${DOMIAN}
        DocumentRoot /var/www/bacula-web
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        <Directory /var/www/bacula-web>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
                AuthUserFile /etc/apache2/access/bacula-htpasswd
                AuthName "Bacula"
                AuthType Basic
                require valid-user
        </Directory>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Order allow,deny
                Allow from all
        </Directory>

        ErrorLog /var/log/apache2/bacula-web.${DOMAIN}-error.log
        LogLevel warn
        CustomLog /var/log/apache2/bacula-web.${DOMAIN}-access.log combined
</VirtualHost>

EOF

mkdir /etc/apache2/access/
htpasswd -cdb /etc/apache2/access/bacula-htpasswd bacula sci134*
a2dissite default
a2ensite bacula-web
/etc/init.d/apache2 restart

cd ${BACULA_PKG}
wget -c http://www.douglas.wiki.br/Downloads/misc/bacula-win64-5.2.10.exe
wget -c http://www.douglas.wiki.br/Downloads/misc/bacula-win32-5.2.10.exe


mkdir /var/www/webacula
cd /var/www/webacula
wget -c http://www.douglas.wiki.br/Downloads/misc/webacula-5.5.1.tar.gz
tar -xvf webacula-5.5.1.tar.gz
mv webacula-5.5.1/* .
rm -rf webacula-5.5.1*
chmod 770 /etc/bacula
chown root:bacula /sbin/bconsole
chmod u=rwx,g=rx,o=  /sbin/bconsole
chown root:bacula /etc/bacula/bconsole.conf
chmod u=rw,g=r,o= /etc/bacula/bconsole.conf

usermod -aG bacula www-data

echo "www-data ALL=NOPASSWD: /sbin/bconsole" >> /etc/sudoers
echo "www-data ALL=NOPASSWD: /sbin/bacula-dir" >> /etc/sudoers

sed -i 's|;date.timezone =|date.timezone = America/Sao_Paulo|g' /etc/php5/apache2/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 3600/g' /etc/php5/apache2/php.ini

sed -i 's/db.config.username = root/db.config.username = bacula/g' /var/www/webacula/application/config.ini
sed -i "s/db.config.password =/db.config.password = ${DB_PASSWORD}/g" /var/www/webacula/application/config.ini
sed -i 's|def.timezone = "Europe/Minsk"|def.timezone = "America/Sao_Paulo"|g' /var/www/webacula/application/config.ini
sed -i 's|bacula.bconsole    = "/opt/bacula/sbin/bconsole"|bacula.bconsole    = "/sbin/bconsole"|g' /var/www/webacula/application/config.ini
sed -i 's|bacula.bconsolecmd = "-n -c /opt/bacula/etc/bconsole.conf"|bacula.bconsolecmd = "-n -c /etc/bacula/bconsole.conf"|g' /var/www/webacula/application/config.ini
sed -i 's|; locale = "en"| locale = "pt_BR"|g' /var/www/webacula/application/config.ini

cat << EOF > /var/www/webacula/install/db.conf
# See also application/config.ini

# bacula settings
db_name="bacula"
db_pwd="${DB_PASSWORD}"
db_user="bacula"

# !!! CHANGE_THIS !!!
webacula_root_pwd="sci134*"
EOF

cd /var/www/webacula/install/MySql/
./10_make_tables.sh
./20_acl_make_tables.sh

chown -R www-data:www-data /var/www/webacula

cat << EOF > /etc/apache2/sites-available/webacula
<VirtualHost *:80>
        ServerAdmin webmaster@${DOMAIN}
        ServerName webacula.${DOMAIN}
        DocumentRoot /var/www/webacula/html

		<Directory /var/www/webacula/html>
		   Options Indexes FollowSymLinks
		   AllowOverride All
		   Order allow,deny
		   Allow from all
		</Directory>

		<Directory /var/www/webacula/docs>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/application>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/languages>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/library>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/install>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/tests>
		   Order deny,allow
		   Deny from all
		</Directory>

		<Directory /var/www/webacula/data>
		   Order deny,allow
		   Deny from all
		</Directory>


        ErrorLog /var/log/apache2/webacula.${DOMAIN}-error.log
        LogLevel warn
        CustomLog /var/log/apache2/webacula.${DOMAIN}-access.log combined
</VirtualHost>
EOF

cat << EOF > /var/www/webacula/html/.htaccess
SetEnv APPLICATION_ENV production
RewriteEngine On
RewriteBase   /
RewriteCond %{REQUEST_FILENAME} -s [OR]
RewriteCond %{REQUEST_FILENAME} -l [OR]
RewriteCond %{REQUEST_FILENAME} -d
RewriteRule ^.*\$ - [NC,L]
RewriteRule ^.*\$ index.php [NC,L]
php_flag magic_quotes_gpc off
php_flag register_globals off
EOF


a2ensite webacula

a2enmod rewrite

/etc/init.d/apache2 restart


