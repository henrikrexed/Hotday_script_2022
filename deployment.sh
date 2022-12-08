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


DT_HOST=$(echo $ENVIRONMENT_URL | grep -oP 'https://\K\S+')



HOME_SCRIPT_DIRECTORY=/home/dtu_training/HOT_DAY_SCRIPT
echo "Script folder is $HOME_SCRIPT_DIRECTORY"

CLUSTER_NAME="Hotday2023"
VERSION=v1.0.0

##Get IP adress of Traefik
IP=$(kubectl get svc traefik -n kube-system -ojson | jq -j '.status.loadBalancer.ingress[].ip')
sed -i "s,IP_TO_REPLACE,$IP," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml
sed -i "s,IP_TO_REPLACE,$IP," $HOME_SCRIPT_DIRECTORY/exercice/02_auto-instrumentation/k8Sdemo-nootel.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/traefic/traefic_deploy.yaml

#### Deploy the cert-manager
echo "Deploying Cert Manager ( for OpenTelemetry Operator)"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.yaml
# Wait for pod webhook started
kubectl wait pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --for=condition=Ready --timeout=2m
kubectl rollout status deployment cert-manager-webhook -n cert-manager

#Modify local files
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
#Deploying the fluent operator
echo "Deploying FluentOperator"
helm install fluent-operator --create-namespace -n kubesphere-logging-system https://github.com/fluent/fluent-operator/releases/download/v1.0.0/fluent-operator.tgz


#Deploy Dynatrace Operator
kubectl create namespace dynatrace
sed -i "s,DT_TENANT_URL,$ENVIRONMENT_URL," $HOME_SCRIPT_DIRECTORY/dynatrace/dynakube.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTER_NAME,"  $HOME_SCRIPT_DIRECTORY/dynatrace/dynakube.yaml

# Deploy the opentelemetry operator
echo "Deploying the OpenTelemetry Operator"
echo "Wait for the certmanager"
sleep 40
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

#Deploy Dynatrace operator
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=$API_TOKEN" --from-literal="dataIngestToken=$API_TOKEN"
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes-csi.yaml
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s
sed -i "s,TENANTURL_TOREPLACE,$ENVIRONMENT_URL," $HOME_SCRIPT_DIRECTORY/dynatrace/dynakube.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTER_NAME," $HOME_SCRIPT_DIRECTORY/dynatrace/dynakube.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/dynatrace/dynakube.yaml

# Deploy the fluent agents
sed -i "s,API_TOKEN_TO_REPLACE,$API_TOKEN," $HOME_SCRIPT_DIRECTORY/exercice/03_Fluent/cluster_output_http.yaml
sed -i "s,TENANT_TO_REPLACE,$DT_HOST," $HOME_SCRIPT_DIRECTORY/exercice/03_Fluent/cluster_output_http.yaml
sed -i "s,CLUSTER_ID_TO_REPLACE,$CLUSTERID," $HOME_SCRIPT_DIRECTORY/exercice/03_Fluent/clusterfilter.yaml
sed -i "s,CLUSTER_NAME_TO_REPLACE,$CLUSTERNAME," $HOME_SCRIPT_DIRECTORY/exercice/03_Fluent/clusterfilter.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/fluent/fluentbit_deployment.yaml  -n kubesphere-logging-system
#Deploy demo Application
kubectl wait pod --namespace default -l app.kubernetes.io/name=opentelemetry-operator -n  opentelemetry-operator-system --for=condition=Ready --timeout=2m

kubectl create ns otel-demo
kubectl label namespace otel-demo app=nodynatrace
kubectl label namespace kubesphere-logging-system app=nodynatrace
kubectl label namespace opentelemetry-operator-system app=nodynatrace
kubectl label namespace default app=nodynatrace
sed -i "s,VERSION_TO_REPLACE,$VERSION," $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml -n otel-demo
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml -n otel-demo
echo "Deploying Otel Collector"
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/rbac.yaml
kubectl apply -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-manifest.yaml
#manage the hipster-shop namespace
echo "Deployint application"
kubectl create ns hipster-shop
kubectl label namespace hipster-shop app=nodynatrace
sed -i "s,TENANT_TO_REPLACE,$ENVIRONMENT_URL," $HOME_SCRIPT_DIRECTORY/exercice/02_auto-instrumentation/k8Sdemo-nootel.yaml
sed -i "s,API_TOKEN_TO_REPLACE,$API_TOKEN," $HOME_SCRIPT_DIRECTORY/exercice/02_auto-instrumentation/k8Sdemo-nootel.yaml
# Echo environ*
echo "========================================================"
echo "Environment fully deployed "
echo "========================================================"


