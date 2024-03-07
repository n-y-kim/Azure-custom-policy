# Azure-custom-policy

## 개요
Subnet에 NSG가 없으면 생성을 deny하는 Custom Policy json 및 이에 따른 terraform 파일 예시.

## Quick Start

### Custom policy definition 만들기
`deny-vnet-subnet-creation-without-nsg.json` 파일을 이용해 Azure Policy를 생성. 해당 Policy 적용 시 NSG가 없는 Subnet, VNet 생성을 deny하게 됨.

### Subnet 정의 방식 바꾸기
기존의 subnet들을 `azurerm_subnet` 리소스로 정의하고 있었다면 `azurerm_virtual_network` 리소스에 `subnet` 블록으로 정의하는 방식으로 변경

예시) 기존 subnet 정의
```hcl
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

예시) 새로운 subnet 정의는 무조건 vnet 리소스에서, data로 subnet 리소스 이용
```hcl
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

}

data "azurerm_subnet" "subnet1" {
    name                 = "subnet1"
    resource_group_name  = azurerm_resource_group.example.name
    virtual_network_name = azurerm_virtual_network.example.name
}
```

## Subnet 정의 방법 변경 이유

Subnet resource를 사용하면 Terraform이 subnet 리소스를 생성한 뒤에 별도의 [`azurerm_subnet_network_security_group_association` 리소스](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association)를 이용하여 NSG와 Subnet을 매핑해야 함.

Custom policy 적용 시 NSG가 없는 subnet과 VNet은 생성될 수 없기 때문에 NSG를 매핑하기도 전에 Policy로 인해 subnet을 생성할 수 없게 됨. 이를 방지하기 위해 VNet 리소스를 이용해 subnet을 생성한 뒤 data로 subnet을 가져오는 방식으로 변경.

> [!Note] 
> Subnet 자체 다른 설정을 modify 하려면 terraform import 를 통해 state를 동기화해야 함. 
> terraform import azurerm_subnet.example "/subscriptions/subscription_id/resourceGroups/resource_group_name/providers/Microsoft.Network/virtualNetworks/vnet_name/subnets/subnet_name"