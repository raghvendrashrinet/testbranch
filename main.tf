resource "azurerm_resource_group" "rg1" {
 name     = "rg1"
  location = "east us"
}

resource "azurerm_storage_account" "stg1" {
  depends_on               = [azurerm_resource_group.rg1]
  name                     = "rg1stg1backend"
  location                 = "east us"
  resource_group_name      = "rg1"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}




resource "azurerm_storage_container" "tfstate" {
  depends_on            = [azurerm_storage_account.stg1]
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.stg1.id
  container_access_type = "private"
}

## VNET

resource "azurerm_virtual_network" "rg1vnet" {
  depends_on          = [azurerm_resource_group.rg1]
  name                = "rg1vnet"
  resource_group_name = "rg1"
  location            = "east us"
  address_space       = ["10.0.0.0/16"]

}


## SUBNET 

resource "azurerm_subnet" "rg1snet1" {
  depends_on           = [azurerm_virtual_network.rg1vnet]
  name                 = "rg1snet1"
  resource_group_name  = "rg1"
  virtual_network_name = "rg1vnet"
  address_prefixes     = ["10.0.0.0/24"]
}


## public ip 

resource "azurerm_public_ip" "pip1" {
  depends_on          = [azurerm_resource_group.rg1]
  name                = "pip1"
  resource_group_name = "rg1"
  location            = "east us"
  allocation_method   = "Static"
}


# nsg

resource "azurerm_network_security_group" "rg1nsg" {
  depends_on          = [azurerm_resource_group.rg1]
  name                = "g1nsg"
  location            = "east us"
  resource_group_name = "rg1"

}

# nsg rule

resource "azurerm_network_security_rule" "rg1nsgrule" {
  depends_on                  = [azurerm_network_security_group.rg1nsg]
  name                        = "rg1nsgrule"
  network_security_group_name = azurerm_network_security_group.rg1nsg.name
  resource_group_name         = azurerm_network_security_group.rg1nsg.resource_group_name
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}


# NIC

resource "azurerm_network_interface" "rg1nic1" {
  depends_on                  = [azurerm_network_security_group.rg1nsg]
  name                        = "rg1nic1"
  location                    = "east us"
  resource_group_name         = "rg1"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.rg1snet1.id
    public_ip_address_id          = azurerm_public_ip.pip1.id
    private_ip_address_allocation = "Dynamic"
  }
}

#nic nsg association

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.rg1nic1.id
  network_security_group_id = azurerm_network_security_group.rg1nsg.id
}


#VM
resource "azurerm_linux_virtual_machine" "rg1vm1" {
  depends_on            = [azurerm_network_interface.rg1nic1]
  name                  = "rg1vm1"
  resource_group_name   = "rg1"
  location              = "east us"
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"
  admin_password        = "P@ssw0rd1234!"
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.rg1nic1.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

