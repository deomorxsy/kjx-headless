#!/bin/sh

# delete all crd (CustomResourceDefinition) related to the kube-prometheus-stack
sudo k3s kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
sudo k3s kubectl delete crd alertmanagers.monitoring.coreos.com
sudo k3s kubectl delete crd podmonitors.monitoring.coreos.com
sudo k3s kubectl delete crd probes.monitoring.coreos.com
sudo k3s kubectl delete crd prometheusagents.monitoring.coreos.com
sudo k3s kubectl delete crd prometheuses.monitoring.coreos.com
sudo k3s kubectl delete crd prometheusrules.monitoring.coreos.com
sudo k3s kubectl delete crd scrapeconfigs.monitoring.coreos.com
sudo k3s kubectl delete crd servicemonitors.monitoring.coreos.com
sudo k3s kubectl delete crd thanosrulers.monitoring.coreos.com

# delete all deployments
sudo k3s kubectl delete --all deployments --namespace=kps

# delete the prometheus node exporter service account
sudo k3s kubectl delete serviceaccount/prometheus-prometheus-node-exporter -n=kps

# delete all remaining serviceaccounts
sudo k3s kubectl delete --all serviceaccount -n=kps

# delete remainings dangling pods
sudo k3s kubectl delete --all pod --namespace=kps

# delete all remaining services under the namespace
sudo k3s kubectl delete svc --all -n kps

# delete all remaining secrets under the namespace
sudo k3s kubectl delete secret --all -n kps
