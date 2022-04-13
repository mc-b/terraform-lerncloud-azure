###
#   holt die eigene IP-Adresse, z.B. fuer Firewalls
#

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
