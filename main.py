import os
from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.network.models import VirtualNetwork, AddressSpace, Subnet
from azure.mgmt.network.models import NetworkSecurityGroup, SecurityRule
from credentials import SUBSCRIPTION_ID

os.environ['PATH'] += ';C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin'

# Create Azure CLI credential
credential = AzureCliCredential()

# Replace 'your-subscription-id' with your actual subscription ID
subscription_id = SUBSCRIPTION_ID

# Create Resource Management client
client = ResourceManagementClient(credential, subscription_id)

# Define resource group parameters
resource_group_name = 'rg-firstdemo'
location = 'westeurope'

# Create the resource group
resource_group_params = {'location': location}
resource_group = client.resource_groups.create_or_update(resource_group_name, resource_group_params)

# Create Network Management client
network_client = NetworkManagementClient(credential, subscription_id)

# Define VNet parameters
vnet_name = 'myVNet'
address_space = '10.200.0.0/16'
address_space_params = AddressSpace(address_prefixes=[address_space])

# Create the VNet
vnet_params = VirtualNetwork(location=location, address_space=address_space_params)
vnet = network_client.virtual_networks.begin_create_or_update(resource_group_name, vnet_name, vnet_params).result()

print(f"VNet '{vnet_name}' created in resource group '{resource_group_name}' with address space '{address_space}'.")

# Define Subnet parameters
subnet_name = 'mySubnet'
subnet_address_prefix = '10.200.0.0/24'

# Create the subnet
subnet_params = Subnet(address_prefix=subnet_address_prefix)
subnet = network_client.subnets.begin_create_or_update(
    resource_group_name, vnet_name, subnet_name, subnet_params
).result()

print(f"Subnet '{subnet_name}' created in VNet '{vnet_name}' with address prefix '{subnet_address_prefix}'.")

# Define NSG parameters
nsg_name = 'myNSG'
nsg_params = NetworkSecurityGroup(location=location)

# Create the NSG
nsg = network_client.network_security_groups.begin_create_or_update(
    resource_group_name, nsg_name, nsg_params
).result()

# Define Security Rules
security_rule_ssh = SecurityRule(
    protocol='Tcp',
    source_address_prefix='*',
    destination_address_prefix='*',
    access='Allow',
    direction='Inbound',
    source_port_range='*',
    destination_port_range='22',
    priority=1000,
    name='Allow_SSH'
)

security_rule_icmp = SecurityRule(
    protocol='Icmp',
    source_address_prefix='*',
    destination_address_prefix='*',
    access='Allow',
    direction='Inbound',
    source_port_range='*',
    destination_port_range='*',
    priority=1010,
    name='Allow_ICMP'
)

# Add Security Rules to the NSG
network_client.security_rules.begin_create_or_update(
    resource_group_name, nsg_name, security_rule_ssh.name, security_rule_ssh
).result()

network_client.security_rules.begin_create_or_update(
    resource_group_name, nsg_name, security_rule_icmp.name, security_rule_icmp
).result()

# Associate the NSG with the Subnet
subnet.network_security_group = nsg

network_client.subnets.begin_create_or_update(resource_group_name, vnet_name, subnet_name, subnet).result()

nsg = network_client.network_security_groups.get(resource_group_name, nsg_name)
all_nsg_rules = []
all_nsg_rules.extend(nsg.security_rules)
all_nsg_rules.extend(nsg.default_security_rules)

for rule in sorted(all_nsg_rules, key=lambda rule: rule.priority):
    print(f"Rule Name: {rule.name}, Priority: {rule.priority}, Direction: {rule.direction}, "
          f"Protocol: {rule.protocol}, Source: {rule.source_address_prefix}, "
          f"Destination: {rule.destination_address_prefix}, Source Port: {rule.source_port_range}, "
          f"Destination Port: {rule.destination_port_range}, Access: {rule.access}")


# Create Resource Management client
resource_client = ResourceManagementClient(credential, subscription_id)

# Delete the resource group
delete_async_operation = resource_client.resource_groups.begin_delete(resource_group_name)
delete_async_operation.wait()

print(f"Resource group '{resource_group_name}' and all its resources have been deleted.")



