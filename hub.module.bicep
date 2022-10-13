@description('Resource Group location.')
param location string = resourceGroup().location

var fwname = 'fw-hub-001'
var vnetname = 'vnet-hub-001'
var snetname = 'AzureFirewallSubnet'
var vnetaddressprefix = '10.0.0.0/16'
var snetaddressprefix = '10.0.1.0/24'
var pipname = 'pip-fw-hub-001'
var fwprivateip = '10.0.1.4'

// Create virtual network for hub
resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: vnetname
  location: location
  tags: {
    displayName: vnetname
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressprefix
      ]
    }    
    enableDdosProtection: false   
  }  
}

// Create subnet for firewall (AzureFirewallSubnet)
resource snetfw 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: snetname
  parent: vnet
  properties: {
    addressPrefix: snetaddressprefix
  }
}

// Create public ip address for firewall
resource pipfw 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: pipname
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Create firewall
resource fw 'Microsoft.Network/azureFirewalls@2022-01-01' = {
  name: fwname
  location: location  
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    hubIPAddresses:{
      privateIPAddress: fwprivateip
    }
    ipConfigurations: [
      {
        name: pipname      
        properties: {          
          publicIPAddress: {
            id: pipfw.id
          }
          subnet: {
            id: snetfw.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'SpokeRuleCollection'        
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'HTTP'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: []
              targetFqdns: [
                '*'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

output vnetname string = vnet.name
output fwprivateip string = fwprivateip
