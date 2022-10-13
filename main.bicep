targetScope = 'subscription'

@description('Resource Group location.')
param location string = 'westeurope'

@description('Hub resource group.')
param hubrgname string = 'rg-hub-001'

@description('Spoke resource group.')
param spokergname string = 'rg-spoke-001'

@description('Virtual machine admin username.')
param adminusername string

@description('Virtual machine admin password.')
@minLength(12)
@secure()
param adminpassword string

// Create hub resource group
resource rghub 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubrgname
  location: location
}

// Create spoke resource group
resource rgspoke 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokergname
  location: location
}

// Create hub resources
module hubmodule 'hub.module.bicep' = {
  name: 'hubdeployment'
  scope: rghub
  params: {
    location: location
  }
}

//Create spoke resources
module spokemodule 'spoke.module.bicep' = {
  name: 'spokedeployment'
  scope: rgspoke
  params: {
    location: location
    adminUsername: adminusername
    adminPassword: adminpassword
    fwprivateip: hubmodule.outputs.fwprivateip
  }
}

// Create vnet peering hub -> spoke
module peeringhubspoke 'vnetpeering.module.bicep' = {
  name: 'peeringhubspokedeployment'
  scope: rghub
  params: {
    peeringname: 'hub-to-spoke'
    localvnetname: hubmodule.outputs.vnetname
    remotevnetname: spokemodule.outputs.vnetname
    remoteresourcegroupname: rgspoke.name
  }
  dependsOn: [
    hubmodule
    spokemodule
  ]
}

// Create vnet peering spoke -> hub
module peeringspokehub 'vnetpeering.module.bicep' = {
  name: 'peeringspokehubdeployment'
  scope: rgspoke
  params: {    
    peeringname: 'spoke-to-hub'
    localvnetname: spokemodule.outputs.vnetname
    remotevnetname: hubmodule.outputs.vnetname
    remoteresourcegroupname: rghub.name
  }
  dependsOn: [
    hubmodule
    spokemodule
  ]
}
