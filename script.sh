#!/usr/bin/env bash

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
# start root user checking

if [ $(id -u) -ne 0 ]; then
    echo "Please use sudo or run the script as root."
    exit 1
fi

# end root user checking
################################################################################################
# start set variables

command_args=$*
version="1.0"
tool_name="srv_dns"
job="started"
priority="info"
logs_directory="/var/log/srv_dns/"
backup_directory="/var/backup/srv_dns/"
uid_execution=$(id -u)

# end set variables
################################################################################################
# start definition functions

function short_help() {
    echo "$(echo $0): usage: command [-os <os>] [-ct <container>] [--help :show Full help] ...";
}

function full_help() {
    echo "";
    echo -e "\e[1;34mDESCRIPTION: \e[0m";
    echo "Script to help in the creation of DNS Servers.";
    echo "";
    echo -e "\e[1;34mUSAGE: \e[0m";
    echo "  command [OPTIONS] OBJECT ...";
    echo "";
    echo -e "\e[1;34mOPTIONS: \e[0m";
    echo "  -os, --operational-system <os>";
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

function show_version() {
    echo "version: $version"
}

function show_change_directories() {
    echo "logs:     $logs_directory"
    echo "backups:  $backup_directory"
}

function logger() {
    if [ -z "$*" ] || [ -z "$job" ] || [ -z "$priority" ]; then
        echo "error: log not informed correctly"
    else
        if [ -d "$logs_directory" ]; then
            #echo "logs directory already exist."
            if [ -e "$logs_directory/$tool_name.log" ]; then
                #echo "log file already exist."
                echo "$(date --rfc-3339='s') $(hostname) $(dnsdomainname) $0[$PPID]: $job: $priority: $*" >> "$logs_directory/$tool_name.log"
            else
                echo "creating file $logs_directory/$tool_name.log to logs registry."
                touch "$logs_directory/$tool_name.log"
            fi
        else
            echo "creating directory $logs_directory to log registry."
            mkdir -p "$logs_directory"
        fi
    fi
    
}

function read_cli_args() {
    num_arg_errors=0
    while [ -n "$1" ]; do
        if [ "$1" == "-h" ]; then
            short_help;
            exit 0;
        elif [ "$1" == "-H" ] || [ "$1" == "--help" ]; then
            full_help;
            exit 0;
        fi
        case $1 in
            ( "-os"|"--operational-system" )
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
            ( "-cd"|"--change-directories" )
                show_change_directories
                exit 0
                ;;
            ( "-v"|"--version" )
                show_version
                exit 0
                ;;
            ( "-h" )
                short_help
                exit 0
                ;;
            ( "-H"|"--help" )
                full_help
                exit 0
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

read_cli_args $command_args ;

# end argument reading
################################################################################################

logger
