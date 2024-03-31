param location string = resourceGroup().location
param vnetAddressPrefix string 
param subnetAddressPrefix string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet1'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-09-01' = {
  name: 'subnet1'
  parent: virtualNetwork
  properties: {
    addressPrefix: subnetAddressPrefix
  }
}

output subnetId string = subnet.id
