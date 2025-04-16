#!/bin/bash

# Colores para mejor legibilidad
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con formato
print_section() {
  echo -e "${GREEN}==== $1 ====${NC}"
}

print_info() {
  echo -e "${YELLOW}$1${NC}"
}

# Crear namespaces necesarios
print_section "CREANDO NAMESPACES"
kubectl create namespace prometheus
kubectl create namespace test-monitoreo

# Añadir repositorios de Helm
print_section "CONFIGURANDO HELM"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus Operator en el namespace prometheus
print_section "INSTALANDO PROMETHEUS OPERATOR"
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus -f values.yaml
# Si necesitas valores personalizados, descomenta la siguiente línea:
# helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus -f values.yaml --create-namespace

# Exponer servicios como NodePort
print_section "CONFIGURANDO SERVICIOS PARA ACCESO EXTERNO"
echo "Configurando Prometheus como NodePort..."
kubectl patch svc prometheus-kube-prometheus-prometheus -n prometheus \
  -p '{"spec": {"type": "NodePort"}}'

echo "Configurando Grafana como NodePort..."
kubectl patch svc prometheus-grafana -n prometheus \
  -p '{"spec": {"type": "NodePort"}}'

# Desplegar aplicación de prueba con métricas en test-monitoreo
print_section "DESPLEGANDO APLICACIONES DE PRUEBA"
echo "Desplegando NGINX con exportador de métricas..."
kubectl apply -f monitor2.yaml -n test-monitoreo

# Opción para desplegar Flask si es necesario
# echo "Desplegando aplicación Flask con exportador de métricas..."
# kubectl apply -f flask-deployment.yaml

# Esperar a que los servicios estén disponibles
print_info "Esperando a que los servicios estén disponibles..."
sleep 30

# Obtener puertos de servicios
PROMETHEUS_PORT=$(kubectl get svc prometheus-kube-prometheus-prometheus -n prometheus -o jsonpath="{.spec.ports[0].nodePort}")
GRAFANA_PORT=$(kubectl get svc prometheus-grafana -n prometheus -o jsonpath="{.spec.ports[0].nodePort}")

# Configurar acceso en Minikube si está en uso
if command -v minikube &> /dev/null; then
  print_section "CONFIGURANDO ACCESO EN MINIKUBE"
  echo "URL de Prometheus:"
  PROMETHEUS_URL=$(minikube service prometheus-kube-prometheus-prometheus --url -n prometheus)
  echo "$PROMETHEUS_URL"
  
  echo "URL de Grafana:"
  GRAFANA_URL=$(minikube service prometheus-grafana --url -n prometheus)
  echo "$GRAFANA_URL"
fi

# Mostrar información de acceso
print_section "INFORMACIÓN DE ACCESO"

echo "Prometheus disponible en:"
if [ -n "$PROMETHEUS_URL" ]; then
  echo "  $PROMETHEUS_URL"
else
  echo "  http://<IP_DEL_CLUSTER>:$PROMETHEUS_PORT"
fi

echo "Grafana disponible en:"
if [ -n "$GRAFANA_URL" ]; then
  echo "  $GRAFANA_URL"
else
  echo "  http://<IP_DEL_CLUSTER>:$GRAFANA_PORT"
fi

echo "Credenciales por defecto de Grafana:"
echo "  Usuario: admin"
echo "  Contraseña: prom-operator"

print_section "ESTADO DE LOS PODS"
echo "Pods en namespace prometheus:"
kubectl get pods -n prometheus
echo ""
echo "Pods en namespace test-monitoreo:"
kubectl get pods -n test-monitoreo

print_section "INSTALACIÓN COMPLETADA"
echo "Tu stack de monitoreo está listo para usar."
echo "Para acceder a los dashboards de Grafana, usa las credenciales proporcionadas arriba."