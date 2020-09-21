#!/usr/bin/env bash

# GLOBAL VARIABLES
VERSION=0.1
FILETMP=/tmp/must_change.zmprov

if [ "$(whoami)" != "zimbra" ]; then
        echo "Script must be run as user: zimbra"
        exit 255
fi

usage() {
    echo "Usage: $(basename "$0") [-vseh] [-c UID]"
    echo "OPTIONS:"
    echo "    -h Show this help"
    echo "    -v Show version"
    echo "    -s Show current COS and their IDs"
    echo "    -e Set expire password to all accounts from COS ID"
    echo "    -c Specify the COS ID"
}

showCos() {
    for cos in $(zmprov gac); do
        echo -ne "${cos}: "
        /opt/zimbra/bin/zmprov gc ${cos} zimbraId | grep -oE "\w{8}\-(\w{4}\-){3}\w{12}"
    done
}
setExpire() {
    echo "Cleaning last run."
    if [ -f "${FILETMP}" ]; then
        rm -rf ${FILETMP}
    fi
    echo "Generating file operations.."
    for account in $(/opt/zimbra/bin/zmprov sa "(&(|(zimbraCOSId=${COS})))"); do
        echo -ne "ma ${account} zimbraPasswordMustChange TRUE\n" >${FILETMP}
    done
    echo "Generating file operations finished."
    echo "Executing file oprations to accounts in ${COS}"
    /opt/zimbra/bin/zmprov <${FILETMP}
    if [ $? -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}
# Procesod e argumentos
while getopts ":c: hevs" opt; do
    case ${opt} in
    v)
        echo "Version ${VERSION}"
        ;;
    s)
        showCos
        ;;
    e)
        expireAcc=1
        ;;
    c)
        COS=${OPTARG}
        ;;
    h)
        usage
        ;;
    \?)
        echo "Opcion invalida -${OPTARG}"
        usage
        exit 1
        ;;
    :)
        echo "Opcion -${OPTARG} requiere un argumento"
        exit 1
        ;;
    esac
done

if [ ${OPTIND} -eq 1 ];
then
    echo "No options were passed"
    usage
fi

shift $((OPTIND - 1))

if [ -v expireAcc ] && [ -v COS ]
then
    setExpire
elif [ -v expireAcc ] || [ -v COS ]
then
    echo "-e and -c options are mutually inclusive"
    usage
fi
