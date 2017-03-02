#!/bin/bash
#=============================================================================#
# NOTA DE LICENCA                                                             #
#                                                                             #
# Este trabalho esta licenciado sob uma Licenca Creative Commons Atribuicao-  #
# Compartilhamento pela mesma Licenca 3.0 Brasil. Para ver uma copia desta    #
# licenca, visite http://creativecommons.org/licenses/by/3.0/br/              #
# ou envie uma carta para Creative Commons, 171 Second Street, Suite 300,     #
# San Francisco, California 94105, USA.                                       #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Criado por :				                                      #
#    Douglas Quintiliano dos Santos | douglas.q.santos@gmail.com 24/09/2014   #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
#                                                                             #
# Funcao: Script para realizar configuração de servidores DNS MASTER          #
# No Debian Wheezy                                                            #
#                                                                             #
# Informações Adicionais: Os arquivos de zonas vão ficar localizados em       #
# /var/lib/named/var/cache/bind/master se a base for /var/lib/named           #
#=============================================================================#
LOCAL_IP=$(hostname -i)
REV_LOCAL=$(echo ${LOCAL_IP} | cut -d '.' -f 4)
BIND_BASE="/var/lib/named"
ETC_BIND="/etc/bind"
CAT="/bin/cat"
CD="cd"
RM="/bin/rm"
DOMINIO="douglas.lan"
LAN="192.168.1.0/24"
GREEN="\033[01;32m" RED="\033[01;31m" YELLOW="\033[01;33m" CLOSE="\033[m"
APTITUDE="/usr/bin/aptitude"
SED="/bin/sed"
MKDIR="/bin/mkdir"
MKNOD="/bin/mknod"
MV="/bin/mv"
LN="/bin/ln"
CP="/bin/cp"
CHOWN="/bin/chown"
CHMOD="/bin/chmod"
REV3=$(echo ${LAN} | cut -d '.' -f 3)
REV2=$(echo ${LAN} | cut -d '.' -f 2)
REV1=$(echo ${LAN} | cut -d '.' -f 1)
IP_REVERSO=${REV3}.${REV2}.${REV1}


echo -e "${GREEN} ATUALIZANDO OS REPOSITORIOD${CLOSE}"
${APTITUDE} update -y || { echo "${RED}FALHA AO ATUALIZAR OS REPOSITORIOS  ${CLOSE}"; exit 1; }

echo -e "${GREEN} INSTALANDO OS PACOTES NECESSARIOS${CLOSE}"
${APTITUDE} install bind9 dnsutils -y || { echo "${RED}FALHA AO INSTALAR DEPENDENCIAS ${CLOSE}"; exit 1; }

echo -e "${GREEN} PARANDO O BIND${CLOSE}"
/etc/init.d/bind9 stop

echo -e "${GREEN} CRIANDO A ARQUVO DE DIRETORIOS NECESSARIA${CLOSE}"
${MKDIR} -p ${BIND_BASE}${ETC_BIND}/zones/{disabled,external,internal}
${MKDIR} -p ${BIND_BASE}/dev
${MKDIR} -p ${BIND_BASE}/var/log
${MKDIR} -p ${BIND_BASE}/var/cache/bind/{disabled,dynamic,master,slave}
${MKDIR} -p ${BIND_BASE}/var/run/bind/run
${MKNOD} ${BIND_BASE}/dev/null c 1 3
${MKNOD} ${BIND_BASE}/dev/random c 1 8
${MKNOD} ${BIND_BASE}/dev/zero c 1 5

