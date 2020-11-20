#!/bin/bash

function exit_on_error {
        last="$#"
        code=1
        if [ $# -gt 0 ]; then
                usr_code=$(eval echo "\${$last}")
                if [[ "$usr_code" =~ ^[0-9]+$ ]]; then
                        last=$(( $# - 1 ))
                        code=$usr_code
                fi
        fi
        if [ -z $code ]; then
                return
        fi
        msg="[ERROR] line $(caller)"
        if [ $last -gt -1 ]; then
                msg="$msg: ${@:1:$last}"
        fi
        echo -e "\e[91m$msg\e[0m"
        exit $code
}
