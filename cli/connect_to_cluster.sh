REGION_NAME=eastus2
RESOURCE_GROUP=POC-ARO-002
CLUSTER_NAME=oa-aro-poc-002


az login --service-principal -u $1 -p $2 --tenant $3

az aro list-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP