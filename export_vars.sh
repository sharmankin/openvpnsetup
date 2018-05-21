#!/bin/bash
f_clr () {
    yes "" | head -n "$(tput lines)"
}
findmaxcnf (){
        find "$EASY_RSA" -maxdepth 1 -regex ".*openssl-.*.cnf" | while read -r cnf
        do [[ ${maxvers:-0} < "$cnf" ]] && maxvers="$cnf" && echo "$maxvers" > "$EASY_RSA"/mvers
        done
        echo "$(<"$EASY_RSA"/mvers)"
        rm "$EASY_RSA"/mvers
}
org_to_email () {
    rslt="$(echo "$1" | tr -d "[:blank:]" | tr -d "[:punct:]" | tr -s "[:upper:]" "[:lower:]")"
    echo "info@${rslt}.org"
}
export_vars () {
    # == Export Section Begin ===========
        EASY_RSA="$(find / -type l -name pkitool -exec dirname {} \; 2>/dev/null)"
            export EASY_RSA
            export OPENSSL="openssl"
            export PKCS11TOOL="pkcs11-tool"
            export GREP="grep"
        KEY_CONFIG="$(findmaxcnf)"
            export KEY_CONFIG
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
        KEY_EMAIL="$(org_to_email $KEY_ORG)"
            export KEY_EMAIL
            export KEY_OU="DEF_UNIT"
            export KEY_NAME="ovpnserver"
            export FIRST_RUN_KEY=1
    # == Export Section End =============
}
set_vars (){
    [ "$EASY_RSA" ] || exit 10
    sed -ri "/Export Section Begin/,/Export Section End/{\
        /^ +EASY_RSA/s/\".*\"/\"${EASY_RSA//\//\\\/}\"/;\
        /^ +KEY_CONFIG/s/\".*\"/\"${KEY_CONFIG//\//\\\/}\"/;\
        /^ +export KEY_DIR/s/\".*\"/\"${KEY_DIR//\//\\\/}\"/;\
        /^ +export KEY_COUNTRY/s/\".*\"/\"$KEY_COUNTRY\"/;\
        /^ +export KEY_PROVINCE/s/\".*\"/\"$KEY_PROVINCE\"/;\
        /^ +export KEY_CITY/s/\".*\"/\"$KEY_CITY\"/;\
        /^ +export KEY_ORG/s/\".*\"/\"$KEY_ORG\"/;\
        /^ +KEY_EMAIL/s/\".*\"/\"$KEY_EMAIL\"/;\
        /^ +export KEY_OU/s/\".*\"/\"$KEY_OU\"/;\
        /^ +export KEY_NAME/s/\".*\"/\"$KEY_NAME\"/;\
        /^ +export FIRST_RUN_KEY/s/1/0/\
    }" "$0"
}
make_conf_file () {
    cat > "$EASY_RSA/$KEY_NAME".conf <<  EOF
        mode server
        proto udp
        dev tun
        port $(while [ "${s:-0}" -ne 1 ];do e=$RANDOM;echo $e | grep -qE "^[1-9]{4}$" && s=1 && echo $e;done)
        tun-mtu 1500
        mssfix 0
        tls-server
        float
        ca /etc/openvpn/keys/ca.crt
        cert /etc/openvpn/keys/$KEY_NAME.crt
        key /etc/openvpn/keys/$KEY_NAME.key
        dh /etc/openvpn/keys/dh$KEY_SIZE.pem
        server 172.10.1.0 255.255.255.0
        ifconfig-pool-persist ipp.txt
        client-config-dir ccd
        push "redirect-gateway def1 bypass-dhcp"
        push "dhcp-option DNS 208.67.222.222"
        push "dhcp-option DNS 208.67.220.220"
        # client-to-client
        keepalive 10 120
        key-direction 0
        tls-auth /etc/openvpn/keys/ta.key
        cipher AES-256-CBC
        auth SHA256
        ncp-ciphers AES-256-CBC
        tls-timeout 3600
        hand-window 3600
        user nobody
        group nogroup
        persist-key
        persist-tun
        status      /var/log/openvpn/openvpn-status.log
        log         /var/log/openvpn/openvpn_current_session.log
        log-append   /var/log/openvpn/openvpn.log
        verb 3
        mute-replay-warnings
        # crl-verify /etc/openvpn/crl.pem
EOF
    sed -ri 's/^ +//g' "$EASY_RSA/$KEY_NAME".conf
    sudo mv "$EASY_RSA/$KEY_NAME".conf /etc/openvpn/
}
first_run () {
    f_clr
    echo -en "Вы начинаете установку OpenVPN сервер. Сначала необходимо настроить переменные для генерации ключей.\\n\
        \\rБудут выведены построчно переменные, значения которых необходимо изменить, или оставить по умолчанию нажав клавишу ввод.\\n\
        \\n\
        \\rПриступить к настройке значений? [y|N]: "
    read -r -n 1 change_vars && echo
    case "$change_vars" in
        Y|y)
            f_clr
    # == <Emulate ./clean-all> ====
            if [ "$KEY_DIR" ]; then
                rm -rf "$KEY_DIR"
                mkdir "$KEY_DIR" && \
                    chmod go-rwx "$KEY_DIR" && \
                    touch "$KEY_DIR/index.txt" && \
                    echo 01 > "$KEY_DIR/serial"
                    [ -d /etc/openvpn/keys ] && sudo rm -rf /etc/openvpn/keys
                    find /etc/openvpn/ -maxdepth 1 -name '*.conf' -exec sudo rm -f {} \; 2>/dev/null
                    [ -d /etc/openvpn/ccd ] && sudo rm -rf /etc/openvpn/ccd
                    find /var/log/ -name 'openvpn*' -exec sudo rm -rf {} \; 2>/dev/null
                    [ -d "$KEY_DIR/clients_files" ] && sudo rm -rf "$KEY_DIR/clients_files"
            else
                echo 'Please source the vars script first (i.e. "source ./vars")'
                echo 'Make sure you have edited it to reflect your configuration.'
            fi
    # == </Emulate ./clean-all> ====
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
                \\rKEY_EMAIL=\"$(org_to_email "$KEY_ORG")\": "
                    read -r key_email
                    [ -z "$key_email" ] && KEY_EMAIL="$(org_to_email "$KEY_ORG")"
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
                \\rВы подтверждаете, что все переменные имеют желаемые значения? [\\e[1;31my\\e[0m|\\e[1;32mN\\e[0m]]: "
                read -r -n 1 answer && echo
                if [[ "$answer" == "y" ]]; then
                    echo -en "Установить мастер-пароль для управления пользователями OpenVPN сервера? [\\e[1;31my\\e[0m|\\e[1;32mN\\e[0m]]: "
                    read -r -n 1 yespass
                    [[ "$yespass" == "y" ]] && initwithpass="--pass"


                    "$EASY_RSA"/pkitool --initca "$initwithpass"
                    "$EASY_RSA"/pkitool --server "$KEY_NAME"
                    f_clr
                    "$OPENSSL" dhparam -out "${KEY_DIR}"/dh${KEY_SIZE}.pem ${KEY_SIZE}
                    openvpn --genkey --secret "${KEY_DIR}"/ta.key
                    sudo mkdir -p /etc/openvpn/keys
                    sudo mkdir -p /var/log/openvpn
                    sudo mkdir -p /etc/openvpn/ccd
                    sudo cp "${KEY_DIR}"/{ca.key,ca.crt,ta.key,dh"$KEY_SIZE".pem,"$KEY_NAME".key,"$KEY_NAME".crt} /etc/openvpn/keys || exit 332

                    make_conf_file

                    if sudo systemctl start openvpn@"$KEY_NAME" 2>/dev/null; then
                        f_clr
                        echo -e "OpenVPN сервер \\e[1;32m$KEY_NAME\\e[0m Установлен и запущен без ошибок"
                        accepted=1
                        sudo cat /etc/openvpn/"$KEY_NAME".conf
                        set_vars
                    else
                        echo -e "\\e[1;31mЧто-то пошло не так. Попробуйте повторить установку.\\e[0m"
                    fi
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
    exit 0
}
export_vars
[ $FIRST_RUN_KEY -eq 1 ] && first_run
