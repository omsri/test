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
      "source-vmName": {
        "defaultValue": "source-vm",
        "type": "string",
        "metadata": {
            "description": "source virtual machine name"
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
    "source-pipName": "source-pip",
    "source-nicName": "[concat('source-', parameters('source-vmName'), 'NetworkInterface')]",
    "source-nsgName": "source-nsg",
    "source-vnetPrefix": "10.1.1.0/24",
    "source-vnetSubnetPrefix" : "10.1.1.32/27",
    "source-vmOSDiskName": "source-vmOSDisk",
    "source-vmSize": "Standard_DS3_v2",
    "vmStorageAccountContainerName": "vhds",
    "source-StorageAccountName": "[concat('sourcezerto', uniqueString(resourceGroup().id))]",
    "source-subnetRef": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('source-virtualNetworkName'), variables('Subnet1Name'))]",
    "Subnet1Name": "Subnet-1"
    },
    "resources": [
        {
          "name": "[variables('source-StorageAccountName')]",
          "type": "Microsoft.Storage/storageAccounts",
          "location": "[resourceGroup().location]",
          "apiVersion": "2016-01-01",
          "sku": {
            "name": "[parameters('storageAccountType')]"
          },
          "dependsOn": [ ],
          "tags": {
            "displayName": "source-storageAccount"
          },
          "kind": "Storage"
        },
        {
          "name": "[variables('source-virtualNetworkName')]",
          "type": "Microsoft.Network/virtualNetworks",
          "location": "[resourceGroup().location]",
          "apiVersion": "2016-03-30",
          "dependsOn": [ ],
          "tags": {
            "displayName": "source-vnet"
          },
          "properties": {
            "addressSpace": {
              "addressPrefixes": [
                "[variables('source-vnetPrefix')]"
              ]
            },
            "subnets": [
              {
                "name": "[variables('Subnet1Name')]",
                "properties": {
                  "addressPrefix": "[variables('source-vnetSubnetPrefix')]"
                }
              }
            ]
          }
        },
        {
          "name": "[variables('source-nicName')]",
          "type": "Microsoft.Network/networkInterfaces",
          "location": "[resourceGroup().location]",
          "apiVersion": "2016-03-30",
          "dependsOn": [
            "[resourceId('Microsoft.Network/virtualNetworks', variables('source-virtualNetworkName'))]",
            "[resourceId('Microsoft.Network/publicIPAddresses', variables('source-pipName'))]"
          ],
          "tags": {
            "displayName": "source-vmNic"
          },
          "properties": {
            "ipConfigurations": [
              {
                "name": "ipconfig1",
                "properties": {
                  "privateIPAllocationMethod": "Dynamic",
                  "subnet": {
                    "id": "[variables('source-subnetRef')]"
                  },
                  "publicIPAddress": {
                    "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('source-pipName'))]"
                  }
                }
              }
            ],
            "networkSecurityGroup": {
                        "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('source-nsgName'))]"
                    }
          }
        },
        {
          "name": "[parameters('source-vmName')]",
          "type": "Microsoft.Compute/virtualMachines",
          "location": "[resourceGroup().location]",
          "apiVersion": "2015-06-15",
          "dependsOn": [
            "[resourceId('Microsoft.Storage/storageAccounts', variables('source-StorageAccountName'))]",
            "[resourceId('Microsoft.Network/networkInterfaces', variables('source-nicName'))]"
          ],
          "tags": {
            "displayName": "source-vm"
          },
          "plan": {
            "name": "zerto60ga",
            "publisher": "zerto",
            "product": "zerto-cloud-appliance-50"
          },
          "properties": {
            "hardwareProfile": {
              "vmSize": "[variables('source-vmSize')]"
            },
            "osProfile": {
              "computerName": "[parameters('source-vmName')]",
              "adminUsername": "[parameters('vmAdminUsername')]",
              "adminPassword": "[parameters('vmAdminPassword')]"
            },
            "storageProfile": {
              "imageReference": {
                "publisher": "zerto",
                "offer": "zerto-cloud-appliance-50",
                "sku": "zerto60ga",
                "version": "latest"
              },
              "osDisk": {
                "name": "vmOSDisk",
                "vhd": {
                  "uri": "[concat(reference(resourceId('Microsoft.Storage/storageAccounts', variables('source-StorageAccountName')), '2016-01-01').primaryEndpoints.blob, variables('vmStorageAccountContainerName'), '/', variables('source-vmOSDiskName'), '.vhd')]"
                },
                "caching": "ReadWrite",
                "createOption": "FromImage"
              }
            },
            "networkProfile": {
              "networkInterfaces": [
                {
                  "id": "[resourceId('Microsoft.Network/networkInterfaces', variables('source-nicName'))]"
                }
              ]
            }
          }
        },
        {
          "name": "[variables('source-pipName')]",
          "type": "Microsoft.Network/publicIPAddresses",
          "location": "[resourceGroup().location]",
          "apiVersion": "2016-03-30",
          "dependsOn": [ ],
          "tags": {
            "displayName": "source-pip"
          },
          "properties": {
            "publicIPAllocationMethod": "Dynamic"          
          }
        },
        {          
                "type": "Microsoft.Network/networkSecurityGroups",
                "name": "[variables('source-nsgName')]",
                "apiVersion": "2017-06-01",
                "location": "[resourceGroup().location]",            
                "properties": { 
                        "securityRules": [
                        {
                            "name": "AllowRDP",
                            "etag": "W/\"ec1cdead-18a3-4ae4-b0fa-1d58260ead30\"",
                            "properties": {
                                "provisioningState": "Succeeded",
                                "protocol": "Tcp",
                                "sourcePortRange": "*",
                                "destinationPortRange": "3389",
                                "sourceAddressPrefix": "*",
                                "destinationAddressPrefix": "*",
                                "access": "Allow",
                                "priority": 100,
                                "direction": "Inbound",
                                "sourceAddressPrefixes": [],
                                "destinationAddressPrefixes": []
                            }
                        }
                    ]			
                }
            }
        
      ],
      "outputs": {
        "vNet" : {
          "type" : "string",
          "value" : "[resourceId('Microsoft.Network/virtualNetworks', variables('source-virtualNetworkName'))]"
        }
      }
    }
