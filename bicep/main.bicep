@description('Location')
param location string

@description('Domain Prefix')
param domain string

@description('Pull secret from cloud.redhat.com. The json should be input as a string')
param pullSecret string

@description('Name of ARO vNet')
param clusterVnetName string = 'aro-vnet'

@description('ARO vNet Address Space')
param clusterVnetCidr string = '10.100.0.0/15'

@description('Worker node subnet address space')
param workerSubnetCidr string = '10.100.70.0/23'

@description('Master node subnet address space')
param masterSubnetCidr string = '10.100.76.0/24'

@description('Master Node VM Type')
param masterVmSize string = 'Standard_D8s_v3'

@description('Worker Node VM Type')
param workerVmSize string = 'Standard_D4s_v3'

@description('Worker Node Disk Size in GB')
@minValue(128)
param workerVmDiskSize int = 128

@description('Number of Worker Nodes')
@minValue(3)
param workerCount int = 3

@description('Cidr for Pods')
param podCidr string = '10.128.0.0/14'

@metadata({
  description: 'Cidr of service'
})
param serviceCidr string = '172.30.0.0/16'

@description('Unique name for the cluster')
param clusterName string

@description('Tags for resources')
param tags object = {
<<<<<<< HEAD
  env: 'PoC'
=======
  env: 'POC'
>>>>>>> da701593cca24b97496f1c9f4f41502ac8d5a971
}

@description('Api Server Visibility')
@allowed([
  'Private'
  'Public'
])
param apiServerVisibility string = 'Public'

@description('Ingress Visibility')
@allowed([
  'Private'
  'Public'
])
param ingressVisibility string = 'Public'

@description('The Application ID of an Azure Active Directory client application')
param aadClientId string

@description('The Object ID of an Azure Active Directory client application')
param aadObjectId string

@description('The secret of an Azure Active Directory client application')
@secure()
param aadClientSecret string

@description('The ObjectID of the Resource Provider Service Principal')
param rpObjectId string

var contribRole = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'

resource clusterVnetName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: clusterVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        clusterVnetCidr
      ]
    }
    subnets: [
      {
        name: 'master'
        properties: {
          addressPrefix: masterSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'worker'
        properties: {
          addressPrefix: workerSubnetCidr
          serviceEndpoints: [
            {
              service: 'Microsoft.ContainerRegistry'
            }
          ]
        }
      }
    ]
  }
}

resource clusterVnetName_Microsoft_Authorization_id_name_aadObjectId 'Microsoft.Network/virtualNetworks/providers/roleAssignments@2018-09-01-preview' = {
  name: '${clusterVnetName}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name, aadObjectId)}'
  properties: {
    roleDefinitionId: contribRole
    principalId: aadObjectId
  }
  dependsOn: [
    clusterVnetName_resource
  ]
}

resource clusterVnetName_Microsoft_Authorization_id_name_rpObjectId 'Microsoft.Network/virtualNetworks/providers/roleAssignments@2018-09-01-preview' = {
  name: '${clusterVnetName}/Microsoft.Authorization/${guid(resourceGroup().id, deployment().name, rpObjectId)}'
  properties: {
    roleDefinitionId: contribRole
    principalId: rpObjectId
  }
  dependsOn: [
    clusterVnetName_resource
  ]
}

resource clusterName_resource 'Microsoft.RedHatOpenShift/OpenShiftClusters@2020-04-30' = {
  name: clusterName
  location: location
  tags: tags
  properties: {
    clusterProfile: {
      domain: domain
      resourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/aro-${domain}-${location}'
      pullSecret: pullSecret
    }
    networkProfile: {
      podCidr: podCidr
      serviceCidr: serviceCidr
    }
    servicePrincipalProfile: {
      clientId: aadClientId
      clientSecret: aadClientSecret
    }
    masterProfile: {
      vmSize: masterVmSize
      subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVnetName, 'master')
    }
    workerProfiles: [
      {
        name: 'worker'
        vmSize: workerVmSize
        diskSizeGB: workerVmDiskSize
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVnetName, 'worker')
        count: workerCount
      }
    ]
    apiserverProfile: {
      visibility: apiServerVisibility
    }
    ingressProfiles: [
      {
        name: 'default'
        visibility: ingressVisibility
      }
    ]
  }
  dependsOn: [
    clusterVnetName_resource
  ]
}