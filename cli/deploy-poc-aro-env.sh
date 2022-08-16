

az login --service-principal -u $1 -p $2 --tenant $3

#!/bin/bash
################################################################################################## Initialize

####
#   UUID Function
####
# Generate a pseudo UUID
uuid()
{
    local N B T

    for (( N=0; N < 16; ++N ))
    do
        B=$(( $RANDOM%255 ))

        if (( N == 6 ))
        then
            printf '4%x' $(( B%15 ))
        elif (( N == 8 ))
        then
            local C='89ab'
            printf '%c%x' ${C:$(( $RANDOM%${#C} )):1} $(( B%15 ))
        else
            printf '%02x' $B
        fi

        for T in 3 5 7 9
        do
            if (( T == N ))
            then
                printf '-'
                break
            fi
        done
    done

    echo
}

[ "$0" == "$BASH_SOURCE" ] && uuid

####
#   END UUID Function
####
# Generate a pseudo UUID


if [ $# -gt 1 ]; then
    echo "Usage: $BASH_SOURCE <Custom Domain eg. aro.foo.com>"
    exit 1
fi

# Random string generator - don't change this.
RAND="$(echo $RANDOM | tr '[0-9]' '[a-z]')"
export RAND

# Customize these variables as you need for your cluster deployment
APIPRIVACY="Public"
export APIPRIVACY
INGRESSPRIVACY="Public"
export INGRESSPRIVACY
LOCATION="eastus2"
export LOCATION
VNET="10.151.0.0"
export VNET
WORKERS="3"
export WORKERS
PULLSECRETFILE="pull-secret.txt"
export PULLSECRETFILE

# Don't change these
BUILDDATE="$(date +%Y%m%d-%H%M%S)"
export BUILDDATE
CLUSTER="aro-$(whoami)-$RAND"
export CLUSTER
RESOURCEGROUP="$CLUSTER-$LOCATION"
export RESOURCEGROUP
SUBID="$(az account show -o json |jq -r '.id')"
export SUBID
VNET_NAME="$CLUSTER-vnet"
export VNET_NAME
VNET_OCTET1="$(echo $VNET | cut -f1 -d.)"
export VNET_OCTET1
VNET_OCTET2="$(echo $VNET | cut -f2 -d.)"
export VNET_OCTET2


################################################################################################## Infrastructure Provision


echo " "
echo "Building Azure Red Hat OpenShift 4"
echo "----------------------------------"

if [ -n "$(az provider show -n Microsoft.RedHatOpenShift -o table | grep -E '(Unregistered|NotRegistered)')" ]; then
    echo "The ARO resource provider has not been registered for your subscription $SUBID."
    echo -n "I will attempt to register the ARO RP now (this may take a few minutes)..."
    az provider register -n Microsoft.RedHatOpenShift --wait > /dev/null
    echo "done."
    echo -n "Verifying the ARO RP is registered..."
    if [ -n "$(az provider show -n Microsoft.RedHatOpenShift -o table | grep -E '(Unregistered|NotRegistered)')" ]; then
        echo "error! Unable to register the ARO RP. Please remediate this."
        exit 1
    fi
    echo "done."
fi

if [ -z "$(az extension list -o table |grep aro)" ]; then
    echo "The Azure CLI extension for ARO has not been installed."
    echo -n "I will attempt to register the extension now (this may take a few minutes)..."
    az extension add -n aro --index https://az.aroapp.io/stable > /dev/null
    echo "done."
    echo -n "Verifying the Azure CLI extension exists..."
    if [ -z "$(az extension list -o table |grep aro)" ]; then
        echo "error! Unable to add the Azure CLI extension for ARO. Please remediate this."
        exit 1
    fi
    echo "done."
fi

echo -n "Updating the Azure CLI extension to the latest version (if required)..."
az extension update -n aro --index https://az.aroapp.io/stable 

if [ $# -eq 1 ]; then
    CUSTOMDNS="--domain=$1"
    export CUSTOMDNS
    echo "You have specified a parameter for a custom domain: $1. I will configure ARO to use this domain."
    echo " "
fi

# Resource Group Creation
echo -n "Creating Resource Group..."
az group create -g "$RESOURCEGROUP" -l "$LOCATION" -o table >> /dev/null 
echo "done"

# VNet Creation
echo -n "Creating Virtual Network..."
az network vnet create -g "$RESOURCEGROUP" -n $VNET_NAME --address-prefixes $VNET/16 -o table > /dev/null
echo "done"

# Subnet Creation
echo -n "Creating 'Master' Subnet..."
az network vnet subnet create -g "$RESOURCEGROUP" --vnet-name $VNET_NAME -n "$CLUSTER-master" --address-prefixes "$VNET_OCTET1.$VNET_OCTET2.$(shuf -i 0-254 -n 1).0/24" --service-endpoints Microsoft.ContainerRegistry -o table > /dev/null
echo "done"
echo -n "Creating 'Worker' Subnet..."
az network vnet subnet create -g "$RESOURCEGROUP" --vnet-name $VNET_NAME -n "$CLUSTER-worker" --address-prefixes "$VNET_OCTET1.$VNET_OCTET2.$(shuf -i 0-254 -n 1).0/24" --service-endpoints Microsoft.ContainerRegistry -o table > /dev/null
echo "done"

# VNet & Subnet Configuration
echo -n "Disabling 'PrivateLinkServiceNetworkPolicies' in 'Master' Subnet..."
az network vnet subnet update -g "$RESOURCEGROUP" --vnet-name $VNET_NAME -n "$CLUSTER-master" --disable-private-link-service-network-policies true -o table > /dev/null
echo "done"
echo -n "Adding ARO RP Contributor access to VNET..."
az role assignment create --scope /subscriptions/$SUBID/resourceGroups/$RESOURCEGROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME --assignee f1dd0a37-89c6-4e07-bcd1-ffd3d43d8875 --role "Contributor" -o table > /dev/null
echo "done"

# Pull Secret
echo -n "Checking if pull-secret.txt exists..."
if [ -f "pull-secret.txt" ]; then
    echo "detected"
    echo -n "Removing extra characters from pull-secret.txt..."
    tr -d "\n\r" < pull-secret.txt >pull-secret.tmp
    rm -f pull-secret.txt
    mv pull-secret.tmp pull-secret.txt
    echo "done"
    PULLSECRET="--pull-secret=$(cat ./pull-secret/pull-secret.txt)"
    export PULLSECRET
else
    echo "not detected."
fi
echo " "

################################################################################################## Build ARO


# Build ARO
echo "==============================================================================================================================================================="
echo "Building Azure Red Hat OpenShift - this takes roughly 30-40 minutes. The time is now: $(date)..."
echo " "
echo "Executing: "
echo "az aro create -g $RESOURCEGROUP -n $CLUSTER --cluster-resource-group $RESOURCEGROUP-cluster --vnet=$VNET_NAME --master-subnet=$CLUSTER-master --worker-subnet=$CLUSTER-worker --ingress-visibility=$INGRESSPRIVACY --apiserver-visibility=$APIPRIVACY --pull-secret=$PULLSECRETFILE --worker-count=$WORKERS $CUSTOMDNS $PULLSECRET -o table"
echo " "
time az aro create -g "$RESOURCEGROUP" -n "$CLUSTER" --cluster-resource-group $RESOURCEGROUP-cluster --vnet="$VNET_NAME" --master-subnet="$CLUSTER-master" --worker-subnet="$CLUSTER-worker" --ingress-visibility="$INGRESSPRIVACY" --apiserver-visibility="$APIPRIVACY" --pull-secret="$PULLSECRETFILE" --worker-count="$WORKERS" $CUSTOMDNS $PULLSECRET -o table


################################################################################################## Post Provisioning


# Update ARO RG tags
echo " "
echo -n "Updating resource group tags..."
DOMAIN="$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null |jq -r '.clusterProfile.domain')"
export DOMAIN
VERSION="$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null |jq -r '.clusterProfile.version')"
export VERSION
az group update -g "$RESOURCEGROUP" --tags "ARO $VERSION Build Date=$BUILDDATE" -o table >> /dev/null 2>&1
echo "done."

# Forward Zone Creation (if necessary)
if [ -n "$CUSTOMDNS" ]; then
    DNS="$(echo $CUSTOMDNS | cut -f2 -d=)"
    export DNS
    if [ -z "$(az network dns zone list -o json | jq -r '.[] | .name' | grep $DNS)" ]; then
        echo -n "A DNS zone was not detected for $DNS. Creating..."
	az network dns zone create -n $DNS -g $RESOURCEGROUP -o table >> /dev/null 2>&1
        echo "done." 
        echo " "
        echo "Dumping nameservers for newly created zone..." 
        az network dns zone show -g $DNSRG -n $RESOURCEGROUP -o json | jq -r '.nameServers[]'
        echo " "
    else
        echo "A DNS zone was already detected for $DNS. Skipping zone creation..."
    fi
    DNSRG="$(az network dns zone list -o table |grep $DNS | awk '{print $2}')"
    export DNSRG
    if [ -z "$(az network dns record-set list -g $DNSRG -z $DNS -o table |grep api)" ]; then
        echo -n "An A record for the ARO API does not exist. Creating..." 
        IPAPI="$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null | jq -r '.apiserverProfile.ip')"
	export IPAPI
	az network dns record-set a add-record -z $DNS -g $DNSRG -a $IPAPI -n api -o table >> /dev/null 2>&1
        echo "done."
    else
        echo "An A record appears to already exist for the ARO API server. Please verify this in your DNS zone configuration."
    fi
    if [ -z "$(az network dns record-set list -g $DNSRG -z $DNS -o table |grep apps)" ]; then
        echo -n "An A record for the apps wildcard ingress does not exist. Creating..."
        IPAPPS="$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null | jq -r '.ingressProfiles[0] .ip')"
	export IPAPPS
        az network dns record-set a add-record -z $DNS -g $DNSRG -a $IPAPPS -n *.apps -o table >> /dev/null 2>&1
        echo "done."
    else
        echo "An A record appears to already exist for the apps wildcard ingress. Please verify this in your DNS zone configuration."
    fi
fi

################################################################################################## Output Messages


echo " "
echo "$(az aro list-credentials -n $CLUSTER -g $RESOURCEGROUP -o table 2>/dev/null)"

echo " "
echo "$APIPRIVACY Console URL"
echo "-------------------"
echo "$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null |jq -r '.consoleProfile.url')"

echo " "
echo "$APIPRIVACY API URL"
echo "-------------------"
echo "$(az aro show -n $CLUSTER -g $RESOURCEGROUP -o json 2>/dev/null |jq -r '.apiserverProfile.url')"

echo " "
echo "To delete this ARO Cluster"
echo "--------------------------"
echo "az aro delete -n $CLUSTER -g $RESOURCEGROUP -y ; az group delete -n $RESOURCEGROUP -y"

if [ -n "$CUSTOMDNS" ]; then

    echo " "
    echo "To delete the two A records in DNS"
    echo "----------------------------------"
    echo "az network dns record-set a delete -g $DNSRG -z $DNS -n api -y ; az network dns record-set a delete -g $DNSRG -z $DNS -n *.apps -y"
fi

echo " "
echo "-end- part one"
echo " "

echo "I will attempt to connect Azure Red Hat OpenShift to Azure Active Directory."
echo "*** Please note if your ARO cluster uses a custom domain, the console and app addresses must resolve prior to running this script ***"
echo "ARO Cluster Name: $CLUSTER"
echo "ARO Resource Group Name: $RESOURCEGROUP"
echo "Shall I continue?" 
PS3="Select a numbered option >> "
options=("Yes" "No")
select yn in "${options[@]}"
do
case $yn in
    Yes ) break ;;
    No ) echo "Well okay then."; exit ;;
esac
done

########## Set Variables
echo -n "Obtaining the variables I need..."
aroName=$CLUSTER
export aroName
echo -n "aroName, "
aroRG=$RESOURCEGROUP
export aroRG
echo -n "aroRG, "
dns="$(az aro show -g $aroRG -n $aroName -o json 2>/dev/null |jq -r '.clusterProfile.resourceGroupId' | cut -f5 -d/ |cut -f2 -d-)"
export dns
echo -n "dns, "
location="$(az aro show -g $aroRG -n $aroName --query location -o tsv  2> /dev/null)"
export location
echo -n "location, "
domain="$(az aro show -g $aroRG -n $aroName -o json 2>/dev/null |jq -r '.clusterProfile.domain')"
export domain
echo -n "domain, "
apiServer="$(az aro show -g $aroRG -n $aroName --query apiserverProfile.url -o tsv  2> /dev/null)"
export apiServer
echo -n "apiServer, "
webConsole="$(az aro show -g $aroRG -n $aroName --query consoleProfile.url -o tsv  2> /dev/null)"
export webConsole
echo -n "webConsole, "
clientSecret=$(uuid)
export clientSecret
echo -n "clientSecret, "
consoleUrl=$(az aro show -g $aroRG -n $aroName -o json 2>/dev/null |jq -r '.consoleProfile.url')
export consoleUrl
echo -n "consoleUrl, "
if [ -n "$(echo $consoleUrl | grep aroapp.io)" ]; then
  oauthCallbackURL="https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AAD"
  export oauthCallbackURL
else
  oauthCallbackURL="https://oauth-openshift.apps.$dns/oauth2callback/AAD"
  export oauthCallbackURL
fi
echo -n "oauthCallbackURL..."
echo "done."

########## Create Manifest
echo -n "Creating manifest for Azure application..."
cat > manifest.json<< EOF
[{
  "name": "upn",
  "source": null,
  "essential": false,
  "additionalProperties": []
},
{
"name": "email",
  "source": null,
  "essential": false,
  "additionalProperties": []
},
{
  "name": "name",
  "source": null,
  "essential": false,
  "additionalProperties": []
}]
EOF
echo "done."

########## Generate and configure SP
echo -n "Configuring Azure Application & Service Principal..."
appId=$(az ad app create --query appId -o tsv --display-name aro-$domain-aad-connector --reply-urls $oauthCallbackURL --password $clientSecret 2> /dev/null)
tenantId=$(az account show --query tenantId -o tsv 2> /dev/null)
az ad app update --set optionalClaims.idToken=@manifest.json --id $appId
az ad app permission add --api 00000002-0000-0000-c000-000000000000 --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope --id $appId 2> /dev/null
echo "done."

########## Obtain PW and login to ARO CLI
echo -n "Obtaining ARO login credentials for kubeadmin user..."
kubePW=$(az aro list-credentials -n $aroName -g $aroRG -o tsv 2> /dev/null | awk '{print $1}') 
oc login -u kubeadmin -p $kubePW --server $apiServer --insecure-skip-tls-verify=true
echo "done."

########## Create ARO openID authentication secrets file
echo " "
echo "Creating ARO openID authentication secrets file..."
oc create secret generic openid-client-secret-azuread -n openshift-config --from-literal=clientSecret=$clientSecret
echo "done."

########## Create openID authentication provider YAML configuration
echo -n "Extracting current OpenShift authentication provider configuration and merging AAD provider code..."
oc get oauth cluster -o yaml > oidc.yaml
sed -i '$d' oidc.yaml
cat <<EOF >> oidc.yaml
spec:
  identityProviders:
  - name: AAD
    mappingMethod: claim
    type: OpenID
    openID:
      clientID: $appId
      clientSecret: 
        name: openid-client-secret-azuread
      extraScopes: 
      - email
      - profile
      extraAuthorizeParameters: 
        include_granted_scopes: "true"
      claims:
        preferredUsername: 
        - email
        - upn
        name: 
        - name
        email: 
        - email
      issuer: https://login.microsoftonline.com/$tenantId
EOF
echo "done."

########## Apply configuration and force replication
echo " "
echo "Applying revised authentication provider configuration to OpenShift and forcing replication update..."
oc replace -f oidc.yaml
oc create secret generic openid-client-secret-azuread --from-literal=clientSecret=$clientSecret --dry-run -o yaml | oc replace -n openshift-config -f -
echo "done."

########## Clean Up
echo -n "Cleaning up..."
rm -f manifest.json
rm -f oidc.yaml
echo "done."

echo "Enter with your Azure Ad User and run"
echo "oc get users"
echo "oc adm policy add-cluster-role-to-user cluster-admin <user_name>"

exit 0