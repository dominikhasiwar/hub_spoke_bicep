@description('Resource Group location.')
param location string = resourceGroup().location

@description('Admin username.')
param adminUsername string

@description('Admin password.')
@minLength(12)
@secure()
param adminPassword string

@description('Firewall private ip.')
param fwprivateip string

var nsgname = 'nsg-spoke-001'
var vnetname = 'vnet-spoke-001'
var snetname = 'snet-spoke-001'
var vnetaddressprefix = '192.0.0.0/16'
var snetaddressprefix = '192.0.0.0/24'
var snetbasitonaddressprefix = '192.0.1.0/26'
var routetablename = 'rt-spoke-001'
var nicname = 'nic-spoke-001'
var vmname = 'vm-spoke-001'
var vmsize = 'Standard_B2s'
var osversion = '2022-datacenter'
var bastionname = '${vnetname}-bastion'
var pipbastionname = '${vnetname}-ip'

// Create network security group
resource nsg 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: nsgname
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Create route table 
resource rtspoke 'Microsoft.Network/routeTables@2022-01-01' = {
  name: routetablename
  location: location
  properties: {
    routes: [
      {
        name: 'SpokeToFirewallRoute'        
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: fwprivateip
        }
        type: 'Microsoft.Network/routeTables/routes'
      }
    ]
  }
}

// Create virtual network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressprefix
      ]
    }   
  }
}

// Create spoke subnet
resource snetspoke 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: snetname
  parent: vnet
  properties: {
    addressPrefix: snetaddressprefix
    networkSecurityGroup: {
      id: nsg.id
    }
    routeTable:{
      id: rtspoke.id
    }
  }
}

// Create bastion subnet
resource snetbastion 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: 'AzureBastionSubnet'
  parent: vnet
  properties: {
    addressPrefix: snetbasitonaddressprefix
  }
}

// Create network interface
resource nic 'Microsoft.Network/networkInterfaces@2022-01-01' = {
  name: nicname
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: snetspoke.id
          }
        }
      }
    ]
  }
}

// Create virtual machine
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmname
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmsize
    }
    osProfile: {
      computerName: vmname
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: osversion
        version: 'latest'
      }
      osDisk: {
        name: '${replace(vmname, '-', '')}_osdisc'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Create public ip address for bastion
resource pipbastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: pipbastionname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Create bastion for virtual machine 
resource vnetspokebastion 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionname
  location: location
  tags: {
  }
  properties: {
    scaleUnits: 2
    enableTunneling: false
    enableIpConnect: false
    disableCopyPaste: false
    enableShareableLink: false    
    ipConfigurations: [
      {
        name: 'IpConf'        
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pipbastion.id
          }
          subnet: {
            id: snetbastion.id
          }
        }
      }
    ]
  }
  sku: {
    name: 'Basic'
  }
}

output vnetname string = vnet.name
