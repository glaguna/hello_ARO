# PoC about Azure Red Hat OpenShift 

This is a collection of sample projects for Cloud Application Developer using Azure Cloud Platform. The sample projects are arranged in different topics about Infrastructure as Code and deployment on Azure supported by Secure DevOps Practices.

Azure Red Hat OpenShift, reference architecture:
[ARO Reference Architecture](https://techcommunity.microsoft.com/t5/fasttrack-for-azure/azure-red-hat-openshift-reference-architecture-amp-reference/ba-p/3470115)
![](https://techcommunity.microsoft.com/t5/image/serverpage/image-id/377746i9632EE4217A98930/image-size/large?v=v2&px=999)

Prerequirements:
- Create service principal to create GitHub Secrets used by workflows.

```shell
  az ad sp create-for-rbac --name "aropocsp" --role contributor \
                            --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
                            --sdk-auth
                            
  # Replace {subscription-id}, {resource-group} with the subscription, resource group details

  # The command should output a JSON object similar to this:

 
  {
    "clientId": "<GUID>",
    "clientSecret": "<STRING>",
    "subscriptionId": "<GUID>",
    "tenantId": "<GUID>",
    "resourceManagerEndpointUrl": "<URL>"
    (...)
  }
  ```

#### Other Resources
- [What is Infrastructure as Code?](https://docs.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)
- [Infrastructure as code](https://docs.microsoft.com/en-us/dotnet/architecture/cloud-native/infrastructure-as-code)
- [Using IaC on Azure](https://docs.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code#using-iac-on-azure)
- [Deploy an Azure Red Hat OpenShift cluster with an Azure Resource Manager template or Bicep file](https://docs.microsoft.com/en-us/azure/openshift/quickstart-openshift-arm-bicep-template?pivots=aro-bicep)
- [Installing a cluster on Azure](https://docs.openshift.com/container-platform/4.9/installing/installing_azure/preparing-to-install-on-azure.html)
- [Azure Red Hat OpenShift](https://docs.microsoft.com/en-us/azure/openshift/intro-openshift)
- [Azure Policy](https://docs.microsoft.com/en-us/azure/governance/policy/overview)
- [Azure Policy definition structure](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/definition-structure)

### Check More DevSquad Projects
* [DevSquad Main Project](https://github.com/microsoft/fast-prototyping)

> Note: This page is getting updated so make sure to check regularly for new resources.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
