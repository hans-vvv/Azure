"""
Demo script to update a NSG. Some networking and compute resources
are build using Python SDK for Azure.
"""
from azure.mgmt.network.models import SecurityRule, SecurityRuleProtocol

from AzureWrapper import AzureWrapper

azw = AzureWrapper()

azw.set_location('westeurope')

# Create resource group and Vnet
azw.create_rg_or_set_rg_name('myRG')
azw.create_vnet_or_set_vnet_name('myNet', '10.10.0.0/16')

# Create subnets
azw.create_subnet('SUB-1', '10.10.0.0/24')
azw.create_subnet('SUB-2', '10.10.1.0/24')

# Create Network Security Groups
azw.create_nsg('NSG-SUB-1')
azw.create_nsg('NSG-SUB-2')

# Create NIC and VM
nic = azw.create_nic('VM-1-NIC-1', 'SUB-1', '10.10.0.4')
azw.create_linux_test_vm('VM-1', nic)

# Create NIC and VM
nic = azw.create_nic('VM-2-NIC-1', 'SUB-2', '10.10.1.4')
azw.create_linux_test_vm('VM-2', nic)

# # Create Application Security Groups
# azw.create_asg('ASG-VM-1')
# azw.create_asg('ASG-VM-2')
#
# # Associate VM NICs with Application Security groups
# azw.associate_nic_with_asg('ASG-VM-1', 'VM-1-NIC-1')
# azw.associate_nic_with_asg('ASG-VM-2', 'VM-2-NIC-1')

# Print the newly created NSG-SUB-2
azw.print_nsg_rules('NSG-SUB-2')

### This prints:
# Rule Name: AllowVnetInBound, Priority: 65000, Direction: Inbound, Protocol: *, Source: VirtualNetwork, Destination: VirtualNetwork, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowVnetOutBound, Priority: 65000, Direction: Outbound, Protocol: *, Source: VirtualNetwork, Destination: VirtualNetwork, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowAzureLoadBalancerInBound, Priority: 65001, Direction: Inbound, Protocol: *, Source: AzureLoadBalancer, Destination: *, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowInternetOutBound, Priority: 65001, Direction: Outbound, Protocol: *, Source: *, Destination: Internet, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: DenyAllInBound, Priority: 65500, Direction: Inbound, Protocol: *, Source: *, Destination: *, Source Port: *, Destination Port: *, Access: Deny
# Rule Name: DenyAllOutBound, Priority: 65500, Direction: Outbound, Protocol: *, Source: *, Destination: *, Source Port: *, Destination Port: *, Access: Deny

# Update the NSG
asg = azw.network_client.application_security_groups.get(azw.rg_name, 'ASG-VM-1')
security_rule_params = SecurityRule(
    name='Allow_Outbound_8001',
    protocol=SecurityRuleProtocol.tcp,
    source_port_range='*',
    destination_port_range='8000',
    source_address_prefix='*',
    destination_application_security_groups=[asg],
    access='Allow',
    direction='Outbound',
    priority=300,
)
nsg = azw.network_client.network_security_groups.get(azw.rg_name, 'NSG-SUB-2')
nsg.security_rules.append(security_rule_params)

# Update the NSG
azw.network_client.network_security_groups.begin_create_or_update(azw.rg_name, 'NSG-SUB-2', nsg)

# print the NSG again
azw.print_nsg_rules('NSG-SUB-2')

# This prints: (Notice that rule has been added)

# Rule Name: Allow_Outbound_8001, Priority: 300, Direction: Outbound, Protocol: Tcp, Source: *, Destination: None, Source Port: *, Destination Port: 8000, Access: Allow
# Rule Name: AllowVnetInBound, Priority: 65000, Direction: Inbound, Protocol: *, Source: VirtualNetwork, Destination: VirtualNetwork, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowVnetOutBound, Priority: 65000, Direction: Outbound, Protocol: *, Source: VirtualNetwork, Destination: VirtualNetwork, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowAzureLoadBalancerInBound, Priority: 65001, Direction: Inbound, Protocol: *, Source: AzureLoadBalancer, Destination: *, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: AllowInternetOutBound, Priority: 65001, Direction: Outbound, Protocol: *, Source: *, Destination: Internet, Source Port: *, Destination Port: *, Access: Allow
# Rule Name: DenyAllInBound, Priority: 65500, Direction: Inbound, Protocol: *, Source: *, Destination: *, Source Port: *, Destination Port: *, Access: Deny
# Rule Name: DenyAllOutBound, Priority: 65500, Direction: Outbound, Protocol: *, Source: *, Destination: *, Source Port: *, Destination Port: *, Access: Deny

