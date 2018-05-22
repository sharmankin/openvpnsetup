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
rand_network () {
    while [ "${match:-0}" -ne 1 ];do
    segment=$(( RANDOM % 253 ))
    if [ $segment -gt 10 ] ;then
        [ "$(( segment / 8 * 8 ))" -eq $segment ] && match=1 && echo $segment
    fi
done
}
make_conf_file () {
    echo -e "mode server\\n\
            proto udp\\n\
            dev tun\\n\
            port $(while [ "${s:-0}" -ne 1 ];do e=$RANDOM;echo $e | grep -qE "^[1-9]{4}$" && s=1 && echo $e;done)\\n\
            tun-mtu 1500\\n\
            mssfix 0\\n\
            tls-server\\n\
            float\\n\
            ca /etc/openvpn/keys/ca.crt\\n\
            cert /etc/openvpn/keys/$KEY_NAME.crt\\n\
            key /etc/openvpn/keys/$KEY_NAME.key\\n\
            dh /etc/openvpn/keys/dh$KEY_SIZE.pem\\n\
            server 192.$(rand_network).$(rand_network).0 255.255.255.0\\n\
            ifconfig-pool-persist ipp.txt\\n\
            client-config-dir ccd\\n\
            push \"redirect-gateway def1 bypass-dhcp\"\\n\
            push \"dhcp-option DNS 208.67.222.222\"\\n\
            push \"dhcp-option DNS 208.67.220.220\"\\n\
            # client-to-client\\n\
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
            persist-key\\n\
            persist-tun\\n\
            status      /var/log/openvpn/openvpn-status.log\\n\
            log         /var/log/openvpn/openvpn_current_session.log\\n\
            log-append   /var/log/openvpn/openvpn.log\\n\
            verb 3\\n\
            mute-replay-warnings\\n\
            # crl-verify /etc/openvpn/crl.pem" | sed -r 's/^[[:cntrl:]]? +//g' | sudo tee /etc/openvpn/"$KEY_NAME".conf > /dev/null

    # sudo chown root:root /etc/openvpn/"$KEY_NAME".conf
    # sudo chmod 644 /etc/openvpn/"$KEY_NAME".conf
}
make_aliases () {
    EDITOR="$(sudo update-alternatives --get-selections | grep editor | awk '{print $3}')"
    echo -e "alias editvpn='sudo $EDITOR /etc/openvpn/$KEY_NAME.conf'\\n\
    alias vpnlog='sudo lnav /var/log/openvpn/openvpn_current_session.log'\\n\
    alias vpnonline='sudo cat /var/log/openvpn/openvpn-status.log'" >> "$HOME"/.bash_aliases
    sed -ri 's/^[[:cntrl:]]? +//g' "$HOME"/.bash_aliases
}
first_run () {
    f_clr
    echo -en "Вы начинаете установку OpenVPN сервер. Сначала необходимо настроить переменные для генерации ключей.\\n\
        \\rБудут выведены построчно переменные, значения которых необходимо изменить, или оставить по умолчанию нажав клавишу ввод.\\n\
        \\n\
        \\rПриступить к настройке значений? [\\e[1;31my\\e[0m|\\e[1;32mN\\e[0m]]: "
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
            sudo apt-get -y install zip lnav > /dev/null&
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
                    sudo cp "${KEY_DIR}"/{ca.key,ca.crt,ta.key,dh"$KEY_SIZE".pem,"$KEY_NAME".crt,"$KEY_NAME".key} /etc/openvpn/keys || exit 332
                    make_conf_file

                    if sudo systemctl start openvpn@"$KEY_NAME" 2>/dev/null; then
                        sudo systemctl enable openvpn@"$KEY_NAME" >/dev/null
                        f_clr
                        echo -e "\\e[1;32m=======================================================================\\e[0m\\n\
                        \\rOpenVPN сервер \\e[1;32m$KEY_NAME\\e[0m Установлен и запущен без ошибок\\n\
                        \\r\\e[1;32m=======================================================================\\e[0m\\n\\r"
                        accepted=1
                        sudo cat /etc/openvpn/"$KEY_NAME".conf
                        sudo sed -i '/net.ipv4.ip_forward/s/^#//' /etc/sysctl.conf
                        echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null
                        sudo sysctl -p > /dev/null
                        main_interface="$(ip addr | grep -E "inet.*global.* e\\w+$" | awk '{print $7}')"
                        tun_network="$(sudo grep -E "^server" /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"

                        if sudo uwf status 2>/dev/null | grep -qw active; then
                        sudo sed '/^$/,$d' /etc/ufw/before.rules | tee add_rules_file > /dev/null
                            echo -e "\\n\
                                # START OPENVPN RULES\\n\
                                # NAT table rules\\n\
                                *nat\\n\
                                :POSTROUTING ACCEPT [0:0] \\n\
                                # Allow traffic from OpenVPN client to $main_interface\\n\
                                -A POSTROUTING -s $tun_network/24 -o $main_interface -j MASQUERADE\\n\
                                COMMIT\\n\
                                # END OPENVPN RULES\\n\
                            " | sed -r 's/^ +//g' >> add_rules_file
                            sudo sed '1,/^$/d' /etc/ufw/before.rules | tee -a add_rules_file > /dev/null
                            sudo mv /etc/ufw/before.rules{,.bkp}
                            more add_rules_file | sudo tee /etc/ufw/before.rules > /dev/null
                            rm add_rules_file
                            sudo ufw allow "$(sudo grep -E "^port" /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"/udp > /dev/null
                            sudo systemctl restart ufw
                        else
                     #       sudo /sbin/iptables -A POSTROUTING -s "$tun_network/24" -o "$main_interface" -j MASQUERADE
                            echo -e "[Unit]\\n\
                            Description=Up nat route for openvpn\\n\
                            After=network.target\\n\\n\
                            [Service]\\n\
                            Type=forking\\n\
                            User=root\\n\
                            ExecStart=/sbin/iptables  -t nat -A POSTROUTING -s $tun_network/24 -o $main_interface -j MASQUERADE\\n\\n\
                            [Install]\\n\
                            WantedBy=multi-user.target" | sed -r 's/^ +//g' | sudo tee /etc/systemd/system/ovpnroute.service
                            sudo systemctl daemon-reload >/dev/null
                            sudo systemctl enable ovpnroute >/dev/null
                            sudo systemctl start ovpnroute >/dev/null
                        fi
                        set_vars
                        make_aliases
                    else
                        f_clr
                        echo -e "\\e[1;31m===================================================================================================\\e[0m\\n\
                        \\rOpenVPN сервер \\e[1;31m$KEY_NAME\\e[0m Установлен с ошибками\\n\
                        \\rПопробуйте найти ошибку запустив команду \"\\e[1;35msudo lnav /var/log/openvpn/openvpn_current_session.log\\e[0m\"\\n\
                        \\r\\e[1;31m===================================================================================================\\e[0m\\n\\r"
                        exit 1000
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
add_user () {
    [ -d "$EASY_RSA/clients_files" ] || mkdir -p "$EASY_RSA/clients_files"
    [ -f "$EASY_RSA/registred_users" ] || touch "$EASY_RSA/registred_users"
    if grep -qE "^$vpnuser:" "$EASY_RSA/registred_users" ;then   # Доработать с учетом ID пользователя
        echo -e "Пользователь с именем $vpnuser уже зарегистрирован на сервере.\\n\
        \\rВыберите другое имя для регистрируемого пользователя"
        exit 990
    fi
    "$EASY_RSA"/pkitool "$vpnuser"
    CLIENT_DIR="$EASY_RSA/clients_files/$vpnuser/"
    OVPN_FILE="$CLIENT_DIR/${vpnuser}_${KEY_NAME}.ovpn"
    mkdir -p "$CLIENT_DIR"
    zip -qj "$CLIENT_DIR/${vpnuser}_${KEY_NAME}.zip" "$KEY_DIR"/{"$vpnuser".key,"$vpnuser".crt,ta.key,ca.crt}
    echo "$vpnuser:$CLIENT_DIR:active" >> "$EASY_RSA/registred_users"

        REMOTE="$(curl -s -4 https://wtfismyip.com/text)"
        PORT="$(grep -E "^port " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        CIPHER="$(grep -E "^cipher " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        AUTH="$(grep -E "^auth " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        MSSFIX="$(grep -E "^mssfix " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
        NCP_CIPHER="$(grep -E "^ncp-ciphers " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
    #        TUN_MTU="$(grep -E "^tun-mtu " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"
    #        COMPRESS="$(grep -E "^compress " /etc/openvpn/"$KEY_NAME".conf | awk '{print $2}')"

    echo -e "
        client\\n\
        dev tun\\n\
        auth-nocache\\n\
        explicit-exit-notify 1\\n\
        mtu-test\\n\
        mssfix $MSSFIX\\n\
        remote $REMOTE $PORT udp\\n\
        resolv-retry infinite\\n\
        user nobody\\n\
        group nogroup\\n\
        persist-key\\n\
        persist-tun\\n\
        tls-client\\n\
        tls-timeout 3600\\n\
        hand-window 3600\\n\
        remote-cert-tls server\\n\
        cipher $CIPHER\\n\
        auth $AUTH\\n\
        ncp-ciphers ${NCP_CIPHER}\\n\
        verb 0\\n\
        mute 20
        " > "$OVPN_FILE"
        sed -ri 's/^[[:cntrl:]]? +//g' "$OVPN_FILE"

        cat <(echo -e '<ca>')\
            "$KEY_DIR"/ca.crt\
            <(echo -e '</ca>\n<cert>')\
            "$KEY_DIR/$vpnuser".crt\
            <(echo -e '</cert>\n<key>')\
            "$KEY_DIR/$vpnuser".key\
            <(echo -e '</key>\nkey-direction 1\n<tls-auth>')\
            "$KEY_DIR"/ta.key\
            <(echo -e '</tls-auth>')\
            >> "$OVPN_FILE"
}

export_vars
[ $FIRST_RUN_KEY -eq 1 ] && first_run

case "$1" in
        add)
            [ -z "$2" ] && exit 223
            vpnuser="$(echo "$2" | tr -d "[:blank:]" | tr -d "[:punct:]" | tr -s "[:upper:]" "[:lower:]")"
            add_user
        ;;
    revok)
        export_vars
        [ -z "$2" ] && exit 10
        "$EASY_RSA"/revoke-full "$2"
        ;;
esac
