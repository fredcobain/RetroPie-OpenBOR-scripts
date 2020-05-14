#!/bin/bash
# User menu for OpenBOR configuration tool
# This version is a massive rewrite of older version.
# It offers much more configuration possibilities with dynamic setup
#
# Place file to /opt/retropie/configs/all/runcommand-menu
# Access with USER Menu in runcommand.... Press just a button during greybox is visible
#
# coded by cyperghost
# For https://retropie.org.uk/

###### --------------------- INIT ---------------------
readonly MASTERCONF_DIR="/home/pi/RetroPie/roms/ports/openbor"
readonly KEYCONF_DIR="/opt/retropie/configs/ports/openbor/Saves"
readonly JOYPAD_GITHUB="http://raw.githubusercontent.com/fredcobain/RetroPie-OpenBOR-scripts/master/joypad/joypadlist.txt"
######
readonly BACKTITLE=" cyperghosts OpenBOR easy Joypad config "
###### --------------------- INIT ---------------------

BOR_file="$(basename "$3")"
emulator="${1,,}"
BOR_cfg="$KEYCONF_DIR/$BOR_file.cfg"
config_key="${2,,}"

###### --------------- Dialog Functions ---------------

# Show Infobox // $1 = Textmessage, $2 = Show Infobox for x seconds, $3 = Boxtitlemessage

function show_info() {
    dialog --title "$3" --backtitle "$BACKTITLE"  --infobox "$1" 0 0
    sleep "$2"; clear
}

# Show OK-Box // $1 = Textmessage, $2 = Boxtitlemessage

function show_msg() {
    dialog --title "$2" --backtitle "$BACKTITLE"  --msgbox "$1" 0 0
}

# Show yesnobox // $1 = Textmessage, $2 = Boxtitlemessage

function show_yesno() {
    dialog --title "$2" --backtitle "$BACKTITLE" --yesno "$1" 0 0
}

###### --------------- Dialog Functions ---------------




###### --------- Set config-default functions ---------

