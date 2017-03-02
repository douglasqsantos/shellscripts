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
# Criado por:                                                                 #
#       Douglas Quintiliano dos Santos | douglashx@gmail.com em 22/02/2011    #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Baseado no script install.sh de:                                            #
#       Fabricio Vaccari Constanski     | fabriciovc@fabriciovc.eti.br        #
#       http://site.fabriovc.eti.br                                           #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
# Manutenção:                                                                 #
#       Anderson Angelote | anderson@angelote.com.br                          #
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #
                                                                              #
# Funcao: Script para realizar padronização do sistema Debian GNU/Linux       #
#                                                                             #
#=============================================================================#
### COMANDOS ###
APTITUDE=$(which aptitude)
CP=$(which cp)
CAT=$(which cat)
NTPDATE=$(which ntpdate)
MKDIR=$(which mkdir)
CHMOD=$(which chmod)
SED=$(which sed)
RM=$(which rm)
CHOWN=$(which chown)

#INFORMAÇÕES
SERVIDOR=$(cat /etc/hostname)
IP=$(ifconfig eth0 | grep "inet" | cut -d : -f2 | sed -n '1p' | sed "s/Bcast//g" | sed "s/ //g")


MENU(){
echo "-----------------------------------------------"
echo "1) Instalacao do samba Autenticando no AD      "
echo "2) Instalacao do squid Autenticando no AD      "
echo "3) Instalacao do sarg                          "
echo "4) Sair                                        "
echo "-----------------------------------------------"
echo "Digite a sua opcao"
read OPT

while [ $OPT -ne 4 ]; 
do
case "$OPT" in
1) INSTALL_SAMBA_AD;;
2) INSTALL_SQUID_AD;;
3) INSTALL_SARG;;
4) exit 0;;
*) echo "Opcao invalida"; MENU ;;
esac
done

}

