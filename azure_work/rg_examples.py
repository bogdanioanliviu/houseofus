import os
from azure.identity import DefaultAzureCredential
from azure_identity_credential_adapter import AzureIdentityCredentialAdapter
from azure.mgmt.resource import ResourceManagementClient

subscription_id = os.environ.get(
    'AZURE_SUBSCRIPTION_ID') # your Azure Subscription Id

cred = DefaultAzureCredential()
credentials = AzureIdentityCredentialAdapter()
client = ResourceManagementClient(credentials, subscription_id)
resource_group_params = {'location':'westeurope'}
for item in client.resource_groups.list():

    print("\tName: {}".format(item.name))
    print("\tId: {}".format(item.id))
    print("\tLocation: {}".format(item.location))
    print("\tTags: {}".format(item.tags))
    print("\t\tProvisioning State: {}".format(item.properties.provisioning_state))
