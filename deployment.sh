#!/usr/bin/env bash

################################################################################
### Script deploying environment for the OTEL training
###
################################################################################
###########################################################################################################
####  Required Environment variable :
#### ENVIRONMENT_URL=<with your environment URL (with'https'). Example: https://{your-environment-id}.live.dynatrace.com> or {your-domain}/e/{your-environment-id}
#### API_TOKEN : api token with the following right : metric ingest, trace ingest, and log ingest and Access problem and event feed, metrics and topology
#########################################################################################################
### Pre-flight checks for dependencies
if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq before continuing"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Please install git before continuing"
    exit 1
fi


if ! command -v helm >/dev/null 2>&1; then
    echo "Please install helm before continuing"
    exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
    echo "Please install kubectl before continuing"
    exit 1
fi

while [ $# -gt 0 ]; do
  case "$1" in
  --environment-url)
    ENVIRONMENT_URL="$2"
    shift 2
    ;;
  --api-token)
    API_TOKEN="$2"
    shift 2
    ;;
  *)
    echo "Warning: skipping unsupported option: $1"
    shift
    ;;
  esac
done

if [ -z "$ENVIRONMENT_URL" ]; then
  echo "Error: environment-url not set!"
  exit 1
fi

if [ -z "$API_TOKEN" ]; then
  echo "Error: api-token not set!"
  exit 1
fi




################################################################################
### Clone repo
HOME_SCRIPT_DIRECTORY=/home/dtu_training/hotdayscript
echo "SCript folder is $HOME_SCRIPT_DIRECTORY"

CLUSTER_NAME="Hotday2023"
VERSION=v1.0.0

#### Deploy the cert-manager
echo "Deploying Cert Manager ( for OpenTelemetry Operator)"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
# Wait for pod webhook started
kubectl wait pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --for=condition=Ready --timeout=2m
# Deploy the opentelemetry operator
echo "Deploying the OpenTelemetry Operator"
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

#Deploy the OpenTelemetry Collector
echo "Deploying Otel Collector"
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/rbac.yaml
sed -i "s,DT_TENANT_URL,$ENVIRONMENT_URL," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-manifest.yaml
sed -i "s,DT_TOKEN,$API_TOKEN," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-manifest.yaml
sed -i "s,DT_TENANT_URL,$ENVIRONMENT_URL," $HOME_SCRIPT_DIRECTORY/exercice/01_collector/metrics/openTelemetry-manifest.yaml
sed -i "s,DT_TOKEN,$API_TOKEN," $HOME_SCRIPT_DIRECTORY/exercice/01_collector/metrics/openTelemetry-manifest.yaml
sed -i "s,DT_TENANT_URL,$ENVIRONMENT_URL,"  $HOME_SCRIPT_DIRECTORY/exercice/01_collector/trace/openTelemetry-manifest.yaml
sed -i "s,DT_TOKEN,$API_TOKEN," $HOME_SCRIPT_DIRECTORY/exercice/01_collector/trace/openTelemetry-manifest.yaml
CLUSTERID=$(kubectl get namespace kube-system -o jsonpath='{.metadata.uid}')
sed -i "s,CLUSTER_ID_TOREPLACE,$CLUSTERID," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml
sed -i "s,CLUSTER_ID_TOREPLACE,$CLUSTERID," $HOME_SCRIPT_DIRECTORY/exercice/02_auto-instrumentation/openTelemetry-sidecar.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTER_NAME," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTER_NAME," $HOME_SCRIPT_DIRECTORY/exercice/02_auto-instrumentation/openTelemetry-sidecar.yaml
#wait for the opentelemtry operator webhook to start
kubectl wait pod --namespace default -l app.kubernetes.io/name=opentelemetry-operator -n  opentelemetry-operator-system --for=condition=Ready --timeout=2m
#Deploying the fluent operator
echo "Deploying FluentOperator"
helm install fluent-operator --create-namespace -n kubesphere-logging-system https://github.com/fluent/fluent-operator/releases/download/v1.0.0/fluent-operator.tgz

#Deploy Dynatrace Operator
kubectl create namespace dynatrace
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$API_TOKEN" --from-literal="dataIngestToken=$API_TOKEN"
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes-csi.yaml
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s
sed -i "s,TENANTURL_TOREPLACE,$DT_TENANT_URL," dynatrace/dynakube.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTER_NAME," dynatrace/dynakube.yaml
kubectl apply -f dynatrace/dynakube.yaml
echo "Deploying Kubecost"
# Deploy Kubecost
kubectl create namespace kubecost
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm install kubecost kubecost/cost-analyzer --namespace kubecost --set kubecostToken="aGVucmlrLnJleGVkQGR5bmF0cmFjZS5jb20=xm343yadf98" --set serviceMonitor.enabled=true

# Deploy the fluent agents
sed -i "s,API_TOKEN_TO_REPLACE,$API_TOKEN," exercice/03_Fluent/cluster_output_http.yaml
sed -i "s,TENANT_TO_REPLACE,$ENVIRONMENT_URL," exercice/03_Fluent/cluster_output_http.yaml
sed -i "s,CLUSTER_ID_TO_REPLACE,$CLUSTERID," fluent/clusterfilter.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTERNAME," fluent/clusterfilter.yaml
kubectl apply -f fluent/fluentbit_deployment.yaml  -n kubesphere-logging-system
#Deploy demo Application
echo "Deploying Hipstershop"
kubectl create ns otel-demo
kubectl label namespace otel-demo app=nodynatrace
sed -i "s,VERSION_TO_REPLACE,$VERSION," kubernetes-manifests/K8sdemo.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml -n otel-demo
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml -n otel-demo

#manage the hipster-shop namespace
kubectl create ns hipster-shop
kubectl label namespace hipster-shop app=nodynatrace
sed -i "s,TENANT_TO_REPLACE,$ENVIRONMENT_URL," exercice/02_auto-instrumentation/k8Sdemo-nootel.yaml
sed -i "s,API_TOKEN_TO_REPLACE,$API_TOKEN," exercice/02_auto-instrumentation/k8Sdemo-nootel.yaml
# Echo environ*
echo "========================================================"
echo "Environment fully deployed "
echo "========================================================"


