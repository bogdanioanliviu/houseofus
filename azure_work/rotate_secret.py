import datetime
import dateutil.parser
import sys
import secrets
import string
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

#Today date for compare with expire_on
today = datetime.datetime.utcnow().date()
print(today)
# Alphabet for secret
alphabet = string.ascii_letters + string.digits
#Create client to access kv
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url="https://kv-first-test.vault.azure.net/", credential=credential)

#List secrets from kv
secrets_list = secret_client.list_properties_of_secrets()

# Iterate on the list and print info 
for secret in secrets_list:
    retrieved_secret = secret_client.get_secret(secret.name)
    print(retrieved_secret.id)
    print(retrieved_secret.name)
    print(retrieved_secret.value)
    print(retrieved_secret.properties.version)
    print(retrieved_secret.properties.vault_url)
    #print(retrieved_secret.properties.expires_on.date())
    #Calculate diference until secret expires 
    if 'AZURE' not in retrieved_secret.name:
        val = retrieved_secret.properties.expires_on.date() - today
    # check if nr of days is less or equal with 1
        if val.days <= 1:
            print("esto es then {0}".format(val))
            #generate new password for secret using alphabet and length of 20 
            new_password = ''.join(secrets.choice(alphabet) for i in range(20))
            #Set new expiration date
            expires = datetime.datetime.utcnow() + datetime.timedelta(days=5)
            #Create or update secret with new pass and expiration date
            secret_client.set_secret(name=retrieved_secret.name, value=new_password, expires_on=expires)
        else:
            print("esto es else {0}".format(val))
