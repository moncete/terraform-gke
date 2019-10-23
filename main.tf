#Creacion del Cluster

resource "google_container_cluster" "gke-cluster" {
  name               = "${var.cluster_name}"
  network            = "${var.network}"
  location           = "${var.zone}"
  initial_node_count = 2

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  ####Avtivacion de VPC nativa (IP de alias)
  ip_allocation_policy {
    use_ip_aliases = true
  }
}

#Creacion del recurs de Memoryinstane
resource "google_redis_instance" "redis" {

  name            = "${var.cache_name}"
  memory_size_gb  = "${var.size_cache}"
  tier            = "${var.type_service}"
  region          = "${var.region}"
  location_id     = "${var.zone}"

  redis_version   = "${var.version_redis}"

  display_name    = "${var.name_display}"
}

###### Datos para Conexion a GKE y despligues #############
######### Autenticacion en cluster GKE 

data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file = false

  host                   = "https://${google_container_cluster.gke-cluster.endpoint}"
  token                  = "${data.google_client_config.default.access_token}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)}"
}

########################################

######### Creacion Namespace Monitoring
resource "kubernetes_namespace" "tiller" {
  metadata{
    name = "tiller"
  }
}
resource "kubernetes_namespace" "monitoring" {
  metadata{
    name = "monitoring"
  }
}

########################################

######### Creacion del ConfigMap 

resource "kubernetes_config_map" "redis" {
  metadata {
    name = "redisinstance"
  }

  data = {
    REDISHOSTIP = "${google_redis_instance.redis.host}"
    REDISPORT   = "${google_redis_instance.redis.port}"
  }
}

##################################

########### Creacion serviceaccount 

#resource "kubernetes_cluster_role_binding" "google-account" {
#  metadata {
#    name = "cluster-admin-binding"
#  }
#
#  role_ref {
#    kind = "ClusterRole"
#    name = "cluster-admin"
#    api_group = "rbac.authorization.k8s.io"
#  }
#  
#  subject {
#    kind = "User"
#    name = "${data.google_client_config.default.id}"
#    api_group = "rbac.authorization.k8s.io"
#  }
#}

resource "kubernetes_service_account" "tiller" {

  metadata {
    name      = "tiller"
    namespace = "tiller"
  }
}

resource "kubernetes_cluster_role_binding" "tiller"{
  metadata {
    name = "tiller-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "cluster-admin"
    
  }

  subject {
    api_group = ""
    kind = "ServiceAccount"
    name = "tiller"
    namespace = "tiller"
  }
}
############################################################## 


########################## Deploy con Helm ########################

provider "helm" {
  namespace = "tiller"
  service_account   = "tiller"

  kubernetes {
    load_config_file = false
  
    host                   = "https://${google_container_cluster.gke-cluster.endpoint}"
    token                  = "${data.google_client_config.default.access_token}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)}"
  }

}

#data "helm_repository" "stable" {
#    name    = "stable"
#    url     = "https://kubernetes-charts.storage.googleapis.com"
#  }

resource "helm_release" "grafana" {
  depends_on = [
    google_container_cluster.gke-cluster,
    kubernetes_namespace.tiller,
    kubernetes_namespace.monitoring,
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller
  ]
  namespace = "monitoring"
  name        = "grafana"
  repository  = "https://kubernetes-charts.storage.googleapis.com"
  chart       = "grafana"
  recreate_pods = "true"
  
  values      = [ "${file("./helmconf/grafanavalues.yaml")}" ]
}

resource "helm_release" "prometheus" {
  depends_on = [
    google_container_cluster.gke-cluster,
    kubernetes_namespace.tiller,
    kubernetes_namespace.monitoring,
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller
  ]
  namespace = "monitoring"
  name        = "prometheus"
  repository  = "https://kubernetes-charts.storage.googleapis.com"
  chart       = "prometheus"
  recreate_pods = "true"
  
  values      = [ "${file("./helmconf/prometheusvalues.yaml")}" ]
}

resource "helm_release" "influxdb" {
  depends_on = [
    google_container_cluster.gke-cluster,
    kubernetes_namespace.tiller,
    kubernetes_namespace.monitoring,
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller
  ]
  namespace = "monitoring"
  name        = "influxdb"
  repository  = "https://kubernetes-charts.storage.googleapis.com"
  recreate_pods = "true"
  chart       = "influxdb"
  
  values      = [ "${file("./helmconf/influxdbvalues.yaml")}" ]
}

resource "helm_release" "telegraf" {
  depends_on = [
    google_container_cluster.gke-cluster,
    kubernetes_namespace.tiller,
    kubernetes_namespace.monitoring,
    kubernetes_service_account.tiller,
    kubernetes_cluster_role_binding.tiller
  ]
  namespace = "monitoring"
  name        = "telegraf"
  repository  = "https://kubernetes-charts.storage.googleapis.com"
  recreate_pods = "true"
  chart       = "telegraf"

  set {
    name  = "single.enabled"
    value = "false"
  }

  values      = [ "${file("./helmconf/telegrafvalues.yaml")}" ]

}