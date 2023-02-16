#!/usr/bin/env bash

function credits() {
echo "
# ============================================================ #
# Tool Created date: 05 fev 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: srv_dns                                           #
# Description: Script to help in the creation of DNS servers   #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_dns     #
# Remote repository 2: https://gitlab.com/rick0x00/srv_dns     #
# ============================================================ #
"
}

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
logs_directory="/var/log/srv_dns/"
backup_directory="/var/backup/srv_dns/"
uid_execution=$(id -u)


division_equal_line="================================================================================"
division_short_equal_line="========================================"

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
    echo "  -clp, --changelog-preview"
    echo "      Show changelog preview to be changed/maked by the tool.";
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

function show_changelog-preview() {
    echo "$division_short_equal_line"
    echo "the following directory will be created"
    echo "logs:     $logs_directory"
    echo "backups:  $backup_directory"
    echo ""
    echo "the following files will be created"
    echo "logs:     $logs_directory/execution.log"
    echo "          $logs_directory/summary.log"
    echo "$division_short_equal_line"
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
            ( "-clp"|"--changelog-preview" )
                show_changelog-preview
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
        exit 1;    
    fi
}

function logger() {
    # logger function
    # exemple to use: logger -task 'value task' --priority 'value priority' -msg "log message"
    if [ -n "$1" ]; then
    #echo "Log information specified"
        while [ -n "$1" ]; do
            #echo "validating log values"
            case $1 in
                ( "-task"|"--task" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering log parameter: task=$2"
                        task="$2"
                        shift
                    else
                        echo "error: log parameter incorrect: task=$2"
                    fi
                ;;
                ( "-priority"|"--priority" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering log parameter: priority=$2"
                        priority="$2"
                        shift
                    else
                        echo "error: log parameter incorrect: priority=$2"
                    fi
                ;;
                ( "-msg"|"--msg"|"-message"|"--message" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering log parameter: message=$2"
                        log_msg="$2"
                        shift
                    else
                        echo "error: log parameter incorrect: message=$2"
                    fi
                ;;
                ( "-show"|"--show" )
                    #echo "set show log parameter"
                    show_msg="1"
                ;;
                ( * )
                    echo "unknown parameter to log: $1"
                    unrecognized_parameters="$1 $unrecognized_parameters"
                ;;
            esac
            shift
        done
        if [  -n "$unrecognized_parameters" ] || [ -z "$log_msg" ] || [ -z "$task" ] || [ -z "$priority" ]; then
        echo "error: log not informed correctly"
        echo "task: $task"
        echo "priority: $priority"
        echo "message: $log_msg"
            if [ -n "$unrecognized_parameters" ]; then
                echo "unrecognized parameters: $unrecognized_parameters"
            fi
        else
            if [[  "$priority" == "emerg"||"alert"||"crit"||"err"||"warn"||"notice"||"debug"||"info" ]]; then
                #echo "priority: value is valid: $priority"
                while [ True ]; do
                    if [ -d "$logs_directory" ]; then
                        #echo "logs directory already exist."
                        if [ -e "$logs_directory/execution.log" ]; then
                            #echo "log file already exist."
                            #echo "writing log"
                            echo "$(date --rfc-3339='s') $(hostname) $0[$PPID]: $task: $priority: $log_msg" >> "$logs_directory/execution.log"
                            if [ "$show_msg" == "1" ]; then
                                #echo "show log message"
                                echo "$log_msg"
                            fi
                            break
                        else
                            echo "creating file $logs_directory/execution.log to logs registry."
                            touch "$logs_directory/execution.log"
                            echo "$(date --rfc-3339='s') $(hostname) $0[$PPID]: rick0x00 script executed" >> /var/log/syslog
                        fi
                    else
                        echo "creating directory $logs_directory to log registry."
                        mkdir -p "$logs_directory"
                    fi
                done
            else
                echo "Priority value '$priority' is not supported"
            fi
        fi
    else
        echo "no log information specified"
    fi 
}

function task_bar() {
    # task bar function
    # example to use: task_bar -at 'actual task number' --tt 'total number of tasks' -task 'short task description' -slb '1|0' -sla '1|0' -cl '1|0'
    if [ -n "$1" ]; then
        #echo "task bar information available"
        while [ -n "$1" ]; do
            #echo "validating task bar values"
            case "$1" in
                ( "-at"|"--at"|"-actual"|"--actual"|"-actual-task"|"--actual-task" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: actual-task=$2"
                        actual_task=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: actual-task=$2"
                    fi
                ;;
                ( "-tt"|"--tt"|"-total"|"--total"|"-total-tasks"|"--total-tasks" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: total-tasks=$2"
                        total_tasks=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: total-tasks=$2"
                    fi
                ;;
                ( "-t"|"--t"|"-task"|"--task"|"-task-msg"|"--task-msg"|"-msg"|"--msg"  )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: task-msg=$2"
                        task_msg=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: task-msg=$2"
                    fi
                ;;
                ( "-slb"|"--slb"|"-shift-line-before"|"--shift-line-before" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: shift-line-before=$2"
                        shift_line_before=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: shift-line-before=$2"
                    fi
                ;;
                ( "-sla"|"--sla"|"-shift-line-after"|"--shift-line-after" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: shift-line-after=$2"
                        shift_line_after=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: shift-line-after=$2"
                    fi
                ;;
                ( "-cl"|"--cl"|"-clear-line"|"--clear-line" )
                    if [ -n "$2" ] && [[ "$2" != -* ]]; then
                        #echo "registering task parameters: clear-line=$2"
                        clear_line=$2
                        shift
                    else
                        echo "Error: task parameter incorrect: clear-line=$2"
                    fi
                ;;
                ( * )
                    echo "unknown parameter to task bar: $1"
                    unrecognized_parameters="$1 $unrecognized_parameters"
                ;;
            esac
            shift
        done
    else
        echo "no task bar information available"
    fi
    if [  -n "$unrecognized_parameters" ] || [ -z "$task_msg" ] || [ -z "$total_tasks" ] || [ -z "$actual_task" ] ; then
        echo "error: log not informed correctly"
        echo "task msg: $task_msg"
        echo "total tasks: $total_tasks"
        echo "actual task: $actual_task"
        if [ -n "$unrecognized_parameters" ]; then
            echo "unrecognized parameters: $unrecognized_parameters"
        fi
    else
        yx_stty=$(stty size)
        width_tty=${yx_stty#* }
        if [ -n "$shift_line_before" ]; then
            if [ "$shift_line_before" == "1" ]; then
                echo -en "\n"
            elif [ "$shift_line_before" == "0" ]; then
                echo -en "\r"
            fi
        fi
        if [ -z "$clear_line" ]; then
            clear_line=0
        fi
        if [ "$clear_line" == "1" ]; then
            for (( c=1; c<=$width_tty; c++ )); do echo -en " " ; done
        else
            echo -en "\033[1m"
            echo -en "TASK "
            echo -en "[$actual_task/$total_tasks]: "
            echo -en "\033[0m"
            echo -en "$task_msg"
        fi
        if [ -n "$shift_line_after" ]; then
            if [ "$shift_line_after" == "1" ]; then
                echo -en "\n"
            elif [ "$shift_line_after" == "0" ]; then
                echo -en "\r"
            fi
        fi
    fi
}

function progress_bar() {
    percent=$1
    shift_line=$2
    clear_line_bar=$3
    yx_stty=$(stty size)
    width_tty=${yx_stty#* }
    width_bar=$(((width_tty-15)-2))
    bar_percent=$((($percent*$width_bar)/100))
    complement_bar_percent=$(($width_bar-$bar_percent))
    if [ "$shift_line" == "1" ]; then
        echo -en "\n"
    else
        echo -en "\r"
    fi
    if [ "$clear_line_bar" == "1" ]; then
        for (( c=1; c<=$width_tty; c++ )); do echo -en " " ; done
    else
        for (( c=1; c<=$width_tty; c++ )); do echo -en " " ; done
        echo -en "\r"
        echo -en "\033[1m"
        echo -en "PROGRESS "
        echo -en "\033[0m"
        echo -en "["
        echo -en "\033[30m"
        echo -en "\033[46m"
        for (( c=1; c<=$bar_percent; c++ )); do echo -en "#" ; done
        echo -en "\033[0m"
        echo -en "\033[1m"
        #echo -en "($percent%)"
        printf '(%4s)' "$percent%"
        echo -en "\033[0m"
        for (( c=1; c<=$complement_bar_percent; c++ )); do echo -en "." ; done
        echo -en "]"
    fi
}

function full_progress_bar() {
    actual=$1
    total=$2
    msg=$3
    update_progress=$4
    clear=$5
    if [[ "$update_progress" == "1" ]]; then 
        echo -en "\033[1A"
        echo -en "\r"   
    else
        echo -en "\n"
    fi 
    percent="$((($actual*100)/$total))"
    progress_bar $percent 0 $clear
    task_bar $actual $total $msg 1 $clear
}


# end definition functions
################################################################################################
# start argument reading

read_cli_args $command_args ;

# end argument reading
################################################################################################

credits > $logs_directory/summary.log;
credits;
logger -task "script" --priority "info" -msg "=============== script started ===============" --show;
logger -task "install" --priority "alert" -msg "teste de mensagem" --show;
 