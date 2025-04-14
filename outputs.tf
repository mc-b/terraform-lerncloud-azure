output "ip_vm" {
  description = "Öffentliche IP-Adressen aller VMs"
  value = {
    for k in keys(var.machines) :
    k => azurerm_linux_virtual_machine.vms[k].public_ip_address
  }
}

output "fqdn_vm" {
  description = "FQDNs (Computername) aller VMs"
  value = {
    for k in keys(var.machines) :
    k => azurerm_linux_virtual_machine.vms[k].computer_name
  }
}

output "fqdn_private" {
  description = "FQDNs (Computername) aller VMs"
  value = {
    for k in keys(var.machines) :
    k => azurerm_linux_virtual_machine.vms[k].computer_name
  }
}

output "description" {
  description = "Beschreibungstexte der VMs"
  value = {
    for k, v in var.machines :
    k => lookup(v, "description", "")
  }
}
