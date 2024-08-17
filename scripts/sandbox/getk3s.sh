#!/bin/sh
#
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="--kubelet-arg "root-dir=$KUBELET_DIR"" sh -
sudo chmod 644 /etc/rancher/k3s/k3s.yaml

#
# Solving problems with x509 cert auth in local environments
# for userspace apps that read the configfile (kubecolor, helm3)
sudo k3s kubectl config view --raw > ~/.kube/config

# setup helm3
#
#get the manifest with
#curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
curl -fsSL -o ./artifacts/components/manifestos/get_helm.sh https://raw.githubusercontent.com/helm/helm/f31d4fb3aacabf6102b3ec9214b3433a3dbf1812/scripts/get-helm-3
chmod 700 ./artifacts/components/manifestos/get_helm.sh
./artifacts/components/manifestos/get_helm.sh




###### setup kubectl's krew plugins and kubectl-trace ######
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#### install kubectl-trace ###
sudo k3s kubectl krew install trace
## install with prebuilt bins
#curl -L -o kubectl-trace.tar.gz https://github.com/iovisor/kubectl-trace/releases/download/v0.1.0-rc.1/kubectl-trace_0.1.0-rc.1_linux_amd64.tar.gz
#tar -xvf kubectl-trace.tar.gz
#mv kubectl-trace /usr/local/bin/kubectl-trace

##### setup argocd #####
curl -fsSL -o ./artifacts/components/manifestos/argo.yaml  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo k3s kubectl create namespace argocd
sudo k3s kubectl apply -n argocd -f ./artifacts/components/manifestos/argocd.yaml
#or
#kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#

# argocd CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v2.7.3/argocd-linux-amd64
sudo install -m 555 ./argocd-linux-amd64 /usr/bin/argocd
rm ./argocd-linux-amd64

# cluster ip of argocd below
# sudo k3s kubectl get svc -n argocd | grep argocd-server | awk 'NR==1 {print $3}'

# port-forward the argocd webserver
sudo k3s kubectl port-forward svc/argocd-server -n argocd 8080:443

# set argocd server URI URL, username and password using github as secret store provider
gh repo secret set ARGOCD_SERVER < $(echo localhost:8080)
gh repo secret set ARGOCD_USERNAME < $(echo admin)
gh repo secret set ARGOCD_PASSWD < $(sudo k3s kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# developing/testing use case only, hence the insecure flag below
argocd login "$ARGOCD_SERVER" --username="$ARGOCD_USERNAME" --password="$ARGOCD_PASSWD" --insecure

# check argocd login
argo_agui=$(argocd account get-user-info \
    --server="$(sudo k3s kubectl get svc -n argocd | \
        grep argocd-server | awk 'NR==1 {print $3}')" | awk '{print $3}')

echo "$argo_agui" | \
    ![[grep -q "false"]] && \
    # add cluster to argocd if authenticated
    argocd cluster add "$(sudo k3s kubectl config current-context)" | grep -q "rpc error" && \
    if sed -e '/server: /{ s/s/# s/; n; a\' -e 'bash -c "sudo k3s kubectl get -n default endpoints | awk '\''NR==2 {print $2}'\''"/; }' ~/.kube/config; then \
        # send SIGINT to current bash script in execution if not authenticated
        kill -s="9" --pid="$$" #checkout $BASHPID
    fi
