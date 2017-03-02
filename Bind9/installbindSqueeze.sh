#!/bin/sh
#=============================================================================#
# NOTA DE LICENCA                                                             #
#                                                                             #
# Este trabalho esta licenciado sob uma Licenca Creative Commons Atribuicao-  #
# Compartilhamento pela mesma Licenca 3.0 Brasil. Para ver uma copia desta    #
# licenca, visite http://creativecommons.org/licenses/by/3.0/br/              #
# ou envie uma carta para Creative Commons, 171 Second Street, Suite 300,     #
# San Francisco, California 94105, USA.                                       #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Desenvolvido em 28/02/2011 por:                                             #
#       Douglas Quintiliano dos Santos  | douglashx@gmail.com                 #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Criado por:  						                      #
#       Douglas Quintiliano dos Santos em 28/02/2011                          #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Funcao: Script para realizar instalção de servidor dns em Debian Squeeze    #
#                                                                             #
#=============================================================================#
clear
######################CORES USADAS NO SCRIPT
GREY="\033[01;30m"
RED="\033[01;31m"
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
BLUE="\033[01;34m"
PURPLE="\033[01;35m"
CYAN="\033[01;36m"
WHITE="\033[01;37m"
CLOSE="\033[m"

############VALIDANDO O USUARIO QUE EXECUTANDO O SCRIPT##############################
USU=$(whoami)
if [ "${USU}" != root ]; then
  echo
  echo "${RED}=============================================================================="
  echo " ESTE PROGRAMA PRECISA SER EXECUTADO COM PERMISSOES DE SUPERUSUARIO!"
  echo " Abortando..."
  echo "====================================================================================${CLOSE}"
  echo
  exit 1
fi

#COMANDOS UTILIZADO NO SCRIPT
APTITUDE=$(which aptitude)
PACOTES="bind9 dnsutils"
MKDIR=$(which mkdir)
MKNOD=$(which mknod)
CHMOD=$(which chmod)
CHOWN=$(which chown)
MV=$(which mv)
LN=$(which ln)
CAT=$(which cat)
TOUCH=$(which touch)
CP=$(which cp)

#INSTALANDO OS PACOTES NECESSARIOS
${APTITUDE} install ${PACOTES} -y

#PARANDO O SERVIÇO DO BIND PARA EFETUARMOS OS AJUSTES
/etc/init.d/bind9 stop

#PEDINDO PARA O USUARIO A JAULA DO BIND CASO NAO SEJA INFORMADO USAREI ${JAULA}
echo "${GREEN}INFORME O CAMINHO DA JAULA DO BIND${CLOSE}"
read JAULA
	if [ -z ${JAULA} ];
	then
	echo "${RED} VAI SER USADO /var/lib/named como jaula ${CLOSE}"
	JAULA="/var/lib/named"
	fi

#CRIANDO A BASE PARA O BIND TRABALHAR ENJAULADO
${MKDIR} -p ${JAULA}/etc
${MKDIR} -p ${JAULA}/dev
${MKDIR} -p ${JAULA}/var/log
${MKDIR} -p ${JAULA}/var/cache/bind
${MKDIR} -p ${JAULA}/var/run/bind/run
${MKNOD} ${JAULA}/dev/null c 1 3
${MKNOD} ${JAULA}/dev/random c 1 8

