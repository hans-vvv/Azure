import os
from azure.identity import AzureCliCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network.models import VirtualNetwork, AddressSpace, Subnet
from azure.mgmt.network.models import NetworkSecurityGroup
from azure.mgmt.compute.models import HardwareProfile, StorageProfile, OSProfile, NetworkProfile
from azure.mgmt.compute.models import NetworkInterfaceReference, VirtualMachineSizeTypes

from credentials import SUBSCRIPTION_ID, ADMIN_USERNAME, ADMIN_PASSWORD


class AzureWrapper:

    """
    Wrapper class which provides methods to perform CRUD operations on Azure objects
    """

    def __init__(self):

        self.resource_client = None
        self.network_client = None
        self.compute_client = None

        self.location = None
        self.rg_name = None
        self.vnet_name = None

        self._setup()

    def _setup(self):

        os.environ['PATH'] += ';C:\\Program Files (x86)\\Microsoft SDKs\\Azure\\CLI2\\wbin'

        credential = AzureCliCredential()
        self.resource_client = ResourceManagementClient(credential, SUBSCRIPTION_ID)
        self.network_client = NetworkManagementClient(credential, SUBSCRIPTION_ID)
        self.compute_client = ComputeManagementClient(credential, SUBSCRIPTION_ID)

    def set_location(self, location):
        """
        """
        self.location = location

    def create_rg_or_set_rg_name(self, rg_name):
        """
        """
        self.rg_name = rg_name
        resource_group_params = {'location': self.location}
        rgs = self.resource_client.resource_groups.list()
        rg_exists = any(rg.name == rg_name for rg in rgs)
        if not rg_exists:
            self.resource_client.resource_groups.create_or_update(rg_name, resource_group_params)
            print(f'RG {rg_name} created')

    def create_vnet_or_set_vnet_name(self, vnet_name, address_space):
        """
        """
        self.vnet_name = vnet_name
        address_space_params = AddressSpace(address_prefixes=[address_space])
        vnet_params = VirtualNetwork(location=self.location, address_space=address_space_params)
        vnets = self.network_client.virtual_networks.list(self.rg_name)
        vnet_exists = any(vnet.name == vnet_name for vnet in vnets)
        if not vnet_exists:
            self.network_client.virtual_networks.begin_create_or_update(
                self.rg_name, vnet_name, vnet_params
            ).result()
            print(f'VNET {vnet_name} created in RG {self.rg_name}')

    def create_subnet(self, subnet_name, subnet_prefix):
        """
        """
        subnet_params = Subnet(address_prefix=subnet_prefix)
        subnets = self.network_client.subnets.list(self.rg_name, self.vnet_name)
        subnet_exists = any(subnet.name == subnet_name for subnet in subnets)
        if not subnet_exists:
            self.network_client.subnets.begin_create_or_update(
                self.rg_name, self.vnet_name, subnet_name, subnet_params
            ).result()
            print(f'Subnet {subnet_name} created in VNet {self.vnet_name}')

    def create_nsg(self, nsg_name):
        """
        """
        nsg_params = NetworkSecurityGroup(location=self.location)
        nsgs = self.network_client.network_security_groups.list(self.rg_name)
        nsg_exists = any(nsg.name == nsg_name for nsg in nsgs)
        if not nsg_exists:
            self.network_client.network_security_groups.begin_create_or_update(
                self.rg_name, nsg_name, nsg_params
            ).result()
            print(f'NSG {nsg_name} created in RG {self.rg_name}')

    def create_nic(self, nic_name, subnet_name, private_ip_address, public_ip_address=True):
        """
        """
        nics = self.network_client.network_interfaces.list(self.rg_name)
        nic_exists = any(nic.name == nic_name for nic in nics)
        if not nic_exists:
            public_ip_name = None
            if public_ip_address is True:
                public_ip_name = 'myPublicIP_' + nic_name
                public_ip_params = {
                    'location': self.location,
                    'public_ip_allocation_method': 'Dynamic'
                }
                self.network_client.public_ip_addresses.begin_create_or_update(
                    self.rg_name, public_ip_name, public_ip_params
                ).result()

            ip_config = {
                'name': 'myIPConfig_' + nic_name,
                'private_ip_address': private_ip_address,
                'subnet': {'id': self.network_client.subnets.get(self.rg_name, self.vnet_name, subnet_name).id}
            }
            if public_ip_address is True:
                public_ip = self.network_client.public_ip_addresses.get(self.rg_name, public_ip_name)
                ip_config.update({'public_ip_address': {'id': public_ip.id}})

            nic_params = {
                'location': self.location,
                'ip_configurations': [ip_config]
            }
            self.network_client.network_interfaces.begin_create_or_update(self.rg_name, nic_name, nic_params).result()

        return self.network_client.network_interfaces.get(self.rg_name, nic_name)

    def create_linux_test_vm(self, vm_name, nic):
        """
        """
        vms = self.compute_client.virtual_machines.list(self.rg_name)
        vm_exists = any(vm.name == vm_name for vm in vms)
        if not vm_exists:
            vm_params = {
                'location': self.location,
                'hardware_profile': HardwareProfile(vm_size=VirtualMachineSizeTypes.STANDARD_DS1_V2),
                'storage_profile': StorageProfile(
                    image_reference={
                        'publisher': 'Canonical',
                        'offer': 'UbuntuServer',
                        'sku': '18.04-LTS',
                        'version': 'latest'
                    }
                ),
                'os_profile': OSProfile(
                    computer_name=vm_name,
                    admin_username=ADMIN_USERNAME,
                    admin_password=ADMIN_PASSWORD,
                ),
                'network_profile': NetworkProfile(
                    network_interfaces=[NetworkInterfaceReference(
                        id=self.network_client.network_interfaces.get(self.rg_name, nic.name).id)]
                )
            }
            self.compute_client.virtual_machines.begin_create_or_update(
                self.rg_name, vm_name, vm_params).result()
        return self.compute_client.virtual_machines.get(self.rg_name, vm_name)

    def add_nic_to_vm(self, vm_name, nic):
        """
        """
        nic_name = nic.name
        nics = self.network_client.network_interfaces.list(self.rg_name)
        nic_exists = any(nic.name == nic_name for nic in nics)
        if not nic_exists:
            vm = self.compute_client.virtual_machines.get(self.rg_name, vm_name)
            vm.network_profile.network_interfaces.append({'id': nic.id})

    def create_asg(self, asg_name):
        """
        """
        asgs = self.network_client.application_security_groups.list(self.rg_name)
        asg_exists = any(asg.name == asg_name for asg in asgs)
        if not asg_exists:
            asg_params = {'location': self.location}
            self.network_client.application_security_groups.begin_create_or_update(
                self.rg_name, asg_name, asg_params
            ).result()
            print(f'ASG {asg_name} created')

    def associate_nic_with_asg(self, asg_name, nic_name):
        """
        """
        nic = self.network_client.network_interfaces.get(self.rg_name, nic_name)
        asg = self.network_client.application_security_groups.get(self.rg_name, asg_name)
        # ip_configs = nic.ip_configurations

        # Append the ASG to each IP configuration
        for ip_config in nic.ip_configurations:
            if ip_config.application_security_groups is None:
                ip_config.application_security_groups = []
            ip_config.application_security_groups.append({'id': asg.id})

        # Update NIC
        async_nic_update = self.network_client.network_interfaces.begin_create_or_update(
            self.rg_name, nic_name, {
                'location': nic.location,
                'ip_configurations': nic.ip_configurations,
                'network_security_group': nic.network_security_group,
                'tags': nic.tags,
            }
        )
        # Wait for the operation to complete
        updated_nic = async_nic_update.result()
        return updated_nic

    def print_nsg_rules(self, nsg_name):
        """
        """
        nsg = self.network_client.network_security_groups.get(self.rg_name, nsg_name)
        all_nsg_rules = []
        all_nsg_rules.extend(nsg.security_rules)
        all_nsg_rules.extend(nsg.default_security_rules)

        for rule in sorted(all_nsg_rules, key=lambda rule: rule.priority):
            print(f"Rule Name: {rule.name}, Priority: {rule.priority}, Direction: {rule.direction}, "
                  f"Protocol: {rule.protocol}, Source: {rule.source_address_prefix}, "
                  f"Destination: {rule.destination_address_prefix}, Source Port: {rule.source_port_range}, "
                  f"Destination Port: {rule.destination_port_range}, Access: {rule.access}")
