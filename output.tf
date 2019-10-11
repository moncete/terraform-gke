#output "redis_host" {
#  value = "${google_redis_instance.Prueba-Redis.host}"
#}
#output "redis_port" {
#  value = "${google_redis_instance.Prueba-Redis.port}"
#}
#output "redis_current_location_id" {
#  value = "${google_redis_instance.Prueba-Redis.current_location_id}"
#}
#
# output "endpoint" {
#   description = "The IP address of the cluster master."
#   sensitive   = false
#   value       = "${data.google_container_cluster.gke-cluster.endpoint}"
# }
#
# output "client_certificate" {
#   description = "Public certificate used by clients to authenticate to the cluster endpoint."
#   value       = base64decode(google_container_cluster.gke-cluster.master_auth[0].client_certificate)
# }
#
# output "client_key" {
#   description = "Private key used by clients to authenticate to the cluster endpoint."
#   value       = base64decode(google_container_cluster.gke-cluster.master_auth[0].client_key)
# }
#
# output "cluster_ca_certificate" {
#   description = "The public certificate that is the root of trust for the cluster."
#   value       = base64decode(google_container_cluster.gke-cluster.master_auth[0].cluster_ca_certificate)
# }