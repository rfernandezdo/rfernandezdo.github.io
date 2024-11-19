---
draft: false
date: 2024-11-20
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Policy
---
# Develop my firts policy for Kubernetes with minikube and gatekeeper

Now that we have our [development environment], we can start developing our first policy for Kubernetes with minikube and gatekeeper.

[development environment]: 20241119_howto_develop_test_policies_minikube_01

First at all, we need some visual code editor to write our policy. I recommend using Visual Studio Code, but you can use any other editor. Exists a plugin for Visual Studio Code that helps you to write policies for gatekeeper. You can install it from the marketplace: [Open Policy Agent](https://marketplace.visualstudio.com/items?itemName=tsandall.opa).

Once you have your editor ready, you can start writing your policy. In this example, we will create a policy that denies the creation of pods with the image `nginx:latest`.

For that we need two files:

- `constraint.yaml`: This file defines the constraint that we want to apply.
- `constraint_template.yaml`: This file defines the template that we will use to create the constraint.

Let's start with the `constraint_template.yaml` file:

```yaml title="constraint_template.yaml"
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8sdenypodswithnginxlatest
spec:
  crd:
    spec:
      names:
        kind: K8sDenyPodsWithNginxLatest
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdenypodswithnginxlatest

        violation[{"msg": msg}] {
          input.review.object.spec.containers[_].image == "nginx:latest"
          msg := "Containers cannot use the nginx:latest image"
        }
```

Now, let's create the `constraint.yaml` file:

```yaml title="constraint.yaml"
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDenyPodsWithNginxLatest
metadata:
  name: deny-pods-with-nginx-latest
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
  parameters:
    msg: "Containers cannot use the nginx:latest image"
```

Now, we can apply the files to our cluster:

```bash
# Create the constraint template
kubectl apply -f constraint_template.yaml

# Create the constraint
kubectl apply -f constraint.yaml
```

Now, we can test the constraint. Let's create a pod with the image `nginx:latest`:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:latest
EOF
```

We must see an error message like this:

```bash
Error from server (Forbidden): error when creating "STDIN": admission webhook "validation.gatekeeper.sh" denied the request: [k8sdenypodswithnginxlatest] Containers cannot use the nginx:latest image
```

Now, let's create a pod with a different image:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.25.5
EOF
```

We must see a message like this:

```bash
pod/nginx-pod created
```

For cleaning up, you can delete pod,the constraint and the constraint template:

```bash
# Delete the pod
kubectl delete pod nginx-pod
# Delete the constraint
kubectl delete -f constraint.yaml

# Delete the constraint template
kubectl delete -f constraint_template.yaml
```

And that's it! We have developed our first policy for Kubernetes with minikube and gatekeeper. Now you can start developing more complex policies and test them in your cluster.

Happy coding!
