param vmNum int
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = [for i in range(1,vmNum):{
  name: 'vm${i}'
}
]
resource script 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = [for i in range(1,vmNum):{
  name: 'dhcp'
  location: location
  parent: vm[i-1]
  properties: {
    asyncExecution: false
    source: {
      script: '''echo b > /home/elninio/a.txt;
      echo kir > /home/elninio/dick.txt'''
    }
  }
}
]
