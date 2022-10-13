@description('Virtual Network Peering name.')
param peeringname string

@description('Local Virtual Network name.')
param localvnetname string

@description('Remote Virtual Network name.')
param remotevnetname string

@description('Remote Resource Group name.')
param remoteresourcegroupname string

resource vnetpeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-01-01' = {
  name: '${localvnetname}/${peeringname}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteresourcegroupname, 'Microsoft.Network/virtualNetworks', remotevnetname)
    }
  }
}
