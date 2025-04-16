#!/bin/bash

# Crear namespace para Prometheus
kubectl create namespace prometheus

# Crear namespace para aplicaciones de prueba
kubectl create namespace test-monitoreo

# Añadir repositorio de Helm para Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus usando el archivo values.yaml
helm install prometheus prometheus-community/prometheus \
  -n prometheus \
  -f values.yaml

# Exponer Prometheus como NodePort para acceder desde el exterior
kubectl expose service prometheus-server \
  -n prometheus \
  --type=NodePort \
  --target-port=9090 \
  --name=prometheus-server-ext

# Si estás usando minikube, obtener la URL para acceder a Prometheus
if command -v minikube &> /dev/null; then
  echo "Obteniendo URL de Prometheus en minikube..."
  minikube service prometheus-server-ext --url -n prometheus
fi

# Desplegar la aplicación NGINX con exportador de métricas
kubectl apply -f nginx-prometheus-deployment.yaml

# Verificar que todo está funcionando
echo "Esperando a que los pods estén listos..."
sleep 10
echo "Pods de Prometheus:"
kubectl get pods -n prometheus
echo "Pods de aplicación de prueba:"
kubectl get pods -n test-monitoreo

echo "============================================"
echo "Instalación completa. Puedes acceder a Prometheus mediante la URL proporcionada arriba."
echo "Para verificar las métricas, navega a Status > Targets en la interfaz web de Prometheus."
echo "============================================"