#!/bin/bash
f_clr () {
    yes "" | head -n "$(tput lines)"
}
def_vars () {
    awk -F '"' '$1 ~ KEY {print $2}' KEY="$1" vars
}
get_vars (){
    KEY_COUNTRY="$(def_vars KEY_COUNTRY)"
    KEY_PROVINCE="$(def_vars KEY_PROVINCE)"
    KEY_CITY="$(def_vars KEY_CITY)"
    KEY_ORG="$(def_vars  KEY_ORG)"
    KEY_EMAIL="$(def_vars  KEY_EMAIL)"
    KEY_OU="$(def_vars  KEY_OU)"
    KEY_NAME="$(def_vars  KEY_NAME)"
}
set_vars (){
    export EASY_RSA="$(pwd)"
    export OPENSSL="openssl"
    export PKCS11TOOL="pkcs11-tool"
    export GREP="grep"
        KEY_CONFIG="$(pwd)/openssl-1.0.0.cnf"
    export KEY_CONFIG
    export KEY_DIR="$EASY_RSA/keys"
    export PKCS11_MODULE_PATH="dummy"
    export PKCS11_PIN="dummy"
    export KEY_SIZE=2048
    export CA_EXPIRE=3650
    export KEY_EXPIRE=3650
        KEY_COUNTRY="$(def_vars KEY_COUNTRY)"
    export KEY_COUNTRY
        KEY_PROVINCE="$(def_vars KEY_PROVINCE)"
    export KEY_PROVINCE
        KEY_CITY="$(def_vars KEY_CITY)"
    export KEY_CITY
        KEY_ORG="$(def_vars KEY_ORG)"
    export KEY_ORG
        KEY_EMAIL="$(def_vars KEY_EMAIL)"
    export KEY_EMAIL
        KEY_OU="$(def_vars KEY_OU)"
    export KEY_OU
        KEY_NAME="$(def_vars KEY_NAME)"
    export KEY_NAME
}
first_run () {
    f_clr
    echo -en "Вы начинаета настраивать OpenVPN. Сначала необходимо настроить переменные для генерации ключей.\\n\
        Будут выведены построчно переменные, значения которых необходимо изменить, или оставить по умолчанию нажав клавишу ввод.\\n\
        Приступить к настройке значений? [y|N]: "
    read -r -n 1 change_vars && echo
    case "$change_vars" in
        Y|y)
            f_clr
            while [ "${accepted:-0}" -ne 1 ]; do
                get_vars
                echo -en "Двухбуквенный код страны\\n\
                \\rKEY_COUNTRY=\"$KEY_COUNTRY\": "
                    read -r key_country
                    [ -z "$key_country" ] || KEY_COUNTRY="$key_country"
                    echo
                echo -en "Двух или трех буквенный код региона\\n\
                \\rKEY_PROVINCE=\"$KEY_PROVINCE\": "
                    read -r key_province
                    [ -z "$key_province" ] || KEY_PROVINCE="$key_province"
                    echo
                echo -en "Название города\\n\
                KEY_CITY=\"$KEY_CITY\": "
                    read -r key_city
                    [ -z "$key_city" ] || KEY_CITY="$key_city"
                    echo
                echo -en "Название органицации\\n\
                KEY_ORG=\"$KEY_ORG\": "
                    read -r key_org
                    [ -z "$key_org" ] || KEY_ORG="$key_org"
                    echo
                echo -en "Электронные адрес\\n\
                KEY_EMAIL=\"$KEY_EMAIL\": "
                    read -r key_email
                    [ -z "$key_email" ] || KEY_EMAIL="$key_email"
                    echo
                echo -en "Название подразделения\\n\
                KEY_OU=\"$KEY_OU\": "
                    read -r key_ou
                    [ -z "$key_ou" ] || KEY_OU="$key_ou"
                    echo
                echo -en "Название которое Вы хотите дать своему VPN серверу\\n\
                KEY_NAME=\"$KEY_NAME\": "
                    read -r key_name
                    [ -z "$key_name" ] || KEY_NAME="$key_name"
                    echo
                f_clr
                echo -en "KEY_COUNTRY=\"$KEY_COUNTRY\"\\n\
                KEY_PROVINCE=\"$KEY_PROVINCE\"\\n\
                KEY_CITY=\"$KEY_CITY\"\\n\
                KEY_ORG=\"$KEY_ORG\"\\n\
                KEY_EMAIL=\"$KEY_EMAIL\"\\n\
                KEY_OU=\"$KEY_OU\"\\n\
                KEY_NAME=\"$KEY_NAME\"\\n\
                \\n\
                \\e[1;35mПроверьте значения.\\e[0m\\n\
                \\n\
                Вы подтверждаете, что все переменные имею желаемые значения? [y|N]: "
                read -r -n 1 answer
                if [[ "$answer" == "y" ]]; then
                    accepted=1
                    work_path=$( pwd | sed 's%\/%\\\/%g')
                    sed -i "{/KEY_COUNTRY/s/\".*\"/\"$key_country\"/;\
                    /KEY_PROVINCE/s/\".*\"/\"$key_province\"/;\
                    /KEY_CITY/s/\".*\"/\"$key_city\"/;\
                    /KEY_ORG/s/\".*\"/\"$key_org\"/;\
                    /KEY_EMAIL/s/\".*\"/\"$key_email\"/;\
                    /KEY_OU/s/\".*\"/\"$key_ou\"/;\
                    /KEY_NAME/s/\".*\"/\"$key_name\"/;\
                    /EASY_RSA/s/\".*\"/\"$work_path\"/}" vars
                    sed -i "/KEY_CONFIG/s/=.*$/=\"\$EASY_RSA\\/openssl-1.0.0.cnf\"/" vars
                    sed -i '/^FIRS_RUN_FLAG/s/0/1/' "$0"
                    sed -ri '/^#|^echo|^$/d' vars
                else
                    f_clr
                fi
            done

            cd "$EASY_RSA" || exit 100
            sed -i "/KEY_CONFIG/s/=.*$/=\"\$EASY_RSA\\/openssl-1.0.0.cnf\"/" vars
            sed -i '/^FIRS_RUN_FLAG/s/0/1/' "$0"
            # sed -ri '/^#|^echo|^$/d' vars
            # ./clean-all
            . vars
            ./pkitool --initca --pass
            # ./pkitool --server "$KEY_NAME"
            # $OPENSSL dhparam -out "${KEY_DIR}"/dh${KEY_SIZE}.pem ${KEY_SIZE}
            # openvpn --genkey --secret keys/ta.key
            # [ -d "/etc/openvpn/keys" ] || sudo mkdir -p /etc/openvpn/{keys,ccd}
            # sudo cp keys/{ca.key,ca.crt,"$KEY_NAME".key,"$KEY_NAME".crt,dh${KEY_SIZE}.pem,ta.key}
            ;;

        *)
            f_clr
            echo -en "Данная настройка необходима для правильной конфигурации OpenVPN.\\n\
Пожалуйста запустите скрип настройки еще раз.\\n\
Настройка значений производится только один раз, при первом запуске." && echo
            exit 0
            ;;
    esac
}

FIRS_RUN_FLAG=0

[ $FIRS_RUN_FLAG -eq 0 ] && first_run


