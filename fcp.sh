#!/usr/bin/env bash

# GLOBAL VARIABLES
VERSION=0.1
MCHANGE=/tmp/must_change.zmprov
SPASSF=/tmp/settmppass.zmprov
ACCTFILE=/tmp/accs.list

if [ "$(whoami)" != "zimbra" ]; then
        echo "Script must be run as user: zimbra"
        exit 255
fi

usage() {
    echo "Usage: $(basename "$0") [-vseh] [-p P4\$s ] [-c UID]"
    echo "OPTIONS:"
    echo "    -h Show this help"
    echo "    -v Show version"
    echo "    -s Show current COS and their IDs"
    echo "    -e Set expire password to all accounts from COS ID"
    echo "    -c Specify the COS ID"
    echo "    -p Specify temporal password (default autogenerate)"
}

showCos() {
    # List all COS
    /opt/zimbra/bin/zmprov gac > /tmp/cos.zmprov
    # Get all COS IDS
    while read cos;
    do
        echo -e "gc ${cos} zimbraId";
    done < /tmp/cos.zmprov| zmprov |awk '(/name/ && ORS=" => ") || (/zimbraId:/ && ORS=RS)'
}
setExpire() {
    pass=$1
    echo "Cleaning last run."
    rm -rf /tmp/*.zmprov
    echo "Generating accounts file..."
    /opt/zimbra/bin/zmprov sa "(&(|(zimbraCOSId=${COS})))" > ${ACCTFILE}
    echo "Generating accounts file successfuly"
    echo "Generating files operations.."
    while IFS= read -r line; do echo -ne "ma ${line} zimbraPasswordMustChange TRUE\n" >> ${MCHANGE}; done < ${ACCTFILE}
    while IFS= read -r line; do echo -ne "sp ${line} ${pass}\n" >> ${SPASSF}; done < ${ACCTFILE}
    echo "Generating files operations finished."
    echo "Executing files operations to accounts in ${COS}."
    echo "Setting temporal password ${pass}"
    /opt/zimbra/bin/zmprov < ${SPASSF}
    if [ $? -eq 0 ]; then
        echo "Set temporal password to accounts in cos ${COS} successfuly."
        exit 0
    else
        echo "Set temporal password to accounts in cos ${COS} successfuly."
        exit $?
    fi
    echo "Setting expire password"
    /opt/zimbra/bin/zmprov < ${MCHANGE}
    if [ $? -eq 0 ]; then
        echo "Set password expire to accounts in cos ${COS} successfuly."
        exit 0
    else
        echo "Set password expire to accounts in cos ${COS} successfuly."
        exit $?
    fi
}
# Procesod e argumentos
while getopts ":c:p: hevs" opt; do
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
    p)  setPassword=${OPTARG}
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

if [ -v expireAcc ] && [ -v COS ] && [ -v setPassword ]
then
    setExpire ${setPassword}
elif [ -v expireAcc ] && [ -v COS ]
then
    setExpire $(/usr/bin/pwgen 5 1)
elif [ -v expireAcc ] || [ -v COS ]
then
    echo "-e and -c options are mutually inclusive"
    usage
fi
