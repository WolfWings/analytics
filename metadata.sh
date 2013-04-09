#!/bin/bash
while /bin/true; do
	if [ $0 != ${SHELL##*/} ]; then
		echo "This script must be called via the 'source' command,"
		echo "to allow it to setup the environmental variables for"
		echo "the 'nova' client properly."
		break
	fi
	export NOVA_SERVICE_NAME=cloudServersOpenStack
	export NOVA_URL=https://identity.api.rackspacecloud.com/v2.0/ 
	export NOVA_VERSION=1.1
	export NOVA_RAX_AUTH=1
	dialog \
	--backtitle "Rackspace Metadata Updater" \
	--title "API Information" \
	--no-mouse \
	--form "\nAccount Details" 0 0 4 \
	"  Username:" 1 2 "" 1 14 32  0 \
	" API Token:" 2 2 "" 2 14 32  0 \
	"Account ID:" 3 2 "" 3 14 32 10 \
	"    Region:" 4 2 "" 4 14 32  4 \
	2>/tmp/chri5631.metadata.$$
	exec 4<>/tmp/chri5631.metadata.$$
	export NOVA_USERNAME
	export NOVA_API_KEY
	export NOVA_PROJECT_ID
	export NOVA_REGION_NAME
	read -u 4 NOVA_USERNAME
	read -u 4 NOVA_API_KEY
	read -u 4 NOVA_PROJECT_ID
	read -u 4 NOVA_REGION_NAME
	break
done
