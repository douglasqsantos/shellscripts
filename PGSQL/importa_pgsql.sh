#!/bin/bash
#
#Reset pgsql password
#su - postgres
#psql
#postgres=# ALTER USER postgres WITH PASSWORD 'senha';
##############################################################
clear
############VALIDANDO O USUARIO QUE EXECUTANDO O SCRIPT##############################
USU=$(whoami)

if [ "${USU}" != root ]; then
  echo -e
  echo -e "=============================================================================="
  echo -e " ESTE PROGRAMA PRECISA SER EXECUTADO COM PERMISSOES DE SUPERUSUARIO!"
  echo -e " Abortando..."
  echo -e "=============================================================================="
  echo -e
  exit 1
fi

GREY="\033[01;30m"
RED="\033[01;31m"
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
BLUE="\033[01;34m"
PURPLE="\033[01;35m"
CYAN="\033[01;36m"
WHITE="\033[01;37m"
CLOSE="\033[m"

echo -e  "${RED}####################################################################${CLOSE}"
echo -e "${RED}# Este script estara trabalhando com o seguinte processo ${GREEN} $$ ${CLOSE}   ${CLOSE}"
echo -e  "${RED}####################################################################${CLOSE}"

sleep 3

### COMANDOS USADOS NO SCRIPT ###
PSQL=$(which psql)
MKDIR=$(which mkdir)
FIND=$(which find)
RM=$(which rm)

### USUARIO PARA CONEXTAR NO BANCO
USUARIO="postgres"

### SENHAS DO USUARIO POSTGRES DO BANCO ###
export PGPASSWORD="5hEU246WDRVkUYw"

### IP DO SERVIDOR DE BANCO DE DADOS ###
SRV_BANCO="127.0.0.1"

### DIRETORIOS USADOS NO SCRIPT ###
BACKUP="/srv/dump_pgsql/bancos/dados/all.sql"
LOGS_DADOS="/srv/dump_pgsql/logs/dados"

if [ ! -d ${LOGS_DADOS} ]; then
	${MKDIR} -p ${LOGS_DADOS} 2> /dev/null
fi

### IMPORTANDO O BANCO DE DADOS
${PSQL} -h ${SRV_BANCO} -U ${USUARIO} -f ${BACKUP} > ${LOGS_DADOS}/importacao.log

### REMOVENDO OS LOGS VAZIOS ###
echo -e "${GREEN} REMOVENDO ARQUIVOS DE LOGS VAZIOS ${CLOSE}"
sleep 2

${FIND} ${LOGS_DADOS} -empty -exec ${RM} -rf {} \;

echo -e "${GREEN} FINALIZADA A IMPORTACAO ${CLOSE}"

