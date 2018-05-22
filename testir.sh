#!/bin/bash

# # Рандом по условию
# while [ "${s:-0}" -ne 1 ];do e=$RANDOM;if echo $e | grep -qE "^[1-9]{$1}$"; then [ $e -lt 24 ] && s=1 && echo $e;fi;done
# # Текущий локальный адрес
# ip addr | grep -E "inet.*global.* e\\w+$" | awk '{print $2}' | sed 's/\/.*$//'
# # Текущий локальный интерфейс
# ip addr | grep -E "inet.*global.* e\\w+$" | awk '{print $7}'


while [ "${s:-0}" -ne 1 ];do
    e=$(( RANDOM % 253 ))
    if [ $e -gt 10 ] ;then
        [ "$(( e / 8 * 8 ))" -eq $e ] && s=1 && echo $e
    fi
done

# while [ "${s:-0}" -ne 1 ];do e=$RANDOM; if echo $e | grep -qE "^[1-9]{3}$"; then if [ $e -ge 192 ] && [ $e -le 223 ];then [ "$(( e / 8 * 8 ))" -eq $e ] && s=1 && echo $e;fi;fi;done;unset s e