INSTALL_SAMBA_AD (){

echo "Instalando os pacotes"
export DEBIAN_PRIORITY=critical 
export DEBIAN_FRONTEND=noninteractive

${APTITUDE} update && ${APTITUDE} dist-upgrade -y
${APTITUDE} install -y samba samba-common smbclient winbind bind9 krb5-config libpam-krb5

unset DEBIAN_PRIORITY
unset DEBIAN_FRONTEND

echo "Ajustando o arquivo Resolv.conf"
${CP} -Rfa /etc/resolv.conf{,.bkp}
echo "Informe o endereco ip do servidor AD (10.0.0.248)"
read IP_AD

echo "Informe o dominio (gpb.local)"
read DOMINIO
${CAT} << EOF > /etc/resolv.conf
#ip do servidor 2008
search ${DOMINIO}
nameserver 127.0.0.1
EOF

chattr +i /etc/resolv.conf

${CP} -Rfa /etc/bind/named.conf.default-zones{,.bkp}
${CAT} << EOF >> /etc/bind/named.conf.default-zones
zone "${DOMINIO}" {
        type forward;
        forwarders { ${IP_AD}; };
};

zone "gpb.intranet" {
        type forward;
        forwarders { ${IP_AD}; };
};

EOF

/etc/init.d/bind9 restart
sleep 1

echo "Teste de consulta no dominio informado"
nslookup ${DOMINIO}

if [ $? -eq 0 ]; then
   echo Dominio encontrado
else exit 1
fi

sleep 3
echo "Ajustando  o arquivo de hosts"

${CP} -Rfa /etc/hosts{,.bkp}
${CAT} << EOF > /etc/hosts
#/etc/hosts
127.0.0.1       localhost
#Ip do ad 
${IP_AD}        win2008.${DOMINIO} win2008
${IP_AD}       ${DOMINIO}         ${DOMINIO}
#Ip da maquina local
${IP}          ${SERVIDOR}.${DOMINIO}  ${SERVIDOR}  
10.0.0.108      repo.scitechinfo.com.br

EOF

echo "Atualizando o relogio do sistema"
${NTPDATE} -u ntp.usp.br

echo "Ajustando arquivo krb5"
${CP} -Rfa /etc/krb5.conf{,.bkp}
${CAT} << EOF > /etc/krb5.conf
[libdefaults]
default_realm = ${DOMINIO}
krb4_config = /etc/krb.conf
krb4_realms = /etc/krb.realms
kdc_timesync = 1
ccache_type = 4
forwardable = true
proxiable = true
v4_instance_resolve = false
v4_name_convert = {
host = {
rcmd = host
ftp = ftp
}
plain = {
something = something-else
}
}
fcc-mit-ticketflags = true
[realms]
${DOMINIO} = {
kdc = ${IP_AD}
admin_server = ${IP_AD}:749
default_server = ${IP_AD}
}
[domain_realm]
.${DOMINIO}=${DOMINIO}
${DOMINIO}=${DOMINIO}
[login]
krb4_convert = true
krb4_get_tickets = false
[kdc]
profile = /etc/krb5kdc/kdc.conf
[appdefaults]
pam = {
debug = false
ticket_lifetime = 36000
renew_lifetime = 36000
forwardable = true
krb4_convert = false
}
[logging]
default = file:/var/log/krb5libs.log
kdc = file:/var/log/krb5kdc.log
admin_server = file:/var/log/kadmind.log
EOF

echo Ajustando o arquivo limits.conf
${CP} -Rfa /etc/security/limits.conf{,.bkp}
${CAT} << EOF >> /etc/security/limits.conf
root hard nofile 131072
root soft nofile 65536
mioutente hard nofile 32768
mioutente soft nofile 16384
EOF

echo "Ajustando o arquivo smb.conf"

WKSMB=$(echo ${DOMINIO} | cut -d "." -f -1 | tr "[:lower:]" "[:upper:]")
KRBSMB=$(echo ${DOMINIO} | tr "[:lower:]" "[:upper:]")
${CP} -Rfa /etc/samba/smb.conf{,.bkp}

${CAT} << EOF > /etc/samba/smb.conf
[global]
        workgroup = ${WKSMB}
        realm = ${KRBSMB}
        server string = Squid Proxy Server
        security = ADS
        auth methods = winbind
        password server = ${IP_AD}
        socket options = TCP_NODELAY SO_RCVBUF=8192 SO_SNDBUF=8192
        load printers = No
        printcap name = cups
        disable spoolss = Yes
        local master = No
        domain master = No
        idmap uid = 10000-30000
        idmap gid = 10000-30000
        winbind cache time = 15
        winbind enum users = Yes
        winbind enum groups = Yes
        winbind use default domain = Yes
EOF

echo "Ajustando o previlégio do winbind"
gpasswd -a proxy winbindd_priv 

${SED} -i "36d" /etc/init.d/winbind
${SED} -i "36i\start-stop-daemon --start --quiet --oknodo --exec \$DAEMON -- no-caching #\$WINBINDD_OPTS" /etc/init.d/winbind


echo Ajustando o arquivo nsswitch

${CP} -Rfa /etc/nsswitch.conf{,.bkp}

${CAT} << EOF > /etc/nsswitch.conf
passwd:         compat winbind
group:          compat winbind
shadow:         compat

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

echo "reiniciando os serviços"
/etc/init.d/samba restart
/etc/init.d/winbind restart

echo "vamos inserir a maquina no dominio informe o usuario com direitos administrativos"
read USU
net ads join ${DOMINIO} -U ${USU}

echo "reiniciando os serviços"
/etc/init.d/samba restart
/etc/init.d/winbind restart

echo "checando a conexao com o AD"
wbinfo -t
sleep 2

echo "checando os grupos do AD"
wbinfo -g
sleep 2

echo "Checando os usuarios do AD"
wbinfo -u
sleep 2

echo "ajustando o arquivo common-password"
${CP} -Rfa /etc/pam.d/common-password{,.bkp}
${CAT} << EOF > /etc/pam.d/common-password
password        sufficient                      pam_unix.so
#password       requisite                       pam_krb5.so minimum_uid=1000
password        [success=2 default=ignore]      pam_unix.so obscure use_authtok try_first_pass sha512
password        [success=1 default=ignore]      pam_winbind.so use_authtok try_first_pass
password        requisite                       pam_deny.so
password        required                        pam_permit.so
EOF

${CP} -Rfa /etc/pam.d/common-session{,.bkp}
${CAT} << EOF > /etc/pam.d/common-session
#/etc/pam.d/common-session
session [default=1]                     pam_permit.so
session requisite                       pam_deny.so
session required                        pam_permit.so
session required                        pam_unix.so 
session optional                        pam_winbind.so 
session optional                        pam_mkhomedir.so skel=/etc/skel umask=0027
EOF

echo "Vou reiniciar o servidor"
sleep 3
reboot
MENU
} 

