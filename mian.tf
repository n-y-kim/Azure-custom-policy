# 리소스 그룹
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

# NSG
resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# VNet
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]

# subnet을 VNet resource 에서 생성
  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
    security_group = azurerm_network_security_group.example.id
  }

  subnet {
    name = "subnet2"
    address_prefix = "10.0.2.0/24"
    security_group = azurerm_network_security_group.example.id
  }
}

# data 로 subnet 리소스 이용
data "azurerm_subnet" "subnet1" {
    name                 = "subnet1"
    resource_group_name  = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
}

# 예시, subnet 에 NIC 생성
resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

data "azurerm_subnet" "subnet2" {
    name                = "subnet2"
    resource_group_name = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
}