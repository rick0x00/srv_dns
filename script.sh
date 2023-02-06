#!/usr/bin/env bash

commandargs=$*

# ============================================================ #
# Created date: 05 fev 2023                                    #
# Created by: Henrique Silva rick.0x00@gmail.com               #
# Name: srv_dns                                                #
# Description: Script to help in the creation of DNS servers   #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_dns     #
# Remote repository 2: https://gitlab.com/rick0x00/srv_dns     #
# ============================================================ #

################################################################################################
# start definition functions

function shorthelp() {
    echo "$(echo $0): usage: command [-os <os>] [-ct <container>] [--help :show Full help] ...";
}

function fullhelp() {
    echo "";
    echo -e "\e[1;34mDESCRIPTION: \e[0m";
    echo "Script to help in the creation of DNS Servers.";
    echo "";
    echo -e "\e[1;34mUSAGE: \e[0m";
    echo "  command [OPTIONS] OBJECT ...";
    echo "";
    echo -e "\e[1;34mOPTIONS: \e[0m";
    echo "  -os, --os <os>";
    echo "      Operational System.";
    echo "      [default: debian] [possible values: debian]";
    echo "  -ct, --container-technology <container>"
    echo "      Container Technology.";
    echo "      [default: off|no-ct] [possible values: off|no-ct]";
    echo "  -dns, --dns <dns>"
    echo "      DNS Software solution.";
    echo "      [default: bind] [possible values: bind]";
    echo "  -cd, --change-directories"
    echo "      Show directories to be changed/maked by the tool.";
    echo "  -v, --version"
    echo "      Report version of tool.";
    echo "  -h";
    echo "      Show short help message."
    echo "  -H, --help"
    echo "      Show Full Help message.";
    echo "";
    echo -e "\e[1;34mEXAMPLES: \e[0m";
    echo "  command -os debian --dns bind";
    echo "";
}

function readcliargs() {
    num_arg_errors=0
    while [ -n "$1" ]; do
        if [ "$1" == "-h" ]; then
            shorthelp;
            exit 0;
        elif [ "$1" == "-H" ] || [ "$1" == "--help" ]; then
            fullhelp;
            exit 0;
        fi
        case $1 in
            ( "-os"|"--os" )
                if [ -n "$2" ] && [[ "$2" != -* ]]; then
                    case $2 in
                        ( [Dd]ebian | DEBIAN )
                            echo "os system: $2"
                            shift
                            ;;
                        ( * )
                            echo 'error: unrecognized "'$2'" operational system.'
                            num_arg_errors=$(($num_arg_errors+1))
                            ;;
                    esac
                else
                    echo 'error: operational system not defined'
                    num_arg_errors=$(($num_arg_errors+1));
                fi
                ;;
            ( "-ct"|"--container-technology" )
                if [ -n "$2" ] && [[ "$2" != -* ]]; then
                    case $2 in
                        ( "off"|"no-ct" )
                            echo "Container technology: $2"
                            shift
                            
                            ;;
                        ( * )
                            echo 'error: unrecognized "'$2'" container technology option'
                            num_arg_errors=$(($num_arg_errors+1))
                            ;;
                    esac
                else
                    echo 'error: Container technology not defined'
                    num_arg_errors=$(($num_arg_errors+1));
                fi
                ;;
            ( "-dns"|"--dns" )
                if [ -n "$2" ] && [[ "$2" != -* ]]; then
                    case $2 in
                        ( [bB]ind | "BIND" )
                            echo "dns software: $2"
                            shift
                            ;;
                        ( * )
                            echo 'error: unrecognized "'$2'" DNS software option'
                            num_arg_errors=$(($num_arg_errors+1))
                            ;;
                    esac
                else
                    echo 'error: dns software not defined'
                    num_arg_errors=$(($num_arg_errors+1));
                fi
                ;;
            ( * )
                echo "error: unknown option: $1"
                num_arg_errors=$(($num_arg_errors+1));
            ;;
        esac
        shift
    done
    if [ $num_arg_errors != 0 ]; then
        echo "error: $num_arg_errors invalid arguments"    
    fi
}

# end definition functions
################################################################################################
# start argument reading

readcliargs $commandargs ;

# end argument reading
################################################################################################