INSTALL_SQUID_AD (){

${APTITUDE} install -y squid3 squid3-common squid3-cgi apache2  php5 libapache2-mod-php5

${CP} -Rfa /etc/squid3/squid.conf{,.bkp}
${CAT} << EOF > /etc/squid3/squid.conf
#/etc/squid3/squid.comf
#Porta padrao do proxy
http_port 3128

#Endereco de E-mail do admin
cache_mgr suporte@gpb.local

#Nao faz cache de dados de formularios html,em de resultados de programas cgi                      
hierarchy_stoplist cgi-bin ?

#Cria uma access control list, baseando-se na url e utilizando exp. regulares nesta situacao   
#foi criado uma exp. regular para cgi e ?.        
acl QUERY urlpath_regex cgi-bin \?

#Nao faz cache da acl QUERY                        
cache deny QUERY

#Define o tamonho maximo de um objeto para seu armazenamento no cache local                 
maximum_object_size 4096 KB

#Define o tamanho minimo de um objeto para seu armazenamento no cache local                 
minimum_object_size 0 KB

#Define o tamanho maximo de um objeto para seu armazenamento no cache de memoria            
maximum_object_size_in_memory 64 KB

#Definicao da quantidade de memoria ram a ser alocada para cache                                
cache_mem 60 MB

#Para nao bloquear downloads                       
quick_abort_min -1 KB

#Para cache de fqdn
fqdncache_size 1024

#Tempo de atualizacao dos objetos relacionados aos prot ftp, gopher e http.  
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320

#Definicao da porcentagem do uso do cache que fara o squid descartar os arquivos mais antigos                                    
cache_swap_low 90
cache_swap_high 95

#Logs   
access_log /var/log/squid3/access.log squid
cache_log /var/log/squid3/cache.log
cache_store_log /var/log/squid3/store.log

#Define a localizacao do cache de disco, tamanho, qtd de diretorios pai, e por fim a qtd de dir filhos                   
cache_dir ufs /var/spool/squid3 100 16 256

#Controle do arquivo de Log
logfile_rotate 10

#Arquivo que contem os nomes de maquinas           
hosts_file /etc/hosts

#Maquinas que nao precisaram de autenticacao   
#acl liberados src "/etc/squid3/regras/liberados"
#http_access allow liberados

#### Autenticao no Windows 2008 via WINBIND
auth_param ntlm program /usr/bin/ntlm_auth --helper-protocol=squid-2.5-ntlmssp
auth_param ntlm children 30
auth_param basic program /usr/bin/ntlm_auth --helper-protocol=squid-2.5-basic
auth_param basic children 5
auth_param basic realm Squid proxy server
auth_param basic credentialsttl 2 hours
external_acl_type ad_group ttl=600 children=35 %LOGIN /usr/lib/squid3/wbinfo_group.pl

### ACL Padroes
acl manager proto cache_object
acl localhost src 127.0.0.1/32
acl SSL_ports port 443 # https
acl SSL_ports port 563 # snews
acl SSL_ports port 873 # rsync
acl Safe_ports port 80 # http
acl Safe_ports port 21 # ftp
acl Safe_ports port 443 563 # https, snews
acl Safe_ports port 70 # gopher
acl Safe_ports port 210 # wais
acl Safe_ports port 1025-65535 # unregistered ports
acl Safe_ports port 280 # http-mgmt
acl Safe_ports port 488 # gss-http
acl Safe_ports port 591 # filemaker
acl Safe_ports port 777 # multiling http
acl Safe_ports port 631 # cups
acl Safe_ports port 873 # rsync
acl Safe_ports port 901 # SWAT
acl Safe_ports port 1080
acl Safe_ports port 1863
acl Safe_ports port 8443 # https
acl Safe_ports port 47057 # torrent

acl purge method PURGE
acl CONNECT method CONNECT
http_access allow manager localhost
http_access deny manager
http_access allow purge localhost
http_access deny purge
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# Seguranca (Protecao do Cache)
acl manager proto cache_object

#Limita conexoes HTTP                              
acl connect_abertas maxconn 8

#Nao faz cache de paginas locais                   
acl NOCACHE url_regex "/etc/squid3/regras/direto" \?
no_cache deny NOCACHE

### Grupos AD
#      Nome ACL   Tipo      Nome    Grupo AD 
#ad_group -> nome da acl de autenticacao no AD
#aln-diretoria -> grupo do AD -> nao esqueca de criar esse grupo
#acesso_restrito -> grupo no AD -> nao esqueca de criar esse grupo
acl ti-admin            external ad_group ti-admin
acl proxy-administracao external ad_group proxy-administracao
acl proxy-diretoria     external ad_group proxy-diretoria
acl proxy-financeiro    external ad_group proxy-financeiro
acl proxy-gerencia      external ad_group proxy-gerencia
acl proxy-google        external ad_group proxy-google
acl proxy-operacional   external ad_group proxy-operacional
acl proxy-supervisao    external ad_group proxy-supervisao
acl proxy-transporte    external ad_group proxy-transporte

# Whitelists / Blacklists
acl macliberado                 arp              "/etc/squid3/regras/mac_liberado"
acl macblock                    arp              "/etc/squid3/regras/mac_bloqueado"
acl iplivre                     src              "/etc/squid3/regras/ip_liberado"
acl ipblock                     src              "/etc/squid3/regras/ip_bloqueado"
acl sites-proibidos             url_regex     -i "/etc/squid3/regras/expressoes_proibidas"
acl sites-bloqueados            url_regex     -i "/etc/squid3/regras/sites_bloqueados"
acl sites-liberados             url_regex     -i "/etc/squid3/regras/sites_liberados"
acl downloads                   urlpath_regex -i "/etc/squid3/regras/downloads"
acl sites-administracao         url_regex   -i "/etc/squid3/regras/sites_administracao"
acl sites-financeiro            url_regex     -i "/etc/squid3/regras/sites_financeiro"
acl sites-gerencia              url_regex     -i "/etc/squid3/regras/sites_gerencia"
acl sites-google                url_regex     -i "/etc/squid3/regras/sites_google"
acl sites-transporte            url_regex     -i "/etc/squid3/regras/sites_transporte"
acl sites-operacional           url_regex     -i "/etc/squid3/regras/sites_operacional"
acl sites-supervisao            url_regex     -i "/etc/squid3/regras/sites_supervisao"
acl sites-relacionamento        url_regex     -i "/etc/squid3/regras/sites_relacionamento"

#Libera MAC para acesso Full
http_access allow macliberado

# Bloquear MAC 
http_access deny macblock

#liberar IP para acesso Full
http_access allow iplivre

# Bloquear IP 
http_access deny ipblock

# Permissoes de Acesso
http_access allow ti-admin

#bloqueia sites de pornografia
http_access deny  sites-proibidos

#Bloqueio Sites Relacionamento
http_access deny sites-relacionamento

#libera o MAC ADDERESS
http_access allow macliberado
http_access deny  macblock

# bloqueia/Libera o IP
http_access allow iplivre
http_access allow ipblock

# LIbera acesso dos diretores
http_access allow proxy-diretoria

# Bloqueia Downloads 
http_access deny  downloads

#Bloqueia sites diversos
http_access deny  sites-bloqueados

#Libera acesso aos gerentes
http_access allow proxy-gerencia

#Libera acesso aos sites-liberados
http_access allow sites-liberados

# Libera outros acessos
http_access allow proxy-administracao sites-administracao
http_access allow proxy-financeiro    sites-financeiro
http_access allow proxy-google        sites-google !sites-relacionamento
http_access allow proxy-operacional   sites-operacional
http_access allow proxy-supervisao    sites-supervisao
http_access allow proxy-transporte    sites-transporte
http_access allow proxy-atendimento   sites-atendimento

#Bloqueia todo o resto
http_access deny all

# Outras permissoes
http_reply_access allow all
icp_access allow all
miss_access allow all

### Configuracoes Diversas
### Host visel
visible_hostname $SERVIDOR

#Localizacao das paginas de Erros                  
error_directory /usr/share/squid3/errors/Portuguese

#Configuracao de permissoes
cache_effective_user proxy
#cache_effective_group proxy

##Registo puro de uma posio da memrrria num determinado momento
coredump_dir /var/spool/squid3

EOF

${MKDIR} -p /etc/squid3/regras

${CAT} << EOF > /etc/squid3/regras/direto
#sites que nao vao ser feito cache
bradesco
itau
caixa.gov
hsbc
squid-cache

EOF

${CAT} << EOF > /etc/squid3/regras/downloads
.ace$
.af$
.afx$
.asf$
.asx$
.avi$
.bat$
.cmd$
.com$
.cpt$
.divx$
.dms$
.dot$
.dvi$
.ez$
.gl$
.hqx$
.kar$
.lha$
.lzh$
.mov$
.movie$
.mp2$
.mp3$
.mpe$
.mpeg$
.mpg$
.mpga$
.pif$
.qt$
.ra$
.rm$
.rpm$
.scr$
.spm$
.vbf$
.vob$
.vqf$
.wav$
.wk$
.wma$
.wmv$
.wpm$
.wrd$
.wvx$
.wz$

EOF




/etc/init.d/squid3 stop
squid3 -z
/etc/init.d/squid3 start

MENU
}