echo -e "${GREEN} AJUSTANDO AS PERMISSOES${CLOSE}"
chmod 666 ${BIND_BASE}/dev/{null,random,zero}
chown -R bind:bind ${BIND_BASE}/var/*

if [ -L ${ETC_BIND} ]; then
echo "${RED} JA EXISTE UMA ESTRUTURA CRIADA ${CLOSE}"
exit 1;
fi


echo -e "${GREEN} AJUSTANDO A LOCALIZACAO DOS ARQUIVOS E PERMISSOES ${CLOSE}"
${MV} ${ETC_BIND}/* ${BIND_BASE}${ETC_BIND}/
${RM} -rf ${ETC_BIND}
${LN} -sf ${BIND_BASE}${ETC_BIND} ${ETC_BIND}
${CP} /etc/localtime ${BIND_BASE}/etc
${CHOWN} -R bind:bind ${BIND_BASE}${ETC_BIND}
${CHOWN} -R root:bind ${BIND_BASE}/var/cache/bind/dynamic
${CHMOD} -R 775 ${BIND_BASE}/var/cache/bind/dynamic


echo -e "${GREEN} AJUSTANDO A LOCALIZACAO DA JAULA DO BINDS ${CLOSE}"
${CP} -Rfa /etc/default/bind9{,.bkp}
${CAT} << EOF > /etc/default/bind9
RESOLVCONF=yes
OPTIONS="-u bind -t ${BIND_BASE}"
EOF


echo -e "${GREEN} AJUSTANDO O RESOLV.CONF ${CLOSE}"
${CP} /etc/resolv.conf{,.bkp}
${CAT} << EOF > /etc/resolv.conf
search ${DOMINIO}
nameserver 127.0.0.1
EOF


echo -e "${GREEN} AJUSTANDO AS OPCOES DO BIND ${CLOSE}"
${CP} -Rfa ${ETC_BIND}/named.conf.options{,.bkp}
${CAT} << EOF > ${ETC_BIND}/named.conf.options
#${ETC_BIND}/named.conf.options
acl "internal_hosts" {
   127.0.0.1/32;
   ${LAN};
};

options {
 directory "/var/cache/bind";
 managed-keys-directory "/var/cache/bind/dynamic";
 auth-nxdomain no;
 listen-on-v6 { any; };
 listen-on { 127.0.0.1/32; ${LAN}; };
 forwarders { 8.8.8.8; 8.8.4.4; };
 allow-query { any; };
 recursion no;
 version "Nao Disponivel";
 dnssec-enable no;
 dnssec-validation no;
 dnssec-lookaside auto;
 empty-zones-enable yes;
};

include "${ETC_BIND}/rndc.key";
controls {
        inet 127.0.0.1 port 953 allow { 127.0.0.1; } keys { rndc-key; };
};

#LOGS
logging {
 channel xfer-log {
 file "/var/log/named.log";
 print-category yes;
 print-severity yes;
 print-time yes;
 severity info;
 };
 category xfer-in { xfer-log; };
 category xfer-out { xfer-log; };
 category notify { xfer-log; };

 channel update-debug {
 file "/var/log/named-update-debug.log";
 severity  debug 3;
 print-category yes;
 print-severity yes;
 print-time      yes;
 };
 channel security-info    {
 file "/var/log/named-auth-info.log";
 severity  info;
 print-category yes;
 print-severity yes;
 print-time      yes;
 };
 category update { update-debug; };
 category security { security-info; };
};

include "${ETC_BIND}/bind.keys";
EOF


echo -e "${GREEN} AJUSTANDO AS REFERENCIAS DO BIND ${CLOSE}"
${CP} -Rfa ${ETC_BIND}/named.conf{,.bkp}
${CAT} << EOF > ${ETC_BIND}/named.conf
include "${ETC_BIND}/named.conf.options";
include "${ETC_BIND}/named.conf.local";
include "${ETC_BIND}/named.conf.internal-zones";
EOF


echo -e "${GREEN} O CONTROLE DAS ZONAS DO BIND ${CLOSE}"
${CAT} << EOF > ${ETC_BIND}/named.conf.internal-zones
#${ETC_BIND}/named.conf.internal-zones

view "internal" {

#DEFININDO QUAIS CLIENTES VÃO PODER CONSULTAR ESSA VIEW
match-clients {
  internal_hosts;
};

#O NOSSOS CLIENTES DA VIEW INTERNA VÃO PODER EFETUAR CONSULTAS RECURSIVAS
recursion yes;

#PARA QUAL SERVIDOR VAI SER LIBERADO A TRANSFERENCIA DESSA VIEW.
allow-transfer {
   none;
};

#QUEM O BIND VAI NOTIFICAR EM CASO DE ALTERAÇÕES DE ZONA.
allow-notify {
   none;
};

#ARQUIVOS CONTENDO AS ZONAS MASTER E SLAVE INTERNAS
include "${ETC_BIND}/zones/internal/named.conf.internal.master-zones";

};
EOF


echo -e "${GREEN} AJUSTANDO AS ZONAS DO BIND ${CLOSE}"
${CAT} << EOF > ${ETC_BIND}/zones/internal/named.conf.internal.master-zones
#/etc/bind/zones/internal/named.conf.internal.master-zones
zone "." {
	 type hint;
	 file "/etc/bind/db.root";
};

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
	 file "master/db.${DOMINIO}-internal";
};

zone "${IP_REVERSO}.in-addr.arpa" {
	type master;
	file "master/db.${IP_REVERSO}-internal";
};
EOF


echo -e "${GREEN} CRIANDO OS REGISTROS DAS ZONAS ${CLOSE}"
${CAT} << EOF > ${BIND_BASE}/var/cache/bind/master/db.${DOMINIO}-internal
`echo '$TTL 86400'`
@ IN SOA  dns.${DOMINIO}. root.dns.${DOMINIO}. (
                        `date +%Y%m%d`01  ; Serial
                        3600       ; Refresh
                        1800        ; Retry
                        1209600      ; Expire
                        3600 )     ; Minimum

;DNS
@               IN      NS   ${DOMINIO}.
@               IN      NS   ns1.${DOMINIO}.
@               IN      NS   ns2.${DOMINIO}.
@               IN      MX   0 mail.${DOMINIO}.

;NAME SERVERS
@               IN      A    ${LOCAL_IP}
ns1             IN      A    ${LOCAL_IP}
ns2             IN      A    ${LOCAL_IP}
dns             IN      A    ${LOCAL_IP}

;MAIL SERVERS
mail            IN      A    ${LOCAL_IP}
imap            IN      CNAME mail
pop             IN      CNAME mail
smtp            IN      CNAME mail
webmail         IN      CNAME mail

;WEB SERVERS
www             IN      A    ${LOCAL_IP}
ftp             IN      CNAME www
EOF


echo -e "${GREEN} CRIANDO OS REGISTROS DAS ZONAS REVERSA ${CLOSE}"
${CAT} << EOF > ${BIND_BASE}/var/cache/bind/master/db.${IP_REVERSO}-internal
`echo '$TTL 86400'`
@ IN SOA  dns.${DOMINIO}. root.dns.${DOMINIO}. (
                        `date +%Y%m%d`01  ; Serial
                        3600       ; Refresh
                        1800        ; Retry
                        604800      ; Expire
                        3600 )     ; Minimum

;
@               IN      NS   ${DOMINIO}.
@               IN      NS   ns1.${DOMINIO}.
@               IN      NS   ns2.${DOMINIO}.
@               IN      MX   0 mail.${DOMINIO}.

;NAME SERVERS
${REV_LOCAL}      IN      PTR    ${DOMINIO}.
${REV_LOCAL}      IN      PTR    ns1.${DOMINIO}.
${REV_LOCAL}      IN      PTR    ns2.${DOMINIO}.
${REV_LOCAL}      IN      PTR    dns.${DOMINIO}.

;MAIL SERVERS
${REV_LOCAL}    IN      PTR    mail.${DOMINIO}.

;WEB SERVERS
${REV_LOCAL}      IN      PTR    www.${DOMINIO}.
EOF


echo -e "${GREEN} INICIANDO O BIND ${CLOSE}"
/etc/init.d/bind9 start


echo -e "${GREEN} CHAMANDO O SYSLOG ${CLOSE}"
tail -f /var/log/syslog
