#!/bin/bash

BACULA_BASE="/etc/bacula"
BACULA_WD="/var/lib/bacula"
BACULA_PID="/var/run/bacula"
BACULA_LOG="/var/log/bacula"
BACULA_ST="/srv/backup"
BBCLIENTS="${BACULA_BASE}/keys/clients"
CAT="/bin/cat"
CD="cd"
RM="/bin/rm"
OPENSSL="/usr/bin/openssl"
CLIENT=""
DOMAIN="gpb.local"
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
APTITUDE="/usr/bin/aptitude"
SED="/bin/sed"
BACULA_SERVER="172.17.0.90"

if [ -z ${CLIENT} ]; then
	echo "Nao foi definido um client"; exit 1
fi

${APTITUDE} update || { echo "${RED}FALHA AO ATUALIZAR O APTITUDE ${CLOSE}"; exit 1; }
${APTITUDE} install libreadline-dev libreadline6-dev libreadline6-dev libreadline6 libreadline6 libreadline6-dev zlib1g-dev libcurl4-openssl-dev build-essential acl-dev libacl1-dev liblzo2-2 liblzo2-dev -y || { echo "${RED}FALHA AO INSTALAR DEPENDENCIAS ${CLOSE}"; exit 1; }

mkdir ${BACULA_WD}
mkdir ${BACULA_PID}
mkdir ${BACULA_LOG}
mkdir -p ${BACULA_BASE}/scripts

useradd -s /bin/false -d ${BACULA_WD}  bacula
chown -R bacula:bacula ${BACULA_WD} ${BACULA_PID} ${BACULA_LOG} ${BACULA_BASE}

cd /usr/src
wget -c  http://scitech-wiki.gpb.local/Downloads/bacula-7.0.5.tar.gz || { echo "${RED}FALHA AO OBTER O BACULA ${CLOSE}"; exit 1; }

tar -xzvf bacula-7.0.5.tar.gz
cd bacula-7.0.5

FLAGS="-g -Wall" ./configure --enable-client-only --with-openssl=yes --enable-smartalloc --with-working-dir=/var/lib/bacula --with-pid-dir=/var/run/bacula --with-logdir=/var/log/bacula  --with-scriptdir=/etc/bacula/scripts --with-readline=/usr/include/readline  --disable-conio --enable-lockmgr

make && make install && make install-autostart

mkdir /usr/src/olds
cp -Rfa /etc/bacula /usr/src/olds

insserv -r -f bacula-sd
insserv -r -f bacula-dir
rm -rf /etc/init.d/bacula-sd
rm -rf /etc/init.d/bacula-dir


${CAT} << EOF > bacula-fd.patch
--- bacula-fd   2014-08-19 09:48:44.886820180 -0300
+++ /etc/init.d/bacula-fd       2014-08-19 09:51:04.820824428 -0300
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


patch -p1 /etc/init.d/bacula-fd  -i bacula-fd.patch

rm -rf bacula-fd.patch

rsync -avzPH root@${BACULA_SERVER}:/etc/bacula/keys/clients/${CLIENT}/${CLIENT}.tar.xz ${BACULA_BASE}/
cd ${BACULA_BASE}
tar -xJvf ${CLIENT}.tar.xz
rm -rf ${CLIENT}.tar.xz
rm -rf ${BACULA_BASE}/keys/${CLIENT}-fd.cert
rm -rf ${BACULA_BASE}/keys/${CLIENT}-fd.key

chown -R bacula:bacula  ${BACULA_BASE}

/etc/init.d/bacula-fd restart
rm -rf /usr/src/bacula-7.0.5*
