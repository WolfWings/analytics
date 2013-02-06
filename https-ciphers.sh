#!/bin/bash
if [ -z "${HOST}" ]; then
	echo "Please enter hostname to scan, or press enter to scan localhost:"
	read HOST
	echo "Please enter port to scan, or press enter for default HTTPS/443:"
	read PORT
fi

if [ -z "${HOST}" ]; then HOST=localhost; fi

if [ -z "${PORT}" ]; then PORT=443; fi

CIPHERS=`openssl ciphers`
VALID=":"
while [ -n "${CIPHERS}" ]; do
	echo -e -n "Attempt #`echo ${VALID} | awk '-F:' 'END { print NF - 1 }'`\r"
	PICK=`echo | openssl s_client -cipher ${CIPHERS} -connect ${HOST}:${PORT} 2> /dev/null | grep "Cipher    :" | cut --delim=":" -f 2`
	if [ -z "${PICK}" ]; then break; fi
	VALID="${VALID}:${PICK}"
	CIPHERS=`echo -n ${CIPHERS} | xargs -n 1 --delim=":" echo | grep -v ${PICK} | xargs echo | sed -e "s/ /:/g"`
done

BANNER="Supported ciphers for https://${HOST}"
if [ ${PORT} -ne 443 ]; then
	BANNER="${BANNER}:${PORT}"
fi
BANNER="${BANNER} are:\n\t"

echo -n ${VALID} |
cut --delim=":" -f 3- |
xargs --delim=":" echo -e "${BANNER}"
