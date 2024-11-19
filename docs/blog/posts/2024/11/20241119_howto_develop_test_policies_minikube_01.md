---
draft: false
date: 2024-11-19
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Policy
---
# How to create a local environment to write policies for Kubernetes with minikube and gatekeeper

## minikube in wsl2

### Enable systemd in WSL2

```bash
sudo nano /etc/wsl.conf
```

Add the following:

```bash
[boot]
systemd=true
```

Restart WSL2 in command:

```command
wsl --shutdown
wsl
```

### Install docker

[Install docker using repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

## Minikube
### Install minikube

```bash
# Download the latest Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Make it executable
chmod +x ./minikube

# Move it to your user's executable PATH
sudo mv ./minikube /usr/local/bin/

#Set the driver version to Docker
minikube config set driver docker
```
### Test minikube

```bash
# Enable completion
source <(minikube completion bash)
# Start minikube
minikube start
# Check the status
minikube status
# set context
kubectl config use-context minikube
# get pods
kubectl get pods --all-namespaces
```

## Install OPA Gatekeeper

```bash	
# Install OPA Gatekeeper
# check version in https://open-policy-agent.github.io/gatekeeper/website/docs/install#deploying-a-release-using-prebuilt-image
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.17.1/deploy/gatekeeper.yaml

# wait and check the status
sleep 60
kubectl get pods -n gatekeeper-system
```

## Test constraints

First, we need to create a constraint template and a constraint.

```bash
# Create a constraint template
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.17.1/demo/basic/templates/k8srequiredlabels_template.yaml

# Create a constraint
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.17.1/demo/basic/constraints/k8srequiredlabels_constraint.yaml
```

Now, we can test the constraint.

```bash
# Create a deployment without the required label
kubectl create namespace petete 
```
We must see an error message like this:

```bash
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [ns-must-have-gk] you must provide labels: {"gatekeeper"}
```

```bash
# Create a deployment with the required label
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: petete
  labels:
    gatekeeper: "true"
EOF
kubectl get namespaces petete
```
We must see a message like this:

```bash
NAME     STATUS   AGE
petete   Active   3s
```
## Conclusion

We have created a local environment to write policies for Kubernetes with minikube and gatekeeper. We have tested the environment with a simple constraint. Now we can write our own policies and test them in our local environment.

## References

- [Minikube](https://minikube.sigs.k8s.io/docs/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/install)
- [How to use Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/howto/)
- [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)
- [Docker](https://docs.docker.com/engine/install/ubuntu/)
