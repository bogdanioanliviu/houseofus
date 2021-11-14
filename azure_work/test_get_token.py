import datetime
import sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.keys import KeyClient
import azure.mgmt.resource  
#import automationassets

# This is to get values from input 
#resource_group_name = str(sys.argv[1])
#vm_name = str(sys.argv[2])
#print("Resurce group variable has value: {0} ".format(resource_group_name))
#print("Vm name variable has value: {0} ".format(vm_name))
# End of input variables

#This is to get a variable from azure 
#value = automationassets.get_automation_variable("test-variable")
#print(value)
# End external variable

groups = resource_client.resource_groups.list()  
for group in groups:  
    print(group.name) 

credential = DefaultAzureCredential()
key_client = KeyClient(vault_url="https://kv-first-test.vault.azure.net/", credential=credential)

#key = key_client.get_key("first-key")
#print(key.id)
#print(key.name)
#print(key.properties.version)
#print(key.key_type)
#print(key.properties.vault_url)

keys = key_client.list_properties_of_keys()

for key in keys:
    # the list doesn't include values or versions of the keys
    expires = datetime.datetime.utcnow() + datetime.timedelta(days=365)
    updated_key = key_client.update_key_properties(
        key.name, expires_on=expires, enabled=True
    )
    print("Key {0} has expiration date: {1}.".format(key.name, key.expires_on))

