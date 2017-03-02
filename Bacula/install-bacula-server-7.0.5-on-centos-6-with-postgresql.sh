#!/bin/bash
DB_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
PG_PASSWORD=$(cat /dev/urandom | hexdump -n 30| cut -d \  -f 2-| head -n 1 | tr -d " ")
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
YUM="/usr/bin/yum"
CHKCONFIG="/sbin/chkconfig"
SED="/bin/sed"

echo "PASSWORDS " >> passwords.txt
echo "PostgreSQL:  ${PG_PASSWORD}" >> passwords.txt
echo "Bacula on PostgreSQL:  ${DB_PASSWORD}" >> passwords.txt
echo "Bacula-mon: ${BDMON_PASSWORD}" >> passwords.txt
echo "Bconsole: ${BCONSOLE_PASSWORD}" >> passwords.txt
echo "Bacula-fd: ${BFD_PASSWORD}" >> passwords.txt
echo "Bacula-fd-mon: ${BFDMON_PASSWORD}" >> passwords.txt
echo "Bacula-sd: ${BSD_PASSWORD}" >> passwords.txt
echo "Bacula-sd-mon: ${BSDMON_PASSWORD}" >> passwords.txt

#SETANDO VARIAVEIS

${YUM} check-update
${YUM} update -y  || { echo "${RED}FALHA AO ATUALIZAR OS REPOSITORIOS ${CLOSE}"; exit 1; }
${YUM} install postgresql postgresql-contrib postgresql-devel postgresql-docs postgresql-libs postgresql-server perl-Class-DBI-Pg \
readline-devel readline-static readline zlib zlib-devel zlib-static libmcrypto-devel openssl-devel -y  || { echo "${RED}FALHA AO INSTALAR PACOTES ${CLOSE}"; exit 1; }


#INICIALIZANDO O POSTGRESQL
${CHKCONFIG} --add postgresql
${CHKCONFIG} postgresql on
/etc/init.d/postgresql initdb


#AJUSTANDO O BANCO PARA RECEBER O BACULA
${SED} -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf
${SED} -i "s|host    all         all         ::1/128               ident|host    all         all         ::1/128               md5|g" /var/lib/pgsql/data/pg_hba.conf
/etc/init.d/postgresql restart

cat << EOF > /tmp/base.sql
ALTER USER postgres WITH PASSWORD '${PG_PASSWORD}';
CREATE USER bacula WITH PASSWORD '${DB_PASSWORD}';
CREATE DATABASE bacula WITH OWNER bacula ENCODING 'SQL_ASCII' TEMPLATE=template0;
EOF

cd /tmp
su postgres -c 'psql -f /tmp/base.sql' || { echo "${RED}FALHA AO CARREGAR O BANCO DE DADOS ${CLOSE}"; exit 1; }


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

CFLAGS="-g -Wall" ./configure --with-openssl=yes --enable-smartalloc --with-postgresql --with-db-name=bacula --with-db-user=bacula --with-db-password=${DB_PASSWORD} --with-db-port=3306 --with-working-dir=${BACULA_WD} --with-pid-dir=${BACULA_PID} --with-logdir=${BACULA_LOG} --with-readline=/usr/include/readline  --disable-conio --enable-lockmgr --with-scriptdir=${BACULA_BASE}/scripts

make
make install
make install-autostart
chown -R bacula:bacula ${BACULA_BASE}
su - bacula -c "${BACULA_BASE}/scripts/make_postgresql_tables -U bacula -d bacula" || { echo "${RED}FALHA AO CARREGAR AS TABELAS PARA O BACULA ${CLOSE}"; exit 1; }
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
  dbname = "bacula"; dbaddress = "localhost";  dbuser = "bacula"; dbpassword = "${DB_PASSWORD}"  # Configuracoes do PostgreSQL
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

${CHKCONFIG} --add bacula-dir
${CHKCONFIG} bacula-dir on
${CHKCONFIG} --add bacula-sd
${CHKCONFIG} bacula-sd on
${CHKCONFIG} --add bacula-fd
${CHKCONFIG} bacula-fd on



/etc/init.d/bacula-dir start
/etc/init.d/bacula-sd start
/etc/init.d/bacula-fd start


${YUM} install httpd php php-pgsql php-gd -y
${CHKCONFIG} --add httpd
${CHKCONFIG} httpd on

cd /var/www/html
rm -rf index.html
mkdir bacula-web
cd bacula-web
wget http://www.bacula-web.org/files/bacula-web.org/downloads/bacula-web-latest.tgz
tar -xvf bacula-web-latest.tgz
rm -rf bacula-web-latest.tgz
chown -R apache:apache /var/www/html/bacula-web
cd /var/www/html/bacula-web/application/config/

cat << EOF > /var/www/html/bacula-web/application/config/config.php
<?php

// Show inactive clients (false by default)
\$config['show_inactive_clients'] = true;

// Hide empty pools (displayed by default)
\$config['hide_empty_pools'] = false;

// Jobs per page (Jobs report page)
\$config['jobs_per_page'] = 25;

// Translations
\$config['language'] = 'en_US';

// en_US -> English - maintened by Davide Franco (bacula-dev@dflc.ch)
// es_ES -> Spanish - Mantained by Juan Luis Franc�s Jim�nez
// it_IT -> Italian - Mantained by Gian Domenico Messina (gianni.messina AT c-ict.it)
// fr_FR -> French - Mantained by Morgan LEFIEUX (comete AT daknet.org)
// de_DE -> German - Mantained by Florian Heigl
// sv_SV -> Swedish - Maintened by Daniel Nylander (po@danielnylander.se)
// pt_BR -> Portuguese Brazil - Last updated by J. Ritter (condector@gmail.com)
// nl_NL -> Dutch - last updated by Dion van Adrichem

// PostgreSQL bacula catalog
\$config[0]['label'] = 'Prod Server';
\$config[0]['host'] = 'localhost';
\$config[0]['login'] = 'bacula';
\$config[0]['password'] = '${DB_PASSWORD}';
\$config[0]['db_name'] = 'bacula';
\$config[0]['db_type'] = 'pgsql';
\$config[0]['db_port'] = '5432';

?>
EOF

cat << EOF > /etc/httpd/conf.d/bacula-web.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html/bacula-web
        <Directory />
                Options FollowSymLinks
                AllowOverride All
        </Directory>
        <Directory /var/www/html/bacula-web>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
                AuthUserFile /etc/httpd/access/bacula-htpasswd
                AuthName "Bacula"
                AuthType Basic
                require valid-user
        </Directory>
        ErrorLog /var/log/httpd/bacula-web-error.log
        LogLevel warn
        CustomLog /var/log/httpd/bacula-web-access.log combined
</VirtualHost>

EOF

mkdir /etc/httpd/access/
htpasswd -cdb /etc/httpd/access/bacula-htpasswd bacula sci134*
/etc/init.d/httpd start

cd ${BACULA_PKG}
wget -c http://www.douglas.wiki.br/Downloads/misc/bacula-win64-5.2.10.exe
wget -c http://www.douglas.wiki.br/Downloads/misc/bacula-win32-5.2.10.exe
