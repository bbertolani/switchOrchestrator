#!/bin/bash

# shellcheck source="${XDG_CONFIG_HOME:-$HOME/.config}/switchOrchestrator/swo"
# Set default configuration
SWITCH_IP=""
USER=""
HASH_PASS=""
TOKEN=""

# Overwrite default configs from noterc configuration file
SWITCH_CF_FOLDER="${XDG_CONFIG_HOME:-$HOME/.config}/switchOrchestrator"
SWITCH_CF_FILE="$SWITCH_CF_FOLDER/swo_config"
if [ -f "$SWITCH_CF_FILE" ]; then source "$SWITCH_CF_FILE"; fi
if [ -f "$SWITCH_CF_FOLDER/swo_$SWITCH_IP" ]; then TOKEN=$(cat $SWITCH_CF_FOLDER/swo_$SWITCH_IP); fi

SWITCH_ADR="http://"$SWITCH_IP":51088"

# Help
Help() {
    printf "############################################################
# Help                                                     #
############################################################
Switch Orchestrator
Usage: swo [<args>]
Arguments:
  -h | --help                         Display usage guide.
  -j | --job    <JOBNUMBER>           Search about a specific job.
switchOrchestrator loads configuration variables from:
    \$HOME/.config/switchOrchestrator/swo"
    exit 0
}

install() {
    exec mkdir $SWITCH_CF_FOLDER
}

auth() {
    echo $SWITCH_ADR
    JSON=$(curl -s POST $SWITCH_ADR/login -H 'Content-Type: application/json' -d '{"username": "'$USER'", "password": "'$HASH_PASS'"}')

    result=$(jq -r '.success' <<< $JSON)
    if [ "$result" == "false" ]; then
        echo "Login failed"
        exit 1
    fi
    TOKEN=$(jq -r '.token' <<< $JSON)
    SAVED_TOKEN=$SWITCH_CF_FOLDER/swo_$SWITCH_IP
    touch $SAVED_TOKEN
    truncate -s 0 $SAVED_TOKEN
    echo "$TOKEN" >> $SAVED_TOKEN
    echo "Login Sucessful | SWITCH: $SWITCH_IP"
    exit 0
}

searchJob() {
    JSON=$(curl -s --location --request GET "$SWITCH_ADR/api/v1/messages?type=info&message=$JOB_NUMBER&limit=100" -H 'Authorization: Bearer '$TOKEN)
    status=$(jq '.status' <<< $JSON)
    if [ "$status" == "success" ]; then
        echo "Search failed"
        exit 1
    fi
    messages=$(jq '.messages' <<< $JSON)
    echo $messages | jq '[.[] | {timestamp,flow,job,element,message}] | sort_by(.timestamp)' | jtbl
    exit 0
}

validateSearchJob() {
    if [ "$#" -ne 2 ]; then
        printf "Incorrect number of arguments.\n"
        printf "Usage: swo --job <JOBNUMBER>\n"
        exit 1
    fi
    JOB_NUMBER="$2"
    if [ -z "$JOB_NUMBER" ]; then
        printf "Expected additional argument <Job Number>.\n"
        exit 1
    fi
    searchJob $JOB_NUMBER
}

############################################################
# Main program                                             #
############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
if (($# > 0)); then
    while [[ $# -gt 0 ]]; do
        key="$1"
        case $key in
            -j | --job)
                validateSearchJob "$@"
            ;;
            -a | --auth)
                auth
                shift
            ;;
            -i | --install)
                install
            ;;
            -h | --help)
                Help
            ;;
            *)
                printf "Unknown Argument \"%s\"\n" "$1"
                printf "Use \"swo --help\" to see usage information.\n"
                exit 1
            ;;
        esac
    done
else
    #no arguments/options
    printf "\n
    Switch: $SWITCH_ADR
    Config: $SWITCH_CF_FILE
    Use \"swo --help\" to see usage information.\n"

fi