function get_file() {

    local git_address="$1"
    local git_filename="$(basename "$git_address")"
    local cfg_location="$2"
    local filename="$3"
    local array
    local cmd
    local check_connection=$(wget --spider "$git_address" 2>&1 | grep -c "404 Not Found")

    if [[ ! -d "$cfg_location" ]]; then
        show_info "Diretorio nao encontrado!\n\n$cfg_location\n\nFavor Corrigir!\n\nRetornando em 10 segundos!" "10" " Erro! Diretorio nao encontrado! "
        exit 1
    elif [[ ! -s "$cfg_location/$git_filename" && $check_connection -gt 0 ]]; then
        show_msg "Arquivo fonte nao encontrado! Arquivo \"$git_filename\" em \"$cfg_location\" nao encontrado em $git_address" " Erro! Arquivos nao encontrados! " 
        return
    elif [[ -s "$cfg_location/$git_filename" ]]; then
        show_yesno "The file $git_filename disponivel.\n\nPosso sobrescrever?" " Old $git_filename found! "
        [[ $? == 0 ]] && wget -q "$git_address" -O "$cfg_location/$git_filename"
    elif [[ $check_connection -gt 0 ]]; then
        show_info "Erro no servidor!\n\nRetornando....." "4" " Erro: Servidor! "
        return
    else
        wget -q "$git_address" -O "$cfg_location/$git_filename"
    fi

    while read -r; do
        array+=("$REPLY")
    done < "$cfg_location/$git_filename"

    # This snippet repairs wrong setted arrays!
    [[ $((${#array[@]}%2)) != 0 ]] && unset array[${#array[@]}-1]

    cmd=(dialog --backtitle "$BACKTITLE" \
                --title " Setup OpenBOR - Download dos Arquivos Pre Configurados "
                --ok-label " Selecionar " \
                --cancel-label " Voltar " \
                --no-tags --stdout \
                --menu "OpenBOR Addon: \"${BOR_file:0:-4}\"\n\nArquivos de configuracao serao baixados e salvos em:\n$cfg_location/$filename" 16 70 8)
    git_address=$("${cmd[@]}" "${array[@]}")
    [[ $? == 1 ]] && return

    check_connection=$(wget --spider "$git_address" 2>&1 | grep -c "404 Not Found")

    if [[ $check_connection -gt 0 ]]; then
        show_msg "Server reported: 404 Not Found\nFailed to download config file from:\n\n$git_address\n\nSorry for that...." " Error: Setup config file! "
        return
    elif [[ -s "$cfg_location/$filename" && "$filename" == "master.bor.cfg" ]]; then
        show_yesno "Config master ja existente!\nDeseja sobrescrever?" " Config master ja setada! "
        [[ $? == 1 ]] && return
    elif [[ -s "$cfg_location/$filename" ]]; then
        show_yesno "Config do jogo ja existente!\nDeseja sobrescrever?" " Config do jogo ja setada! "
        [[ $? == 1 ]] && return
    fi

    wget -q "$git_address" -O "$cfg_location/$filename"

    if [[ -s "$cfg_location/$filename" && "$filename" == "master.bor.cfg" ]]; then
         show_msg "Arquivo MASTER baixado! Salvo em:\n\n$cfg_location/$filename" " Parabens! Master file ok! "
    elif [[ -s "$cfg_location/$filename" ]]; then
        show_msg "Config file successfully downloaded! Setted file to:\n\n$BOR_cfg" " Parabens! Config file ok! "
    else
        show_msg "Erro no download a partir de:\n\n$git_address\n\nOr file contains zerofiles\n\nSorry for that...." " Error: Setup config file! "
    fi

}

###### --------- Set config-default functions ---------




###### ------------- Set array functions --------------

function remove_items() {

    local i; local ii

    for i in $@;do
        unset array[i*2-ii*2]
        unset array[i*2+1-ii*2]
        ((+ii))
    done
}

###### ------------- Set array functions --------------




    # 1. Check is emulator "openbor" running
    if [[ "$emulator" != "openbor" ]]; then
        show_info "Esse script funciona somente para o emulador \"openbor\"\n    not ${emulator^^}\nVoltando para o RUNCOMMAND...." "5" " Error! "
        exit 0
    fi

    # 2. Initiate Selection menu loop
    while true; do


        array=("0" "Iniciar OPENBOR" \
               "1" "MASTER config --> JOGO config" \
               "2" "JOGO config --> MASTER config" \
               "3" "Lista Github  --> MASTER config" \
               "4" "Lista Github  --> GAME config" \
               "5" "APAGAR configuracoes do GAME" \
               "6" "APAGAR configuracao MASTER" \
               "7" "Voltar para o RUNCOMMAND")

    # 3.Check config files and enable/disable array textes
        [[ ! -s $BOR_cfg && -s $MASTERCONF_DIR/master.bor.cfg ]] && remove_items 0 2 3 5
        [[ ! -s $MASTERCONF_DIR/master.bor.cfg && -s $BOR_cfg ]] && remove_items 1 4 6
        [[ ! -s $MASTERCONF_DIR/master.bor.cfg && ! -s $BOR_cfg  ]] && remove_items 0 1 2 5 6
        [[ -s $MASTERCONF_DIR/master.bor.cfg && -s $BOR_cfg  ]] && remove_items 3 4
        [[ -s $BOR_cfg && $config_key == "configscript" ]] && remove_items 0

        cmd=(dialog --backtitle "$BACKTITLE" \
                    --title " Setup OpenBOR - Beats of Rage Engine "
                    --ok-label " Select " \
                    --cancel-label " Cancel " \
                    --stdout \
                    --menu "OpenBOR Addon: \"${BOR_file:0:-4}\"\n\nConfig file: $BOR_cfg\nMaster file: $MASTERCONF_DIR/master.bor.cfg" 18 70 8)
        choices=$("${cmd[@]}" "${array[@]}")

            case $choices in
                0)  # Start Game via runcommand exit codes command
                    exit 2
                ;;

                1) # Copy Master config to Game config
                   cp -f "$MASTERCONF_DIR/master.bor.cfg" "$BOR_cfg"
                   show_info "Configurando: \"${BOR_file:0:-4}\"\n\nConfiguracao copiada de:\n\"$MASTERCONF_DIR/master.bor.cfg\"\n    para:\n\"$BOR_cfg\"\n\nAguarde!" "8" " Configurando ... "
                ;;

                2) # Copy Game config to Master config
                   cp -f "$BOR_cfg" "$MASTERCONF_DIR/master.bor.cfg" 
                   show_info "Configurando: \"${BOR_file:0:-4}\"\n\nConfiguracao copiada de:\n\"$BOR_cfg\"\n    para:\n\"$MASTERCONF_DIR/master.bor.cfg\"\n\nAguarde!" "8" " Configurando ... "
                ;;

                3) # Download Master config from github
                   get_file "$JOYPAD_GITHUB" "$MASTERCONF_DIR" "master.bor.cfg"
                ;;

                4) # Download Game config from github
                   get_file "$JOYPAD_GITHUB" "$KEYCONF_DIR" "$BOR_file.cfg"
                ;;

                5) # Delete current Game config
                   show_yesno "Configurando: \"${BOR_file:0:-4}\"\n\nArquivo de configuracao do jogo encontrado:\n\"$BOR_cfg\"\n\nApagar o arquivo de configuracao do jogo?" " Apagar: GAME config! "
                   [[ $? == 0 ]] && rm -f "$BOR_cfg"
                ;;

                6) # Delete current Master config
                   show_yesno "Configurando: \"${BOR_file:0:-4}\"\n\nArquivo MASTER encontrado:\n\"$MASTERCONF_DIR/master.bor.cfg\"\n\nApagar o arquivo de configuracao MASTER?" " Apagar: Master config! "
                   [[ $? == 0 ]] && rm -f "$MASTERCONF_DIR/master.bor.cfg"
                ;;

                7) # Exit to runcommand with exit code 0
                   exit 0
                ;;

                *) # Cancel Button
                   exit 0
                ;;
            esac

done
