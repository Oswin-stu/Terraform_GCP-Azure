CLI:

terraform init   

terraform plan   

terraform apply  

Destroy CLI:

terraform plan -destroy

terraform destroy

-----------------------------------------------------
GCP中，如果想Destroy，需要增加一行代碼：deletion_protection = false

以下是完整代碼：

resource "google_container_cluster" "primary" {
  name     = "my-gke-cluster"
  location = "us-central1"

  remove_default_node_pool = true
  initial_node_count = 1

  ip_allocation_policy {}

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  #設置刪除保護未false以允許刪除
  deletion_protection = false
}


根據以上修改後，運行一下步驟才能destroy：
1：terraform apply
2：terraform destroy


-------------------------------------------------------
Azure中：

provider "azurerm" {
  features {}
  client_id       = ""
  client_secret   = ""
  tenant_id       = ""
  subscription_id = ""
}

以上輸入自己的憑證

--------------------------------------------------------
Windows:
https://github.com/helm/helm/releases

macOS:
brew install helm


添加 Helm 仓库:
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update

搜索 PostgreSQL 的可用版本:
helm search repo bitnami/postgresql --versions
--------------------------------------------------------

GCP

1.  Multiple VMs in VPC and 2 private subnets:  

    gcloud compute instances list --project=ea2-terraform

    gcloud compute networks subnets list --project=ea2-terraform


2. Unique Kubernetes Application with database - 使用Helm部署了PostgreSQL数据库, 并且有一个使用Nginx的Kubernetes应用

    gcloud container clusters get-credentials my-gke-cluster --region us-central1 --project ea2-terraform

    kubectl config current-context

    kubectl get nodes

    kubectl get svc,po

3. LoadBalancer

    curl http://<EXTERNAL-IP>

    go to web


4. Connect Database:

    kubectl logs <POD-NAME>


    kubectl port-forward svc/my-postgres-postgresql 5432:5432

    other terminal:
    psql -h localhost -p 5432 -U postgresuser -d mydatabase


5. Cluster AutoScaler

    gcloud container node-pools describe my-node-pool --cluster my-gke-cluster --zone us-central1


6. Using Kubernetes Secret properly

    kubectl get secret my-postgres-postgresql -o yaml

    kubectl get statefulset my-postgres-postgresql

    kubectl describe statefulset my-postgres-postgresql


kubectl get secret my-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode
echo

--------------------------------------------------------

AZURE

1. Multiple VMs in VPC and 2 private subnets:  

    az account set --subscription "<subscription id>"

    az vm list --show-details --output table

    az network vnet list --query "[].{Name:name, Subnets:subnets}" --output json


2. Unique Kubernetes Application with database - 使用Helm部署了PostgreSQL数据库, 并且有一个使用Nginx的Kubernetes应用

    az account show

    az aks get-credentials --resource-group Terraform1 --name myAKSCluster

    kubectl get nodes

    kubectl config current-context

    kubectl get svc,po


    kubectl logs <POD-NAME>

3. LoadBalancer

    curl http://<EXTERNAL-IP>

    go to web


4. Connect Database:

    kubectl logs <POD-NAME>


    kubectl port-forward svc/my-postgres-postgresql 5432:5432

    other terminal:
    psql -h localhost -p 5432 -U postgresuser -d mydatabase


5. Cluster AutoScaler:

    az aks nodepool show --cluster-name myAKSCluster --name default --resource-group Terraform1

    az aks show --resource-group Terraform1 --name myAKSCluster --output table


6. Using Kubernetes Secret properl
    kubectl get secret my-postgres-postgresql -o yaml

    kubectl get statefulset my-postgres-postgresql

    kubectl describe statefulset my-postgres-postgresql

kubectl get secret my-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode
echo



-------------------------------------------------------------------
Database :
kubectl port-forward svc/my-postgres-postgresql 5432:5432

Download PostgreSQL:
https://www.enterprisedb.com/downloads/postgres-postgresql-downloads

----------------------------------------


GCP switch project:

gcloud projects list

gcloud config set project <another-project-id>

gcloud config list project






