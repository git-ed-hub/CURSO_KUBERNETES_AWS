# Script para instalar Prometheus & Grafana
~~~sh
cat <<'EOL' > script.sh
#!/bin/bash
# Levantar el entorno
minikube start --cpus=2 --memory=6000 --kubernetes-version=v1.30.0
minikube addons enable metrics-server
# install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
# agregar el repo
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
# actualizar e instalar
sudo apt-get update
sudo apt-get install helm
# Crear archivo prometheus-values.yaml 
cat <<'EOF' > prometheus-values.yaml  
grafana:
  image:
    tag: 11.2.1
  adminPassword: test123
EOF

# Actualizamos los repositorios
helm repo add prometheus-community \
https://prometheus-community.github.io/helm-charts
helm repo update

# Instalamos prometheus operator
helm install monitoring \
prometheus-community/kube-prometheus-stack \
--values prometheus-values.yaml \
--version 65.1.0  \
--namespace monitoring \
--create-namespace
EOL
chmod +x script.sh
./script.sh
~~~
