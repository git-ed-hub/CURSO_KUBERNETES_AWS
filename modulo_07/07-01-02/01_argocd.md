~~~sh
cat <<'EOT' > install_argo.sh
#!/bin/bash
SERVER=$(hostname -I | awk '{print $1}')
# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install -y apt-transport-https
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm 

#Install minikube
curl -LO https://github.com/kubernetes/minikube/releases/download/v1.34.0/minikube_1.34.0-0_amd64.deb
sudo dpkg -i minikube_1.34.0-0_amd64.deb

# Iniciamos minikube
minikube start --cpus=4 --memory=6000 --kubernetes-version=v1.31.0

# Install kubectl
sudo snap install kubectl --classic

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install CLI argo
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Esperar estado del pod runing
sleep 20
PARTPOD="argocd-server"
NAMESPACE="argocd"
POD_NAME=$(kubectl get po -n $NAMESPACE |grep $PARTPOD | awk '{print $1}')
while true; do
    POD_STATUS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    # Verifica si el pod está en estado "Running"
    if [ "$POD_STATUS" == "Running" ]; then
        echo "El pod $POD_NAME está en estado Running. Continuando..."
        break
    else
        echo "El pod $POD_NAME no está en estado Running (actual: $POD_STATUS). Esperando 10 segundos..."
        sleep 10
    fi
done
# Generar el password
clear
echo "Accede a Argo con el siguiente pass: "
argocd admin initial-password -n argocd
read -p "Primero coloca el servicio porforward para argo antes de continuar..."
argocd login $SERVER:8081

argocd cluster add minikube
echo "Actualiza el password "
argocd account update-password
echo "Listo argocd ya esta instalado, listo para configurar"
echo "************************************************************************************"
echo "**                                     new app                                    **"
echo "**                             application name: flappybird                       **"
echo "**                                  projectl name: default                        **"
echo "**                                sync policy: Automatic                          **"
echo "**   reporitory utl: https://github.com/git-ed-hub/flappybird-deployment.git      **"
echo "**                                    revision: main                              **"
echo "**                                        path: .                                 **"
echo "**                        cluster url: https://kubernetes.default.svc             **"
echo "**                                namespace: default                              **"
echo "**                                      Create                                    **"
echo "************************************************************************************"
EOT
chmod +x install_argo.sh
./install_argo.sh

# Port Forward argocd
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8081:443

~~~
