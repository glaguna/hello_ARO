LOCATION=eastus2                # the location of your cluster
RESOURCEGROUP=POC-ARO-003           # the name of the resource group where you want to create your cluster
CLUSTER=oa-aro-poc-003                 # the name of your cluster

az login --service-principal -u $1 -p $2 --tenant $3

az group create --name $RESOURCEGROUP --location $LOCATION

az network vnet create --resource-group $RESOURCEGROUP --name aro-vnet --address-prefixes 10.0.0.0/22

az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name aro-vnet --name master-subnet --address-prefixes 10.0.0.0/23 --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet create --resource-group $RESOURCEGROUP --vnet-name aro-vnet --name worker-subnet --address-prefixes 10.0.2.0/23 --service-endpoints Microsoft.ContainerRegistry

az network vnet subnet update --name master-subnet -resource-group $RESOURCEGROUP --vnet-name aro-vnet --disable-private-link-service-network-policies true

az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet aro-vnet --master-subnet master-subnet --worker-subnet worker-subnet --worker-count 3