INSTALL_SARG()
{


echo "deb ftp://ftp.br.debian.org/debian-backports/ squeeze-backports main contrib non-free" >> /etc/apt/sources.list
echo "deb-src ftp://ftp.br.debian.org/debian-backports/ squeeze-backports main contrib non-free" >> /etc/apt/sources.list

${APTITUDE} update
${APTITUDE} install sarg -y

${CP} -Ra /etc/sarg/sarg-reports.conf{,.bkp}
${CAT} << EOF > /etc/sarg/sarg-reports.conf
     SARG=/usr/bin/sarg
     CONFIG=/etc/sarg/sarg.conf
    HTMLOUT=/var/www/sarg
  PAGETITLE="Controle de acesso do servidor \$(hostname)"
    LOGOIMG=/sarg/images/sarg.png
   LOGOLINK="http://\$(hostname)/"
      DAILY=Daily
     WEEKLY=Weekly
    MONTHLY=Monthly
EXCLUDELOG1="SARG: No records found"
EXCLUDELOG2="SARG: End"
EOF

${CP} -Ra /etc/sarg/sarg.conf{,.bkp}
${CAT} << EOF > /etc/sarg/sarg.conf
#/etc/sarg/sarg.conf
access_log /var/log/squid3/access.log
title "Relatorio de Acesso a Internet"
font_face Tahoma,Verdana,Arial
header_color darkblue
header_bgcolor blanchedalmond
font_size 9px
background_color white
text_color #000000
text_bgcolor lavender
title_color green
temporary_dir /tmp
output_dir /var/www/sarg
resolve_ip yes
user_ip no
topuser_sort_field BYTES reverse
user_sort_field BYTES reverse
exclude_users /etc/sarg/exclude_users
exclude_hosts /etc/sarg/exclude_hosts
date_format e
records_without_userid ignore
lastlog 0
remove_temp_files yes
index yes
index_tree file
overwrite_report yes
records_without_userid ip
use_comma yes
mail_utility mailx
topsites_num 100
topsites_sort_order CONNECT D
index_sort_order D
exclude_codes /etc/sarg/exclude_codes
max_elapsed 28800000
report_type topusers topsites sites_users users_sites date_time denied auth_failures site_user_time_date downloads
usertab /etc/sarg/usertab
long_url no
date_time_by bytes
charset Latin1
show_successful_message no
show_read_statistics no
topuser_fields NUM DATE_TIME USERID CONNECT BYTES %BYTES IN-CACHE-OUT USED_TIME MILISEC %TIME TOTAL AVERAGE
user_report_fields CONNECT BYTES %BYTES IN-CACHE-OUT USED_TIME MILISEC %TIME TOTAL AVERAGE
topuser_num 0
download_suffix "zip,arj,bzip,gz,ace,doc,iso,adt,bin,cab,com,dot,drv$,lha,lzh,mdb,mso,ppt,rtf,src,shs,sys,exe,dll,mp3,avi,mpg,mpeg"
EOF

${CP} -Rfa /etc/cron.daily/sarg /etc/cron.hourly/

echo "NAO ESQUECA DE CRIAR OS SEGUINTES GRUPOS NO AD com_internet, acesso_restrito, acesso_bancos e colocar os usuarios nos grupos"
echo "SEUS RELATORIOS DO SARG VAO ESTAR EM http://localhost/sarg"
echo "SEU CACHE MANAGER ESTA EM http://localhost/cgi-bin/cachemgr.cgi usuario para acesso e o root e a senha do root"
echo "TESTAR A AUTENTICACAO PODE SER EFETUADO COMO SEGUINTE COMANDO #wbinfo -a usuario%senha "

${SED} -i "/deb ftp:\/\/ftp.br.debian.org\/debian-backports\/ squeeze-backports main contrib non-free/Id" /etc/apt/sources.list
${SED} -i "/deb-src ftp:\/\/ftp.br.debian.org\/debian-backports\/ squeeze-backports main contrib non-free/Id"  /etc/apt/sources.list

MENU
}
MENU