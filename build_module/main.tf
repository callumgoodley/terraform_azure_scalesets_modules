resource "azurerm_resource_group" "group1" {

  name     = var.rgname
  location = var.location
}

resource "azurerm_virtual_network" "vn1" {
  name                = "${var.location}-vn"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.group1.name
}

resource "azurerm_subnet" "sn1" {
  name                 = "uksub"
  resource_group_name  = azurerm_resource_group.group1.name
  virtual_network_name = azurerm_virtual_network.vn1.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_virtual_machine_scale_set" "scaleset1" {
  name                = "${var.location}-scaleset-1"
  location            = var.location
  resource_group_name = azurerm_resource_group.group1.name
  
  upgrade_policy_mode  = "Manual"

  
  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 1
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "${var.location}-vm"
    admin_username       = "myadmin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4fKcLaMlO9qUL7Ydng2VU+PjvXNvm7+5JI928sEXAG3Su6Yqg5lSRDyB/1C2vWaE7welI3jpT1Cjm1g9Y6xv8a+uKSsqTvHFej5QkpQI0BvMcPgjsdeZzRi3QTuNk0QAJd3tVWv3trBhlS1datJRg8mO4FcsKTSV48OR3TCAY/iDF8mmCUiFH+OG2d93h149pg9koYqzONHek8yELdlu+cpiX5kbyi7Wl4MF48Eq7jerRlpMwL7s0ehtOT83xqaaL1pf6oPDZOfmJ5OHYmtlFGRjng/oqgLozI7uvOZGErzDPWBCy30t5erFKFUIOS9qI/6wM8AoOFTsUhwPhLQ1v callumgoodley@vm"
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "${var.location}-IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.sn1.id
    }
  }

  tags = {
    environment = "${var.env}"
  }
}

resource "azurerm_monitor_autoscale_setting" "autoscale1" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.group1.name
  location            = var.location
  target_resource_id  = azurerm_virtual_machine_scale_set.scaleset1.id

  profile {
    name = "startProfile"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    recurrence {
      timezone  = var.timezone
      days      = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours     = var.start_time
      minutes   = [0]
    }
   }
  
  profile {
    name = "stopProfile"

    capacity {
      default = 0
      minimum = 0
      maximum = 0
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_virtual_machine_scale_set.scaleset1.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    recurrence {
      timezone  = var.timezone
      days      = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      hours     = var.stop_time
      minutes   = [0]
    }
    }
} 
