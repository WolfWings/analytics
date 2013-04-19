#!/bin/bash
export NOVA_SERVICE_NAME=cloudServersOpenStack
export NOVA_URL=https://identity.api.rackspacecloud.com/v2.0/ 
export NOVA_VERSION=1.1
export NOVA_RAX_AUTH=1
DIALOG=${DIALOG=dialog}
${DIALOG} \
	--backtitle "Rackspace Metadata Updater" \
	--title "API Information" \
	--no-mouse \
	--form "Account Details" 0 0 3 \
		"Account ID:" 1 2 "" 1 14 32 10 \
		"  Username:" 2 2 "" 2 14 32  0 \
		"   API Key:" 3 2 "" 3 14 32  0 \
	--and-widget \
	--menu "Region/Datacenter" 0 0 3 \
		"DFW" "Dallas (US)" \
		"ORD" "Chicago (US)" \
		"LON" "London (UK)" \
	2>>/tmp/chri5631.metadata.$$
if [ $? -ne 0 ]; then clear; exit; fi
exec 4<>/tmp/chri5631.metadata.$$

export NOVA_PROJECT_ID
read -u 4 NOVA_PROJECT_ID

export NOVA_USERNAME
read -u 4 NOVA_USERNAME

export NOVA_API_KEY
read -u 4 NOVA_API_KEY

export NOVA_REGION_NAME
read -u 4 NOVA_REGION_NAME

clear
echo "Finished setting up NOVA."
echo "Press Ctrl+D or type 'exit' to leave the sub-environment."
exec ${SHELL}
