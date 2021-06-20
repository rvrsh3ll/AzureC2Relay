#Azure location for deployment
variable "location"    { default = "eastus"}

//Your profile name , must be placed in Ressources/ (Just the name here, not path!)
variable "PROFILE_FILE"    { default = "jquery-c2.4.2.profile" }

#Azure function name without <.azurewebsites.net>
variable "func_name"    { default = "<AZURE FUNC NAME>" }

#Site to redirect traffic to that dosent not match mall profile
variable "decoy_website"    { default = "https://microsoft.com" }

# IP Address of your C2 Server
variable "ts_ip" { default = "<IP ADDRESS>"}

#MUST BE REPLACED TO AVOID COLISSION WITH OTHER AZURE GLOBAL RESSOURCES 
variable "uniq_prefix"    { default = "<RANDOM 4 LETTERS>" }

#No need to edit anything below this line!
variable "resource_group"    { default = "relay-rg"}
variable "plan_name"    { default = "relay-appsvc"}
variable "stor_name"    { default = "relaydata001"}
variable "nic_name"    { default = "relay-1nic" }
variable "public_ip_name"    { default = "relay-pia" }
variable "nic_sec_name"    { default = "relay-nsg" }
variable "subnet_one_name"    { default = "vm-subnet" }
variable "subnet_two_name"    { default = "func-subnet" }
variable "vnet_name"    { default = "relay-vnet" }
variable "ai_name"    { default = "appai" }

variable "func_zip_path"    { default = "AzureC2Relay.zip" }