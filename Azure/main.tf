provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

provider "azurerm" {
  features {}
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
  subscription_id = ""
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "Terraform1"
  location = "East US"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet one
resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create subnet two
resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create virtual machine one
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "VM1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  # admin_password      = "ComplexPassword1234!"
  network_interface_ids = [azurerm_network_interface.nic1.id]
  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("../Azure/.ssh/my_azure_vm_key.pub")
  }
}

# Create network interface for VM1
resource "azurerm_network_interface" "nic1" {
  name                = "vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine two
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "VM2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  # admin_password      = "ComplexPassword1234!"
  network_interface_ids = [azurerm_network_interface.nic2.id]
  os_disk {
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("../Azure/.ssh/my_azure_vm_key.pub")
  }
}

# Create network interface for VM2
resource "azurerm_network_interface" "nic2" {
  name                = "vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myAKSCluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akscluster"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    vnet_subnet_id  = azurerm_subnet.subnet1.id
    enable_auto_scaling = true
    min_count       = 1
    max_count       = 3
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.10.0.0/16"  
    dns_service_ip    = "10.10.0.10"  
  }
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
  }
}

resource "helm_release" "postgres" {
  name       = "my-postgres"
  namespace  = "default"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  version    = "15.2.5"

  set {
    name  = "postgresqlUsername"
    value = "postgresuser"
  }

  set {
    name  = "postgresqlPassword"
    value = "postgrespassword"
  }

  set {
    name  = "postgresqlDatabase"
    value = "mydatabase"
  }
}

resource "kubernetes_deployment" "nginx" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  metadata {
    name = "nginx"
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  metadata {
    name = "nginx"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
