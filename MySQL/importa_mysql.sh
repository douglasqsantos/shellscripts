#!/bin/sh
#
# importa_mysql
#
# Script para realizar da importação dos dados exportados com o 
# exporta_mysql pois a importação é feita base a base da estrutura e depois dos dados
#
# Autor : Douglas Q. dos Santos <douglas@douglas.wiki.br>
# Manutenção: Douglas Q. dos Santos <douglas@douglas.wiki.br>
#
#
#----------------------------------------------------------------------
# 
# Este programa faz a configuração dos repositórios, chaves dos repositórios,
# instala um conjunto básico de aplicativos necessários para a operação de um
# servidor utilizando o sitema Debian GNU/Linux 
#
# Exeplos: 
#       $ ./importa_mysql
# Após executar o script vai a importação de toda a estrutura que foi exportada 
# com o export_mysql
# nos temos a seguinte situação for END in $(cat ${BASES} | grep bancodedados)
# nessa situação efetuariamos a importação de somente um determinado banco de dados
# caso contrário temos a seguinte situação: for END in $(cat ${BASES})
# nessa situação vamos importar todos os bancos de dados.
# a primeira situação esta comentada por padrão.
#---------------------------------------------------------------------
#
#
# Histórico:
# v1.0 2011-04-14, Douglas Q. dos Santos:
#       - Versão inicial
#-------------------------------------------------------------------------
clear
############VALIDANDO O USUARIO QUE EXECUTANDO O SCRIPT##############################
USU=$(whoami)

if [ "${USU}" != root ]; then
  echo
  echo "=============================================================================="
  echo " ESTE PROGRAMA PRECISA SER EXECUTADO COM PERMISSOES DE SUPERUSUARIO!"
  echo " Abortando..."
  echo "=============================================================================="
  echo
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

echo  "${RED}####################################################################${CLOSE}"
echo "${RED}# Este script estara trabalhando com o seguinte processo ${GREEN} $$ ${CLOSE}   ${CLOSE}"
echo  "${RED}####################################################################${CLOSE}"

sleep 3

### COMANDOS USADOS NO SCRIPT ###
MYSQLDUMP=$(which mysqldump)
MYSQL=$(which mysql)
MKDIR=$(which mkdir)
FIND=$(which find)
RM=$(which rm)

### ARQUIVOS UTILIZADOS NO SCRIPT ###
BASES="/srv/dump/bases"
PERMISSOES="/srv/dump/permissoes.sql"

### SENHAS DO USUARIO ROOT DO BANCO ###
SENHA="senha"

### DIRETORIOS USADOS NO SCRIPT ###
BANCOS="/srv/dump/bancos"
VALIDAR="/srv/dump/validar"
ESTRUTURA_BANCOS="/srv/dump/bancos/estrutura"
DADOS_BANCOS="/srv/dump/bancos/dados"
VALIDAR_ESTRUTURA="/srv/dump/validar/estrutura"
VALIDAR_DADOS="/srv/dump/validar/dados"

### VALIDA SE EXISTE DIRETORIO PARA ARMAZENAR OS LOGS ###
if [ ! -d ${VALIDAR} ]; then
	${MKDIR} -p ${VALIDAR} 2> /dev/null
fi

if [ ! -d ${VALIDAR_ESTRUTURA} ]; then
	${MKDIR} -p ${VALIDAR_ESTRUTURA} 2> /dev/null
fi

if [ ! -d ${VALIDAR_DADOS} ]; then
	${MKDIR} -p ${VALIDAR_DADOS} 2> /dev/null
fi


### IMPORTA USUARIOS E PERMISSOES ###
#echo "${GREEN} IMPORTA USUARIOS E PERMISSOES${CLOSE}"
#${MYSQL} -u root -p${SENHA} -B mysql < ${PERMISSOES} 2> ${VALIDAR}/permissoes_error_import

### IMPORTANDO AS TABELAS RELACIONADAS NO ARQUIVO ${BASES} ###
#for END in $(cat ${BASES} | grep bancodedados)
for END in $(cat ${BASES})
do
### IMPORTANDO A ESTRUTURA ###
echo "${GREEN} IMPORTANDO A ESTRUTURA DO BANCO${RED} ${END} ${CLOSE} ${CLOSE}"
sleep 2
${MYSQL} -u root -p${SENHA} <  ${ESTRUTURA_BANCOS}/${END}_estrutura.sql 2> ${VALIDAR_ESTRUTURA}/${END}_estrutura_error_import

### IMPORTANDO OS DADOS ###
echo "${GREEN} IMPORTANDO OS DADOS DO BANCO${RED} ${END} ${CLOSE} ${CLOSE}"
sleep 2
${MYSQL} -u root -p${SENHA}  < ${DADOS_BANCOS}/${END}_dados.sql 2> ${VALIDAR_DADOS}/${END}_dados_error_import

### IMPORTANDO TODAS AS BASES ###echo "${GREEN} DUMP DA ESTRUTURA DO BANCO ${RED} ${END} ${CLOSE} ${CLOSE}"
#echo "${GREEN} IMPORTANDO BACKUP FULL DE TODOS OS BANCOS ${CLOSE}"
#sleep 2
#${MYSQ} -u root -p${SENHA} -R -c -t -e -v  > ${DADOS_BANCOS}/${END}_all.sql 2> ${VALIDAR_DADOS}/${END}.error
done

### REMOVENDO OS LOGS VAZIOS ###
echo "${GREEN} REMOVENDO ARQUIVOS DE LOGS VAZIOS ${CLOSE}"
sleep 2
${FIND} ${VALIDAR_ESTRUTURA} -empty -exec ${RM} -rf {} \;
${FIND} ${VALIDAR_DADOS} -empty -exec ${RM} -rf {} \;