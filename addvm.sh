{
  "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
        "storageAccountType": {
        "type": "string",
        "defaultValue": "Standard_LRS",
        "allowedValues": [
          "Standard_LRS",
          "Standard_ZRS",
          "Standard_GRS",
          "Standard_RAGRS",
          "Premium_LRS"
        ],
        "metadata":{  
            "description":"Storage Account type"
         }
      },
      "simpleWIN-vmName": {
        "defaultValue": "simpleWin-vm",
        "type": "string",
        "metadata": {
            "description" : "simpleWin virtual machine name"
       }
     },
     "vmAdminUserName": {
       "type": "string",
       "minLength": 1,
       "metadata": {
           "description" : "Virtual Machine user name"
        }
      },
      "vmAdminPassword": {
        "type": "securestring",
        "metadata": {
            "description" : "Virtual Machine password"
        }
      }
    },  
    "variables": {
        "source-virtualNetworkName": "source-vnet",
        "Subnet1Name": "Subnet-1",
        "simpleWin-storageAccountName": "[concat(uniquestring(resourceGroup().id), 'sawinvm')]",
        "simpleWin-NicName": "myVMNic",
        "simpleWin-pipName": "myPublicIP",
        "source-subnetRef": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('source-virtualNetworkName'), variables('Subnet1Name'))]",
        "windowsOSVersion": "2016-Datacenter"
    },
    "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "name": "[variables('simpleWin-storageAccountName')]",
      "apiVersion": "2016-01-01",
      "location": "[resourceGroup().location]",
      "sku": {
        "name": "[parameters('storageAccountType')]"
      },
      "kind": "Storage",
      "properties": {}
    },
    {
      "apiVersion": "2016-03-30",
      "type": "Microsoft.Network/publicIPAddresses",
      "name": "[variables('simpleWin-pipName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "publicIPAllocationMethod": "Dynamic"        
      }
    },
    {
      "apiVersion": "2016-03-30",
      "type": "Microsoft.Network/networkInterfaces",
      "name": "[variables('simpleWin-NicName')]",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses/', variables('simpleWin-pipName'))]"
      ],
      "properties": {
        "ipConfigurations": [
          {
            "name": "ipconfig1",
            "properties": {
              "privateIPAllocationMethod": "Dynamic",
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses',variables('simpleWin-pipName'))]"
              },
              "subnet": {
                "id": "[variables('source-subnetRef')]"
              }
            }
          }
        ]
      }
    },
    {
      "apiVersion": "2017-03-30",
      "type": "Microsoft.Compute/virtualMachines",
      "name": "[parameters('simpleWIN-vmName')]",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts/', variables('simpleWin-storageAccountName'))]",
        "[resourceId('Microsoft.Network/networkInterfaces/', variables('simpleWin-NicName'))]"
      ],
      "properties": {
        "hardwareProfile": {
          "vmSize": "Standard_DS3_v2"
        },
        "osProfile": {
          "computerName": "[parameters('simpleWIN-vmName')]",
          "adminUsername": "[parameters('vmAdminUserName')]",
          "adminPassword": "[parameters('vmAdminPassword')]"
        },
        "storageProfile": {
          "imageReference": {
            "publisher": "MicrosoftWindowsServer",
            "offer": "WindowsServer",
            "sku": "[variables('windowsOSVersion')]",
            "version": "latest"
          },
          "osDisk": {
            "createOption": "FromImage"
          },
          "dataDisks": [
            {
              "diskSizeGB": 1023,
              "lun": 0,
              "createOption": "Empty"
            }
          ]
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces',variables('simpleWin-NicName'))]"
            }
          ]
        },
        "diagnosticsProfile": {
          "bootDiagnostics": {
            "enabled": true,
            "storageUri": "[reference(resourceId('Microsoft.Storage/storageAccounts/', variables('simpleWin-storageAccountName'))).primaryEndpoints.blob]"
          }
        }
      }
    }
  ]
}

    
