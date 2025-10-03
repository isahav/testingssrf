resource "null_resource" "safe_recon" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== SAFE RECON ==="
      echo "User: $(whoami)"
      echo "Container: $(cat /proc/1/cgroup 2>/dev/null | head -1)"
      echo "Cloud: $(curl -s --connect-timeout 1 http://169.254.169.254/ || echo 'Not AWS')"
      echo "Files: $(ls -la / 2>/dev/null | wc -l) items in root"
      echo "Processes: $(ps aux 2>/dev/null | wc -l) running"
    EOT
  }
}
