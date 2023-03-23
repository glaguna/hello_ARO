LOCATION=eastus                # the location of your cluster
RESOURCEGROUP=aro-work-898140           # the name of the resource group where you want to create your cluster
CLUSTER=oa-aro-poc-003                 # the name of your cluster

az login --service-principal -u $1 -p $2 --tenant $3

az aro create --resource-group $RESOURCEGROUP --name $CLUSTER --vnet aro-vnet --master-subnet master-subnet --worker-subnet worker-subnet --worker-count 3 --client-id $1 --client-secret $2 -o table