#AJUSTANDO AS PERMISSOES DOS DIRETORIOS
${CHMOD} 666 ${JAULA}/dev/random
${CHMOD} 666 ${JAULA}/dev/null
${CHOWN} -R bind:bind ${JAULA}/var/*

#MOVENDO AS CONFIGURAÇÕES DO BIND PARA A JAULA E CRIAR UM LINK PARA O SISTEMA
${MV} /etc/bind ${JAULA}/etc
${LN} -sf ${JAULA}/etc/bind /etc/bind
${CHOWN} -R bind:bind ${JAULA}/etc/bind

${CAT} << EOF > /etc/default/bind9
RESOLVCONF=yes
OPTIONS="-u bind -t ${JAULA}"
EOF

#CRIANDO O ARQUIVO managed-keys-zone 
${TOUCH} ${JAULA}/var/cache/bind/managed-keys.bind

#ALGUMAS VARIAVEIS PARA CONFIGURAR O NOSSO BIND
echo "${GREEN} INFORME O DOMINIO ${CLOSE}"
read DOMINIO

#CONFIRANDO O RESOLV.CONF
${CAT} << EOF > /etc/resolv.conf
domain ${DOMINIO}
nameserver 127.0.0.1
EOF

echo "${GREEN}INFORME A REDE QUE VAI TER ACESSO A CONSULTAR ESSE DNS EX: 10.0.0.0/24 ${CLOSE}"
read REDE
	while [ -z ${REDE} ];
	do
	echo "${RED}INFORME A REDE QUE VAI TER ACESSO A CONSULTAR ESSE DNS EX: 10.0.0.0/24 ${CLOSE}"
	read REDE
	done


#AJUSTANDO O ARQUIVO ${JAULA}/etc/bind/named.conf.options
${CP} -Ra ${JAULA}/etc/bind/named.conf.options ${JAULA}/etc/bind/named.conf.options.bkp
${CAT} << EOF > ${JAULA}/etc/bind/named.conf.options
options {
	directory "/var/cache/bind";
 
	// If there is a firewall between you and nameservers you want                  
	// to talk to, you might need to uncomment the query-source
	// directive below.  Previous versions of BIND always asked
	// questions using port 53, but BIND 8.1 and later use an unprivileged
	// port by default.
 
	// query-source address * port 53;
 
	// If your ISP provided one or more IP addresses for stable
	// nameservers, you probably want to use them as forwarders.
	// Uncomment the following block, and insert the addresses replacing
	// the all-0's placeholder.
 
	// forwarders {
	//      0.0.0.0;
	// };
 
	auth-nxdomain no;    # conform to RFC1035
	listen-on-v6 { any; };
 
	listen-on { 127.0.0.1/32; ${REDE}; };
	allow-query { any; };
	allow-recursion { 127.0.0.1/32; ${REDE}; };
	allow-transfer { none; };
	version "Nao Disponivel";
};
EOF

#CONFIGURANDO AS ZONAS DO DNS

IP=$(ifconfig eth0 | grep "inet" | cut -d : -f2 | sed -n '1p' | sed "s/Bcast//g" | sed "s/ //g")
if [ -z ${IP} ];
then
IP=$(ifconfig eth1 | grep "inet" | cut -d : -f2 | sed -n '1p' | sed "s/Bcast//g" | sed "s/ //g")
fi
	
echo "${GREEN}INFORME O IP DO SERVIDOR DNS CASO SEJA O LOCAL SO PRESSIONE ENTER${CLOSE}"
read IP_NS1
	if [ -z ${IP_NS1} ];
	then
	echo "${RED} VAI SER USADO ${IP} ${CLOSE}"
	IP_NS1=${IP}
	fi

#ESTRAINDO O REVERSO DO NS1
REV3=$(echo ${IP_NS1} | cut -d '.' -f 3)
REV2=$(echo ${IP_NS1} | cut -d '.' -f 2)
REV1=$(echo ${IP_NS1} | cut -d '.' -f 1)
IP_REVERSO=${REV3}.${REV2}.${REV1}

echo "${GREEN}INFORME O IP DO SERVIDOR DNS2 CASO SEJA O LOCAL SO PRESSIONE ENTER${CLOSE}"
read IP_NS2
	if [ -z ${IP_NS2} ];
	then
	echo "${RED} VAI SER USADO ${IP} ${CLOSE}"
	IP_NS2=${IP}
	fi

echo "${GREEN}INFORME O IP DO SERVIDOR WEB CASO SEJA O LOCAL SO PRESSIONE ENTER${CLOSE}"
read IP_WEB
	if [ -z ${IP_WEB} ];
	then
	echo "${RED} VAI SER USADO ${IP} ${CLOSE}"
	IP_WEB=${IP}
	fi

echo "${GREEN}INFORME O IP DO SERVIDOR DE EMAIL CASO SEJA O LOCAL SO PRESSIONE ENTER${CLOSE}"
read IP_EMAIL
	if [ -z ${IP_EMAIL} ];
	then
	echo "${RED} VAI SER USADO ${IP} ${CLOSE}"
	IP_EMAIL=${IP}
	fi

#ARQUIVO DE ZONAS PADROES DO DNS
${CP} -Ra ${JAULA}/etc/bind/named.conf.default-zones ${JAULA}/etc/bind/named.conf.default-zones.bkp
${CAT} << EOF > ${JAULA}/etc/bind/named.conf.default-zones
//Configuração dos Logs
logging {
        channel "named_log" {
        file "/var/log/bind";
        print-time yes;
        severity info;
        };

        category "security"{
        "named_log";
        };

        category "xfer-out"{
        "named_log";
        };

        category "xfer-in"{
        "named_log";
        };

        category "general"{
        "named_log";
        };
};

// prime the server with knowledge of the root servers
zone "." {
	type hint;
	file "/etc/bind/db.root";
};

// be authoritative for the localhost forward and reverse zones, and for
// broadcast zones as per RFC 1912

zone "localhost" {
	type master;
	file "/etc/bind/db.local";
};

zone "127.in-addr.arpa" {
	type master;
	file "/etc/bind/db.127";
};

zone "0.in-addr.arpa" {
	type master;
	file "/etc/bind/db.0";
};

zone "255.in-addr.arpa" {
	type master;
	file "/etc/bind/db.255";
};

zone "${DOMINIO}" {
	type master;
	file "db.${DOMINIO}";
	allow-transfer { ${IP_NS2}; };
};
 
zone "${IP_REVERSO}.in-addr.arpa" {
	type master;
	file "db.${IP_REVERSO}";
	allow-transfer { ${IP_NS2}; };
};

EOF
##CRIANDO OS ARQUIVOS DAS ZONAS
${CAT} << EOF > ${JAULA}/var/cache/bind/db.${DOMINIO}
`echo '$TTL 86400'`
@ IN SOA  dns.${DOMINIO}. root.dns.${DOMINIO}. (
                        `date +%Y%m%d`01  ; Serial
                        3600       ; Refresh
                        1800        ; Retry
                        1209600      ; Expire
                        3600 )     ; Minimum
 
; 
@		IN 	NS   ${DOMINIO}.
${DOMINIO}. IN TXT "v=spf1 a mx ip4:${REDE} -all"
mail.${DOMINIO} IN TXT "v=spf1 a -all"
 
@               IN	NS   ns1.${DOMINIO}.
@               IN 	NS   ns2.${DOMINIO}.
@               IN 	MX   0 mail.${DOMINIO}.
 
;NAME SERVERS
@               IN 	A    ${IP_NS1}
ns1             IN 	A    ${IP_NS1}
ns2             IN 	A    ${IP_NS2}
dns             IN 	A    ${IP_NS1}
 
;MAIL SERVERS
mail            IN 	A    ${IP_EMAIL}
imap            IN 	CNAME mail
pop             IN 	CNAME mail
smtp            IN 	CNAME mail
webmail         IN 	CNAME mail
 
;WEB SERVERS
www             IN 	A    ${IP_WEB}
ftp             IN 	CNAME www
mailadmin       IN 	CNAME www
EOF

#Retirando os endereÃ§os finais para  o arquivo reverso------------------------
REV_NS1=$(echo ${IP_NS1} | cut -d '.' -f 4)
REV_NS2=$(echo ${IP_NS2} | cut -d '.' -f 4)
REV_EMAIL=$(echo ${IP_EMAIL} | cut -d '.' -f 4)
REV_WEB=$(echo ${IP_WEB} | cut -d '.' -f 4)

${CAT} <<EOF > ${JAULA}/var/cache/bind/db.${IP_REVERSO}
`echo '$TTL 86400'`
@ IN SOA  dns.${DOMINIO}. root.dns.${DOMINIO}. (
                        `date +%Y%m%d`01  ; Serial
                        3600       ; Refresh
                        1800        ; Retry
                        604800      ; Expire
                        3600 )     ; Minimum
 
; 
@		IN 	NS   ${DOMINIO}.
@               IN	NS   ns1.${DOMINIO}.
@               IN 	NS   ns2.${DOMINIO}.
@               IN 	MX   0 mail.${DOMINIO}.
 
;NAME SERVERS
${REV_NS1}      IN 	PTR    ${DOMINIO}.
${REV_NS1}      IN 	PTR    ns1.${DOMINIO}.
${REV_NS2}      IN 	PTR    ns2.${DOMINIO}.
${REV_NS1}      IN 	PTR    dns.${DOMINIO}.
 
;MAIL SERVERS
${REV_EMAIL}    IN 	PTR    mail.${DOMINIO}.
 
;WEB SERVERS
${REV_WEB}      IN 	PTR    www.${DOMINIO}.
EOF

#INICIANDO O SERVIÇO NOVAMENTE
/etc/init.d/bind9 start
