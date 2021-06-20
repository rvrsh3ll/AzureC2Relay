# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.uniq_prefix}${var.resource_group}"
  location = "${var.location}"
}


resource "azurerm_storage_account" "storage" {
  name                     = "${var.uniq_prefix}${var.stor_name}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "servplan" {
  name                =  "${var.uniq_prefix}${var.plan_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "P1V2"
  }
}

resource "azurerm_function_app" "func" {
  name                       = "${var.func_name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.servplan.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
  os_type                    = "linux"
  version	                 = "~2"
  app_settings = {
    FUNCTIONS_EXTENSION_VERSION                 = "~2"
    FUNCTIONS_WORKER_RUNTIME                    = "dotnet"
    SCM_DO_BUILD_DURING_DEPLOYMENT              = true
    MalleableProfileB64                          = "${data.local_file.ParseMalleable.content}"
    RealC2EndPoint								= "https://${var.ts_ip}:443/"
  	DecoyRedirect								= "${var.decoy_website}"
	APPINSIGHTS_INSTRUMENTATIONKEY				= "${azurerm_application_insights.funcai.instrumentation_key}"
    
    }

	site_config {
		always_on   = "true"
	}

   depends_on = [
    data.local_file.ParseMalleable,
	azurerm_application_insights.funcai
  ]
  

}

resource "azurerm_application_insights" "funcai" {
  name                = "${var.uniq_prefix}${var.ai_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}



resource "azurerm_virtual_network" "vnet" {
  name                = "${var.uniq_prefix}${var.vnet_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.uniq_prefix}${var.subnet_one_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
 depends_on = [
   azurerm_virtual_network.vnet,
   ]


}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.uniq_prefix}${var.subnet_two_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

    delegation {
      name = "subnetdelegation"

      service_delegation {
        name    = "Microsoft.Web/serverFarms"
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }

 depends_on = [
   azurerm_virtual_network.vnet,
   ]

}

resource "azurerm_public_ip" "pubip" {
  name                = "${var.uniq_prefix}${var.public_ip_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  }

resource "time_sleep" "wait_60_seconds" {
  depends_on = [null_resource.funcrestart]

  create_duration = "60s"
}

resource "null_resource" "funcrestart" {

  provisioner "local-exec" {
    command = "az functionapp restart --name ${var.func_name} --resource-group ${azurerm_resource_group.rg.name}"
	}

 depends_on = [
    azurerm_app_service_virtual_network_swift_connection.funcass,
  ]

}

resource "null_resource" "funcdep" {
  provisioner "local-exec" {
    command = "az functionapp deployment source config-zip -g ${azurerm_resource_group.rg.name} -n ${var.func_name} --src ${var.func_zip_path} --build-remote true"
  }

 depends_on = [
    time_sleep.wait_60_seconds,
  ]

}

resource "azurerm_app_service_virtual_network_swift_connection" "funcass" {
  app_service_id = azurerm_function_app.func.id
  subnet_id      = azurerm_subnet.subnet2.id

   depends_on = [
	   azurerm_function_app.func,
	   azurerm_subnet.subnet2
   ]
}

resource "null_resource" "shell" {
  provisioner "local-exec" {
    command = "dotnet ParseMalleable/ParseMalleable.dll Ressources/${var.PROFILE_FILE} > ParsedMalleableData.txt"
  }
 
}

data "local_file" "ParseMalleable" {
		filename = "ParsedMalleableData.txt"	
		depends_on = [null_resource.shell,]
}