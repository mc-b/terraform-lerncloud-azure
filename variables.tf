
# Allgemeine Variablen

variable "location" {
  description = "The Azure Region in which all resources in this example should be created."
  default = "West Europe"
}

# Public Variablen

variable "module" {
    type    = string
    default = "base"
}

variable "userdata" {
    description = "Cloud-init Script"
    default = "/../../modules/base.yaml"
}

variable "ports" {
    type    = list(number)
    default = [ 22, 80 ]
}

variable "mem" {
    type    = string
    default = "1GB"
}

# Umwandlung "mem" nach AWS Instance Type

variable "instance_type" {
  type = map
  default = {
    "1GB" = "Standard_B1s"
    "2GB" = "Standard_B1ms"
    "4GB" = "Standard_B2s"
    "8GB" = "Standard_B2ms"
    "16GB" = "Standard_B4ms"
  }
}

# wird nicht ausgewertet - nur zu Kompatibilitaet zu Mulitpass
variable "disk" {
    type    = string
    default = "32GB"
}

# wird nicht ausgewertet - nur zu Kompatibilitaet zu Mulitpass
variable "cpu" {
    default = 1
}

# Scripts

data "template_file" "userdata" {
  template = file(var.userdata)
}

