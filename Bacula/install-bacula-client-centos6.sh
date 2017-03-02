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
YUM="/usr/bin/yum"
SED="/bin/sed"
BACULA_SERVER="172.17.0.90"

if [ -z ${CLIENT} ]; then
	echo "Nao foi definido um client"; exit 1
fi

${YUM} check-update || { echo "${RED}FALHA AO ATUALIZAR O YUM ${CLOSE}"; exit 1; }
${YUM} install readline-devel readline-static readline zlib zlib-devel zlib-static libmcrypto-devel openssl-devel -y || { echo "${RED}FALHA AO INSTALAR DEPENDENCIAS ${CLOSE}"; exit 1; }

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

chown -R bacula:bacula  ${BACULA_BASE}
mkdir /usr/src/olds
cp -Rfa /etc/bacula /usr/src/olds

rm -rf /etc/init.d/bacula-sd
rm -rf /etc/init.d/bacula-dir

chkconfig --add bacula-fd
chkconfig bacula-fd on

rsync -avzPH root@${BACULA_SERVER}:/etc/bacula/keys/clients/${CLIENT}/${CLIENT}.tar.xz ${BACULA_BASE}/
cd ${BACULA_BASE}
tar -xJvf ${CLIENT}.tar.xz
rm -rf ${CLIENT}.tar.xz
rm -rf ${BACULA_BASE}/keys/${CLIENT}-fd.cert
rm -rf ${BACULA_BASE}/keys/${CLIENT}-fd.key
/etc/init.d/bacula-fd restart
rm -rf /usr/src/bacula-7.0.5*
