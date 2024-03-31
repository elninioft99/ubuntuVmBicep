param location string = resourceGroup().location
param pubIpName string = 'pub'
param tags object = {}
param adminUserName string = 'elninio'
param vmNum int = 2

@secure()
param adminPasswordOrKey string

module network 'network.bicep' = {
  name: 'vnet'
  params: {
    location: location
    subnetAddressPrefix: '10.2.0.0/24'
    vnetAddressPrefix: '10.2.0.0/16'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'sshRule'
        properties: {
          priority: 300
          direction: 'Inbound'
          protocol: 'Tcp'
          access: 'Allow'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ] 
  }
}

resource pubIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = [ for i in range(1,vmNum): {
  name: '${pubIpName}${i}'
  location: location
    sku:{
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
       
  }
}
]

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = [ for i in range(1,vmNum): {
  name: 'nic${i}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${i}'
        properties: {
          subnet: {
            id: network.outputs.subnetId
          }
          publicIPAddress: {
            id: pubIp[i-1].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}
]

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = [ for i in range(1,vmNum): {
  name: 'vm${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ms'
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i-1].id
        }
      ]
    }
    osProfile: {
      computerName: 'ubuntu${i}'
      adminUsername: adminUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
        ssh: {
          publicKeys:[
            {
              path:'/home/${adminUserName}/.ssh/authorized_keys'
              keyData: adminPasswordOrKey
            }
          ]
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    
  }
  // plan: {
  //   name: 'v1101-byol'
  //   publisher: 'flowmon'
  //   product: 'flowmon_collector'
  //}
  zones: ['1']

}
]
