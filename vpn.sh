#!/bin/bash
f_clr () {
    yes "" | head -n "$(tput lines)"
}

first_run () {
    f_clr
    echo -en "Вы начинаета настраивать OpenVPN. Сначала необходимо настроить переменные для генерации ключей.\\n\
        \\rБудут выведены построчно переменные, значения которых необходимо изменить, или оставить по умолчанию нажав клавишу ввод.\\n\
        \\n\
        \\rПриступить к настройке значений? [y|N]: "
    read -r -n 1 change_vars && echo
    case "$change_vars" in
        Y|y)
                export EASY_RSA="`pwd`"
                export OPENSSL="openssl"
                export PKCS11TOOL="pkcs11-tool"
                export GREP="grep"
                export KEY_CONFIG="$EASY_RSA/openssl-1.0.0.cnf"
                export KEY_DIR="$EASY_RSA/keys"
                export PKCS11_MODULE_PATH="dummy"
                export PKCS11_PIN="dummy"
                export KEY_SIZE=2048
                export CA_EXPIRE=3650
                export KEY_EXPIRE=3650
                export KEY_COUNTRY="DC"
                export KEY_PROVINCE="DP"
                export KEY_CITY="DEF_CITY"
                export KEY_ORG="DEF_ORG"
                export KEY_EMAIL="def@def_domain.zone"
                export KEY_OU="DEF_UNIT"
                export KEY_NAME="default_server"
            f_clr
            if [ "$KEY_DIR" ]; then
                rm -rf "$KEY_DIR"
                mkdir "$KEY_DIR" && \
                    chmod go-rwx "$KEY_DIR" && \
                    touch "$KEY_DIR/index.txt" && \
                    echo 01 >"$KEY_DIR/serial"
                    sudo rm -rf /etc/openvpn/keys 2>/dev/null
                    sudo rm -f /etc/openvpn/*.conf 2>/dev/null
                    sudo rm -rf /etc/openvpn/ccd 2>/dev/null
                    sudo rm -rf /var/log/openvpn 2>/dev/null
                    sudo rm -rf "$KEY_DIR/clients_files"
            else
                echo 'Please source the vars script first (i.e. "source ./vars")'
                echo 'Make sure you have edited it to reflect your configuration.'
            fi
            while [ "${accepted:-0}" -ne 1 ]; do
                echo -en "Двухбуквенный код страны\\n\
                \\rKEY_COUNTRY=\"$KEY_COUNTRY\": "
                    read -r -n 2 key_country
                    [ -z "$key_country" ] || KEY_COUNTRY="$( echo "$key_country"| tr '[:lower:]' '[:upper:]' )"
                    echo
                echo -en "Двух или трех буквенный код региона\\n\
                \\rKEY_PROVINCE=\"$KEY_PROVINCE\": "
                    read -r -n 2 key_province
                    [ -z "$key_province" ] || KEY_PROVINCE="$( echo "$key_province"| tr '[:lower:]' '[:upper:]' )"
                    echo
                echo -en "Название города\\n\
                \\rKEY_CITY=\"$KEY_CITY\": "
                    read -r key_city
                    [ -z "$key_city" ] || KEY_CITY="$key_city"
                    echo
                echo -en "Название органицации\\n\
                \\rKEY_ORG=\"$KEY_ORG\": "
                    read -r key_org
                    [ -z "$key_org" ] || KEY_ORG="$key_org"
                    echo
                echo -en "Электронные адрес\\n\
                \\rKEY_EMAIL=\"$KEY_EMAIL\": "
                    read -r key_email
                    [ -z "$key_email" ] || KEY_EMAIL="$key_email"
                    echo
                echo -en "Название подразделения\\n\
                \\rKEY_OU=\"$KEY_OU\": "
                    read -r key_ou
                    [ -z "$key_ou" ] || KEY_OU="$key_ou"
                    echo
                echo -en "Название которое Вы хотите дать своему VPN серверу\\n\
                \\rKEY_NAME=\"$KEY_NAME\": "
                    read -r key_name
                    [ -z "$key_name" ] || KEY_NAME="$key_name"
                    echo
                f_clr
                echo -en "\\e[1;33mБудут установлены следующие значения.\\e[0m\\n\
                \\r\\n\
                \\rKEY_COUNTRY=\"$KEY_COUNTRY\"\\n\
                \\rKEY_PROVINCE=\"$KEY_PROVINCE\"\\n\
                \\rKEY_CITY=\"$KEY_CITY\"\\n\
                \\rKEY_ORG=\"$KEY_ORG\"\\n\
                \\rKEY_EMAIL=\"$KEY_EMAIL\"\\n\
                \\rKEY_OU=\"$KEY_OU\"\\n\
                \\rKEY_NAME=\"$KEY_NAME\"\\n\
                \\n\
                \\rВы подтверждаете, что все переменные имею желаемые значения? [\\e[1;31my\\e[0m|\\e[1;32mN\\e[0m]]: "
                read -r -n 1 answer && echo
                if [[ "$answer" == "y" ]]; then
                    accepted=1
                    work_path=$( pwd | sed 's%\/%\\\/%g')
                    sed -ri "/func_export_vars/,/\\}/{/^ +export KEY_COUNTRY/s/\".*\"/\"$KEY_COUNTRY\"/;\
                    /^ +export KEY_PROVINCE/s/\".*\"/\"$KEY_PROVINCE\"/;\
                    /^ +export KEY_CITY/s/\".*\"/\"$KEY_CITY\"/;\
                    /^ +export KEY_ORG/s/\".*\"/\"$KEY_ORG\"/;\
                    /^ +export KEY_EMAIL/s/\".*\"/\"$KEY_EMAIL\"/;\
                    /^ +export KEY_OU/s/\".*\"/\"$KEY_OU\"/;\
                    /^ +export KEY_NAME/s/\".*\"/\"$KEY_NAME\"/;\
                    /^ +export EASY_RSA/s/\".*\"/\"$work_path\"/}" "$0"
                    sed -ri "/func_export_vars/,/\\}/{/^ +export KEY_CONFIG/s/=.*$/=\"\$EASY_RSA\\/openssl-1.0.0.cnf\"/}" "$0"
                    sed -ri "/^ +export FIRST_RUN_KEY/s/1/0/" "$0"
                else
                    f_clr
                fi
            done
            ;;
        *)
            f_clr
            echo -en "Данная настройка необходима для правильной конфигурации OpenVPN.\\n\
            \\rПожалуйста запустите скрип настройки еще раз.\\n\
            \\rНастройка значений производится только один раз, при первом запуске." && echo
            exit 0
            ;;
    esac
}

export_vars (){
    # func_export_vars
    export EASY_RSA="`pwd`"
    export OPENSSL="openssl"
    export PKCS11TOOL="pkcs11-tool"
    export GREP="grep"
    export KEY_CONFIG="$EASY_RSA/openssl-1.0.0.cnf"
    export KEY_DIR="$EASY_RSA/keys"
    export PKCS11_MODULE_PATH="dummy"
    export PKCS11_PIN="dummy"
    export KEY_SIZE=2048
    export CA_EXPIRE=3650
    export KEY_EXPIRE=3650
    export KEY_COUNTRY="$KEY_COUNTRY"
    export KEY_PROVINCE="$KEY_PROVINCE"
    export KEY_CITY="$KEY_CITY"
    export KEY_ORG="$KEY_ORG"
    export KEY_EMAIL="$KEY_EMAIL"
    export KEY_OU="$KEY_OU"
    export KEY_NAME="$KEY_NAME"
}

case "$1" in
    setup)
        export FIRST_RUN_KEY=1
        if [ "$FIRST_RUN_KEY" -eq 0 ]; then
            f_clr
            echo -en "\\e[1;31mУ вас уже настроен центр сертификации. Продолжение приведет к невозможности его использования\\e[0m\\n\
            \\rПродолжить? [N|y]"
            read -r -n 1 answ && echo
            [[ $answ == "y" ]] || exit 22
        fi
        first_run
        export_vars

        echo -en "Вы желаете защитить паролем корневой сертификат? [\\e[1;32my\\e[0m|\\e[1;31mN\\e[0m]]: "
        read -r -n 1 yespass && echo
        [[ "$yespass" == "y" ]] && setpass="--pass"
        "$EASY_RSA"/pkitool --initca "${setpass}"
        "$EASY_RSA"/pkitool --server "$KEY_NAME"
        f_clr
        "$OPENSSL" dhparam -out "${KEY_DIR}"/dh${KEY_SIZE}.pem ${KEY_SIZE}
        openvpn --genkey --secret "${KEY_DIR}"/ta.key
        [ -d /etc/openvpn/keys ] || sudo mkdir -p /etc/openvpn/keys
        [ -d /var/log/openvpn ] || sudo mkdir -p /var/log/openvpn/
        [ -d /etc/openvpn/ccd ] || sudo mkdir -p /etc/openvpn/ccd

        sudo cp "${KEY_DIR}"/{ca.key,ca.crt,ta.key,dh"$KEY_SIZE".pem,"$KEY_NAME".key,"$KEY_NAME".crt} /etc/openvpn/keys || exit 332

        # ===== Config Server ======
        echo -e "mode server\\n\
proto udp\\n\
dev tun\\n\
port 1194\\n\
tun-mtu 1500\\n\
mssfix 0\\n\
tls-server\\n\
float\\n\
ca /etc/openvpn/keys/ca.crt\\n\
cert /etc/openvpn/keys/$KEY_NAME.crt\\n\
key /etc/openvpn/keys/$KEY_NAME.key\\n\
dh /etc/openvpn/keys/dh$KEY_SIZE.pem\\n\
server 172.10.1.0 255.255.255.0\\n\
ifconfig-pool-persist ipp.txt\\n\
client-config-dir ccd\\n\
push \"redirect-gateway def1 bypass-dhcp\"\\n\
push \"dhcp-option DNS 208.67.222.222\"\\n\
push \"dhcp-option DNS 208.67.220.220\"\\n\
client-to-client\\n\
keepalive 10 120\\n\
key-direction 0\\n\
tls-auth /etc/openvpn/keys/ta.key\\n\
cipher AES-256-CBC\\n\
auth SHA256\\n\
ncp-ciphers AES-256-CBC\\n\
tls-timeout 3600\\n\
hand-window 3600\\n\
user nobody\\n\
group nogroup\\n\
compress lz4\\n\
persist-key\\n\
persist-tun\\n\
status      /var/log/openvpn/openvpn-status.log\\n\
log         /var/log/openvpn/openvpn_current_session.log\\n\
log-append   /var/log/openvpn/openvpn.log\\n\
verb 3\\n\
mute-replay-warnings\\n\
#crl-verify /etc/openvpn/crl.pem\\n\
                " | sudo tee /etc/openvpn/"$KEY_NAME".conf >/dev/null 2>&1
                sudo systemctl start openvpn@"$KEY_NAME"
                sudo systemctl status openvpn@"$KEY_NAME"
                sudo cat /etc/openvpn/"$KEY_NAME".conf
        ;;
    add)
        export_vars
# ============ DEBUG ===============
        # f_clr
        # echo "$KEY_NAME"
        # echo "$KEY_DIR"
        # sleep 10
# =================================


        [ -z "$2" ] && exit 10
        CLIENTS_KEYS="$EASY_RSA/clients_files/${2}/keys"
        if [ -d "$EASY_RSA/clients_files/${2}" ]; then
            echo -e "Пользователь \\e[1;32m${2}\\e[0m уже существует."
            exit 13
        fi
        mkdir -p "$CLIENTS_KEYS"

        if ! [ -f /etc/openvpn/"$KEY_NAME".conf ]; then
            echo -e "\\e[1;31mСначала нужно создать конфигурацию OpenVPN.\\e[0m\\n\
            \\rДля того, чтобы создать конфигурацию OpenVPN введите команду ./$(basename "$0") config"
            exit 16
        fi
        [ -d "$CLIENTS_KEYS" ] || exit 15
        "$EASY_RSA"/pkitool "$2"
        mv "$KEY_DIR/${2}."* "$CLIENTS_KEYS"

        OVPN_FILE="$EASY_RSA/clients_files/${2}/${2}.ovpn"
        # export_vars
        REMOTE="$(curl -s -4 https://wtfismyip.com/text)"
        PORT="$(grep -E "^port " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        CIPHER="$(grep -E "^cipher " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        AUTH="$(grep -E "^auth " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
#        TUN_MTU="$(grep -E "^tun-mtu " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        MSSFIX="$(grep -E "^mssfix " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        NCP_CIPHER="$(grep -E "^ncp-ciphers " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        COMPRESS="$(grep -E "^compress " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"

cat >> "$OVPN_FILE" << EOF
    client
    dev tun
    auth-nocache
    explicit-exit-notify 1
    mtu-test
    mssfix $MSSFIX
    remote $REMOTE $PORT udp
    resolv-retry infinite
    compress $COMPRESS
    user nobody
    group nogroup
    persist-key
    persist-tun
    tls-client
    tls-timeout 3600
    hand-window 3600
    remote-cert-tls server
    cipher $CIPHER
    auth $AUTH
    ncp-ciphers ${NCP_CIPHER}
    verb 2
    mute 20

    # script-security 2
    # up /etc/openvpn/update-resolv-conf
    # down /etc/openvpn/update-resolv-conf"
EOF
        sed -ri 's/^ +//g' "$OVPN_FILE"

        cat <(echo -e '<ca>')\
            "$KEY_DIR"/ca.crt\
            <(echo -e '</ca>\n<cert>')\
            "$CLIENTS_KEYS/${2}".crt\
            <(echo -e '</cert>\n<key>')\
            "$CLIENTS_KEYS/${2}".key\
            <(echo -e '</key>\nkey-direction 1\n<tls-auth>')\
            "$KEY_DIR"/ta.key\
            <(echo -e '</tls-auth>')\
            >> "$OVPN_FILE"
        ;;
    revok)
        export_vars
        [ -z "$2" ] && exit 10
        "$EASY_RSA"/revoke-full "$2"
esac

# basename "$(ps -aux | grep openvpn | grep -m1 config | awk '{print $22}')" | sed -r 's/\.\w+$//' -- Проверка запущенных OpenVPN для
