#!/usr/bin/env bash
HOME_SCRIPT_DIRECTORY=/home/dtu_training/Hotday_script_2022
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/rbac.yaml
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-manifest.yaml

kubectl delete ns hipster-shop

kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml -n otel-demo
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml -n otel-demo
kubectl delete ns otel-demo

kubectl delete -f $HOME_SCRIPT_DIRECTORY/fluent/fluentbit_deployment.yaml  -n kubesphere-logging-system

kubectl delete -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml
helm uninstall kubecost kubecost/cost-analyzer -n kubecost
kubectl delete namespace kubecost
kubectl delete -f dynatrace/dynakube.yaml
kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes-csi.yaml
kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl -n dynatrace delete secret  dynakube
kubectl delete namespace dynatrace
helm uninstall fluent-operator -n kubesphere-logging-system
kubectl delete namespace kubesphere-logging-system
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml

rm -rf /home/dtu_training/Hotday_script_2022