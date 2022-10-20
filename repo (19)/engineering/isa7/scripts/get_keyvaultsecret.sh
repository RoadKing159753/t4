#!/bin/bash
name=$1
if [[ -n "$name" ]]; then
        token=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true | awk -F"[{,\":}]" '{print $6}')
        keyvaulturl="https://mgt-sct-akv-mgt-pri-kv.vault.azure.net/secrets"
        curl -s ${keyvaulturl}/vtxadmin?api-version=2016-10-01 -H "Authorization: Bearer ${token}" | awk -F"[{,\":}]" '{print $6}'
else
        echo "argument error"
fi