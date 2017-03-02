#!/bin/sh
#
# exporta_mysql
#
# Script para realizar a exportação de bases de dados MySQL
# A exportação é feita base a base da estrutura e depois dos dados
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
#       $ ./exporta_mysql
# Após executar o script vai fazer uma seleção das bases de dados do Servidor
# vai armazenar em um arquivo e vai efetuar o backup das estruturas e depois
# vai efetuar o backup dos dados dos bancos e esses dados vão ser armazenados 
# em uma estrutura com o sql das estruturas e o logs e um com o sql dos dados
# e os logs, após o processo finalizado é verificado quais logs estão vazios 
# e são excluídos com isso garantimos que temos somente os logs com algum possível
# erro.
# nos temos a seguinte situação for END in $(cat ${BASES} | grep bancodedados)
# nessa situação efetuariamos a exportação de somente um determinado banco de dados
# caso contrário temos a seguinte situação: for END in $(cat ${BASES})
# nessa situação vamos exportar todos os bancos de dados.
# a primeira situação esta comentada por padrão.
#
#---------------------------------------------------------------------
#
#
# Histórico:
# v1.0 2011-04-14, Douglas Q. dos Santos:
#       - Versão inicial
#---------------------------------------------------------------------
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
MYSQL=$(which mysql)
MYSQLDUMP=$(which mysqldump)
MKDIR=$(which mkdir)
GREP=$(which grep)
FIND=$(which find)
RM=$(which rm)

### ARQUIVOS UTILIZADOS NO SCRIPT ###
BASES="/srv/dump/bases"
PERMISSOES="/srv/dump/permissoes.sql"

### SENHAS DO USUARIO ROOT DO BANCO ###
SENHA="senha"

### SERVIDOR DE BANCO DE DADOS ###
SRV_BANCO="10.0.0.255"

### DIRETORIOS USADOS NO SCRIPT ###
ESTRUTURA_BANCOS="/srv/dump/bancos/estrutura"
DADOS_BANCOS="/srv/dump/bancos/dados"
LOGS_ESTRUTURA="/srv/dump/logs/estrutura"
LOGS_DADOS="/srv/dump/logs/dados"

### VALIDA OS DIRETORIO NECESSARIOS ###
if [ ! -d ${ESTRUTURA_BANCOS} ];then
	${MKDIR} -p ${ESTRUTURA_BANCOS} 2> /dev/null
fi

if [ ! -d ${LOGS_ESTRUTURA} ];then
	${MKDIR} -p ${LOGS_ESTRUTURA} 2> /dev/null
fi

if [ ! -d ${DADOS_BANCOS} ];then
	${MKDIR} -p ${DADOS_BANCOS} 2> /dev/null
fi

if [ ! -d ${LOGS_DADOS} ];then
	${MKDIR} -p ${LOGS_DADOS} 2> /dev/null
fi

### FAZ A RELACAO DAS TABELAS DO BANCO E ARMAZENA NO ARQUIVO ${BASES} ###
echo "${GREEN} FAZENDO RELACÃO DAS TABELAS DO BANCO DE DADOS${CLOSE}"
sleep 3
${MYSQL} -u root -p${SENHA} -h ${SRV_BANCO} -e "SELECT schema_name from information_schema.schemata" --column-names=FALSE | ${GREP} -v information_schema > ${BASES}

### FAZ DUMP DOS USUARIOS E SUAS SENHAS E FAZ DUMP DAS PERMISSOES DOS USUARIOS NAS TABELAS
#echo "${GREEN} FAZENDO DUMP DOS USUARIOS,SENHAS E SUAS PEMISSOES NAS TABELAS ${CLOSE}"
#sleep 3
#${MYSQLDUMP} -u root -p${SENHA} -h ${SRV_BANCO} mysql user db > ${PERMISSOES}


### FAZ O DUMP DAS TABELAS RELACIONADAS NO ARQUIVO ${BASES} ###
echo "${GREEN} FAZ DUMP DAS TABELAS RELACIONADAS ANTERIORMENTE${CLOSE}"
#for END in $(cat ${BASES} | grep bancodedados)
for END in $(cat ${BASES})
do
### DUMP DA ESTRUTURA ###
echo "${GREEN} DUMP DA ESTRUTURA DO BANCO ${RED} ${END} ${CLOSE} ${CLOSE}"
sleep 2
${MYSQLDUMP} -u root -p${SENHA} -h ${SRV_BANCO} -B ${END} -R -d -v --add-drop-database=TRUE --trigger=FALSE > ${ESTRUTURA_BANCOS}/${END}_estrutura.sql 2> ${LOGS_ESTRUTURA}/${END}.error

### DUMP DOS DADOS ###
echo "${GREEN} DUMP DOS DADOS DO BANCO ${RED} ${END} ${CLOSE} ${CLOSE}"
sleep 2
${MYSQLDUMP} -u root -p${SENHA} -h ${SRV_BANCO} -B ${END} -R -c -t -e -v -K > ${DADOS_BANCOS}/${END}_dados.sql 2> ${LOGS_DADOS}/${END}.error

### DUMP FULL DE TODOS OS BANCOS ###
#${MYSQLDUMP} -u root -p${SENHA} -B ${END} -R -c -t -e -v --add-drop-database=TRUE  > ${DADOS_BANCOS}/${END}_all.sql 2> ${LOGS_DADOS}/${END}.error
done

### REMOVE OS ARQUIVOS DE LOGS VAZIOS ###
echo "${GREEN} REMOVENDO ARQUIVOS DE LOGS VAZIOS ${CLOSE}"
sleep 2
${FIND} ${LOGS_ESTRUTURA} -empty -exec ${RM} -rf {} \;
${FIND} ${LOGS_DADOS} -empty -exec ${RM} -rf {} \;

echo "${GREEN} EXPORTAÇÃO FINALIZADA, VERIFIQUE OS ARQUIVOS DE LOGS ${CLOSE}"