variable "credentials_file" {
  default = "cluster-k8s-437300-65cea77a74c6.json"
}

variable "machine_type" {
  default = "n2-standard-2"
}

variable "image" {
  default = "ubuntu-2204-jammy-v20230919"
}

variable "zone" {
  default = "us-east1-b"
}

variable "region" {
  default = "us-east1"
}

variable "project" {
  default = "cluster-k8s-437300"
}

variable "user-data" {
  default = <<-EOF
    #cloud-config
    runcmd:
      - curl -o /tmp/setup-container.sh https://raw.githubusercontent.com/sandervanvugt/cka/refs/heads/master/setup-container.sh
      - curl -o /tmp/setup-kubetools.sh https://raw.githubusercontent.com/sandervanvugt/cka/refs/heads/master/setup-kubetools.sh
      - chmod +x /tmp/setup-container.sh
      - chmod +x /tmp/setup-kubetools.sh
      - sleep 10
      - /tmp/setup-container.sh
      - /tmp/setup-kubetools.sh
    EOF
}