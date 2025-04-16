#!/bin/bash

# Crear namespaces necesarios
kubectl create namespace prometheus
kubectl create namespace test-monitoreo

# Añadir repositorios de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus Operator en el namespace prometheus
echo "Instalando Prometheus Operator..."
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus
  #-n prometheus -f values.yaml --create-namespace
# Exponer Prometheus como NodePort
kubectl patch svc prometheus-kube-prometheus-prometheus -n prometheus \
  -p '{"spec": {"type": "NodePort"}}'

# Desplegar aplicación de prueba con métricas en test-monitoreo
echo "Desplegando aplicación de ejemplo NGINX con exportador de métricas..."
#kubectl apply -f nginx-prometheus-deployment.yaml 
kubectl apply -f monitor2.yaml  -n test-monitoreo
#echo "Desplegando aplicación de ejemplo FLASK con exportador de métricas..."
#kubectl apply -f flask-deployment.yaml 

# Esperar a que los servicios estén disponibles
echo "Esperando a que los servicios estén disponibles..."
sleep 30

# Obtener la URL de acceso a Prometheus
PROMETHEUS_PORT=$(kubectl get svc prometheus-kube-prometheus-prometheus -n prometheus -o jsonpath="{.spec.ports[0].nodePort}")
# Obtener la URL de acceso a grafana
GRAFANA_PORT=$(kubectl get svc prometheus-grafana  -n prometheus -o jsonpath="{.spec.ports[0].nodePort}")

# Configurar reglas de firewall en Minikube si está en uso
if command -v minikube &> /dev/null; then
  echo "Abriendo Prometheus en Minikube..."
  minikube service prometheus-kube-prometheus-prometheus --url -n prometheus  
fi
if command -v minikube &> /dev/null; then
  echo "Abriendo Prometheus en Minikube..."
  minikube service prometheus-grafana --url -n prometheus 
fi

echo "============================================"
echo "INFORMACIÓN DE ACCESO"
echo "============================================"
echo "Prometheus disponible en:"
echo "$ip1"
echo "  http://<IP_DEL_CLUSTER>:$PROMETHEUS_PORT"
echo "Grafana disponible en:"
echo "  http://<IP_DEL_CLUSTER>:$GRAFANA_PORT"
echo "Verificar estado de los pods:"
kubectl get pods -n prometheus
kubectl get pods -n test-monitoreo
echo "============================================"
