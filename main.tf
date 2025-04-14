# 1x Ressourcengruppe
resource "azurerm_resource_group" "lerncloud" {
  name     = var.module
  location = var.location
}

# 1x Netzwerk + Subnet
resource "azurerm_virtual_network" "lerncloud" {
  name                = "${var.module}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.lerncloud.name
}

resource "azurerm_subnet" "lerncloud" {
  name                 = "${var.module}-subnet"
  virtual_network_name = azurerm_virtual_network.lerncloud.name
  resource_group_name  = azurerm_resource_group.lerncloud.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 1x NSG für alle
resource "azurerm_network_security_group" "lerncloud" {
  name                = "${var.module}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.lerncloud.name

  # dynamische TCP Regeln
  dynamic "security_rule" {
    for_each = local.expanded_ports
    content {
      name                       = "tcp-port-${security_rule.value.port}"
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      source_address_prefix      = "*"
      destination_port_range     = security_rule.value.port
      destination_address_prefix = "*"
    }
  }

  # dynamische UDP Regeln
  dynamic "security_rule" {
    for_each = local.expanded_ports_udp
    content {
      name                       = "udp-port-${security_rule.value.port}"
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      source_address_prefix      = "*"
      destination_port_range     = security_rule.value.port
      destination_address_prefix = "*"
    }
  }

  # Eigene IP erlauben
  security_rule {
    name                       = "allow-ssh-me"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "${chomp(data.http.myip.response_body)}/32"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

# VMs dynamisch aus der Map erzeugen

resource "azurerm_public_ip" "vms" {
  for_each = var.machines

  name                = "${each.key}-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.lerncloud.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "vms" {
  for_each = var.machines

  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.lerncloud.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lerncloud.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vms[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "vms" {
  for_each = var.machines

  network_interface_id      = azurerm_network_interface.vms[each.key].id
  network_security_group_id = azurerm_network_security_group.lerncloud.id
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = var.machines

  name                = each.value.hostname
  resource_group_name = azurerm_resource_group.lerncloud.name
  location            = var.location
  size                = lookup(var.instance_type, var.memory, "Standard_B2s")

  admin_username                  = "ubuntu"
  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false
  custom_data                     = base64encode(each.value.userdata)
  network_interface_ids           = [azurerm_network_interface.vms[each.key].id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-noble"
    sku       = "24_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
