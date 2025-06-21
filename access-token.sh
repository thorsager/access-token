#!/usr/bin/env bash
# Script to retrieve access-tokens
#  - https://github.com/thorsager/access-token

[ -r .env ] && source .env
usage() {
    echo "$(basename "$0") [-d|-H|-R-t] [-i <issuer> -r <realm> -u <user> -p <password> -c <client_id> -s <client_secret> -g <grant_type> -o <scope>] " 1>&2
    echo 1>&2
    echo "Options:" 1>&2
    echo "  -d  -- Dump decoded version of the retrieved token" 1>&2
    echo "  -H  -- Generate http Authorization Header" 1>&2
    echo "  -R  -- Dump the _raw_ token as it is retrieved" 1>&2
    echo 1>&2
    echo "The following env-vars can be used:" 1>&2
    echo " - ISSUER" 1>&2
    echo " - CLIENT_ID" 1>&2
    echo " - CLIENT_SECRET" 1>&2
    echo " - USERNAME" 1>&2
    echo " - PASSWORD" 1>&2
    echo " - GRAND_TYPE (can be either 'password' or 'client_credentials')" 1>&2
    echo "This script will also source .env in CWD" 1>&2
    exit 1
}


base64decode() {
    local mod
    local encoded
    mod=$((${#1}%4))
    if [ $mod -eq 1 ]; then
        encoded="$1="
    elif [ $mod -gt 1 ]; then 
        encoded="$1=="
    else 
        encoded="$1"
    fi
    echo "$encoded" | base64 -d
}

dumptoken() {
    echo "---"
    echo "$1-Header:"
    p1=$(echo -n "$2" | cut -d '.' -f1)
    base64decode "$p1" | jq

    echo "$1-Payload:"
    p2=$(echo -n "$2" | cut -d '.' -f2)
    base64decode "$p2" | jq
}

while getopts ":dHRr:i:u:p:c:s:g:o:" OPT; do
    case "$OPT" in 
        d)
            DECONSTRUCT=true
            ;;
        H)
            HEADER=true
            ;;
        r)
            REALM=${OPTARG}
            ;;
        R)
            RAW=true
            ;;
        i)
            ISSUER=${OPTARG}
            ;;
        s)
            CLIENT_SECRET=${OPTARG}
            ;;
        c)
            CLIENT_ID=${OPTARG}
            ;;
        u)
            USERNAME=${OPTARG}
            ;;
        p)
            PASSWORD=${OPTARG}
            ;;
        g)  
            GRANT_TYPE=${OPTARG}
            ;;
        o)  
            SCOPE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -n "${DECONSTRUCT}" ] && [ -n "${HEADER}" ]; then 
    echo "!cannot both deconstruct token and output header" 1>&2
    exit 2
fi 


if [ -z "${REALM}" ]; then 
    echo "!no REALM" 1>&2
    exit 2
fi

if [ -z "${ISSUER}" ]; then 
    echo "!no ISSUER" 1>&2
    exit 2
fi

if [ -z "${CLIENT_ID}" ]; then 
    echo "!no CLIENT_ID" >&2
    exit 2
fi

if [ -z "${GRANT_TYPE}" ]; then
    GRANT_TYPE=password
fi

if [ -z "${SCOPE}" ]; then
    SCOPE="openid profile email"
fi

if [ -z "${CLIENT_SECRET}" ] && [ "${GRANT_TYPE}" = "client_credentials" ]; then 
    echo "!no CLIENT_SECRET" >&2
    exit 2
fi

if [ -z "${USERNAME}" ] && [ "${GRANT_TYPE}" = "password" ]; then 
    echo "!no USERNAME" >&2
    exit 2
fi

if [ -z "${PASSWORD}" ] && [ "${GRANT_TYPE}" = "password" ]; then 
    echo "!no PASSWORD" >&2
    exit 2
fi


ISSUER_URL="${ISSUER}/realms/${REALM}//protocol/openid-connect/token"
if ! result=$(curl -ks --fail-with-body -L \
    -d client_id="${CLIENT_ID}" \
    -d client_secret="${CLIENT_SECRET}" \
    -d username="${USERNAME}" \
    -d password="${PASSWORD}" \
    -d grant_type="${GRANT_TYPE}" \
    -d scope="${SCOPE}" \
    "${ISSUER_URL}"); then 

    echo "Error!" >&2
    echo "$(echo "$result" | jq -r '.error'): $(echo "$result" | jq -r '.error_description')" >&2
    exit 1
fi


ACCESS_TOKEN=$(echo "$result" | jq -r .access_token)


if [ -n "$GET_RPT" ]; then
    rpt_result=$(getRPTToken)
    echo "$rpt_result"
    exit
fi


if [ -n "${DECONSTRUCT}" ]; then 
    dumptoken "AccessToken" "$ACCESS_TOKEN"
    ID_TOKEN=$(echo "$result" | jq -r .id_token)
    dumptoken "IdToken" "$ID_TOKEN"
    REFRESH_TOKEN=$(echo "$result" | jq -r .refresh_token)
    dumptoken "RefreshToken" "$REFRESH_TOKEN"
    exit 0
fi 

if [ -n "${HEADER}" ]; then 
    printf "Authorization: Bearer %s" "$ACCESS_TOKEN"
    exit 0
fi

if [ -n "${RAW}" ]; then 
    echo "$result" | jq
    exit 0
fi

echo "$ACCESS_TOKEN"

