---
draft: false
date: 2024-04-28
authors:
  - rfernandezdo
categories:
    - DevOps
tags:
    - Terraform
---

# Terraform: Set your local environment developer 

I wil use Ubuntu in WSL v2 as my local environment for my IaC project with Terraform. I will install the following tools:

- vscode
- Trunk
- tenv
- az cli

## az cli

I will use the Azure CLI to interact with Azure resources from the command line. I will install the Azure CLI using the following commands:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

## vscode

I will use Visual Studio Code as my code editor for my IaC project with Terraform. I will install the following extensions:

- Terraform
- Azure Terraform
- Azure Account
- Trunk


## tenv

`tenv` is a tool that allows you to manage multiple Terraform environments with ease. It provides a simple way to switch between different environments, such as development, staging, and production, by managing environment variables and state files for each environment.

### Installation

You can install `tenv` using `go get`:

```bash
LATEST_VERSION=$(curl --silent https://api.github.com/repos/tofuutils/tenv/releases/latest | jq -r .tag_name)
curl -O -L "https://github.com/tofuutils/tenv/releases/latest/download/tenv_${LATEST_VERSION}_amd64.deb"
sudo dpkg -i "tenv_${LATEST_VERSION}_amd64.deb"
```

### Usage

To create a new environment, you can use the `tenv create` command:

```bash
# to install the latest version of Terraform
tenv tf install 
```



## References

- [tenv](https://github.com/tofuutils/tenv)