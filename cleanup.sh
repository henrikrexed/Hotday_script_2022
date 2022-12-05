#!/usr/bin/env bash
HOME_SCRIPT_DIRECTORY=/home/dtu_training/Hotday_script_2022
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/rbac.yaml
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-manifest.yaml

kubectl delete ns hipster-shop

kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/openTelemetry-sidecar.yaml -n otel-demo
kubectl delete -f $HOME_SCRIPT_DIRECTORY/kubernetes-manifests/K8sdemo.yaml -n otel-demo
kubectl delete ns otel-demo

kubectl delete -f $HOME_SCRIPT_DIRECTORY/fluent/fluentbit_deployment.yaml  -n kubesphere-logging-system


helm uninstall --namespace opentelemetry-operator-system  opentelemetry-operator
kubectl delete ns opentelemetry-operator-system

kubectl delete -f dynatrace/dynakube.yaml
kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes-csi.yaml
kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
kubectl -n dynatrace delete secret  dynakube
kubectl delete namespace dynatrace
helm uninstall fluent-operator -n kubesphere-logging-system
kubectl delete namespace kubesphere-logging-system
helm uninstall cert-manager -n cert-manager
kubectl delete -f kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.crds.yaml
kubectl delete ns cert-manager
rm -rf /home/dtu_training/Hotday_script_2022