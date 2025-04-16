#!/bin/bash

# Crear namespaces necesarios
kubectl create namespace prometheus
#kubectl create namespace grafana
kubectl create namespace test-monitoreo
kubectl create namespace test-monitoreo1

# Añadir repositorios de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Instalar Prometheus
echo "Instalando Prometheus..."
#helm install prometheus prometheus-community/prometheus \
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n prometheus \
  -f values.yaml

# Exponer Prometheus como NodePort
kubectl expose service prometheus-prometheus-kube-prometheus-prometheus-0  \
  -n prometheus \
  --type=NodePort \
  --target-port=9090 \
  --name=prometheus-server-ext

# Instalar Grafana
#echo "Instalando Grafana..."
#helm install grafana grafana/grafana \
#  -n grafana \
#  -f grafana-values.yaml

# Exponer Grafana como NodePort
#kubectl expose service grafana \
#  -n grafana \
#  --type=NodePort \
#  --target-port=3000 \
#  --name=grafana-ext

# Desplegar aplicación de ejemplo con métricas
echo "Desplegando aplicación de ejemplo NGINX con exportador de métricas..."
kubectl apply -f nginx-prometheus-deployment.yaml 

echo "Desplegando aplicación de ejemplo FLASK con exportador de métricas..."
kubectl apply -f flask-deployment.yaml 

# Esperar a que todo esté listo
echo "Esperando a que los servicios estén disponibles..."
sleep 30

# Mostrar información de acceso
echo "============================================"
echo "INFORMACIÓN DE ACCESO"
echo "============================================"

# URLs para minikube
if command -v minikube &> /dev/null; then
  echo "Prometheus URL:"
  minikube service prometheus-server-ext --url -n prometheus
  #echo "Grafana URL:"
  #minikube service grafana-ext --url -n grafana
  echo "Credenciales de Grafana:"
  echo "  Usuario: admin"
  echo "  Contraseña: admin (o la que configuraste en grafana-values.yaml)"
else
  # Si no es minikube
  echo "Para acceder a Prometheus:"
  kubectl get service prometheus-server-ext -n prometheus
  #echo "Para acceder a Grafana:"
  #kubectl get service grafana-ext -n grafana
  echo "Credenciales de Grafana:"
  echo "  Usuario: admin"
  echo "  Contraseña: admin (o la que configuraste en grafana-values.yaml)"
fi

echo "============================================"
echo "Verificar estado de los pods:"
echo "kubectl get pods -n prometheus"
#echo "kubectl get pods -n grafana"
echo "kubectl get pods -n test-monitoreo"
echo "kubectl get pods -n test-monitoreo1"
echo "============================================"