---
draft: false
date: 2025-09-01
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - Azure DevOps
  - CI/CD
  - Pipelines
  - YAML
---

# Azure DevOps Pipelines as Code: YAML templates reutilizables

## Resumen

**Pipelines as Code** con YAML en Azure DevOps te permite versionar CI/CD, reutilizar templates y aplicar DRY principle. En este post verás cómo crear pipelines YAML modulares, templates parametrizados y estrategias multi-stage para deploy seguro.

<!-- more -->

## ¿Por qué YAML pipelines?

**Classic UI pipelines vs YAML:**

| Característica | Classic UI | YAML |
|----------------|------------|------|
| **Version control** | ❌ No | ✅ En Git |
| **Code review** | ❌ No | ✅ Pull Requests |
| **Reusabilidad** | Limitada | ✅ Templates |
| **Multi-repo** | Complejo | ✅ Nativo |
| **Auditable** | Parcial | ✅ Git history |

---

## Pipeline básico: build + test

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
    - main
    - develop
  paths:
    exclude:
    - docs/*
    - README.md

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - task: UseDotNet@2
      inputs:
        version: '8.x'
    
    - script: dotnet restore
      displayName: 'Restore dependencies'
    
    - script: dotnet build --configuration $(buildConfiguration) --no-restore
      displayName: 'Build project'
    
    - script: dotnet test --no-build --verbosity normal --logger trx
      displayName: 'Run unit tests'
    
    - task: PublishTestResults@2
      inputs:
        testResultsFormat: 'VSTest'
        testResultsFiles: '**/*.trx'
      condition: always()
    
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '$(Build.ArtifactStagingDirectory)'
        artifactName: 'drop'
```

---

## Templates reutil izables

### Template: build-dotnet.yml

```yaml
# templates/build-dotnet.yml
parameters:
- name: dotnetVersion
  type: string
  default: '8.x'
- name: buildConfiguration
  type: string
  default: 'Release'
- name: runTests
  type: boolean
  default: true

steps:
- task: UseDotNet@2
  inputs:
    version: ${{ parameters.dotnetVersion }}

- script: dotnet restore
  displayName: 'Restore NuGet packages'

- script: dotnet build --configuration ${{ parameters.buildConfiguration }} --no-restore
  displayName: 'Build solution'

- ${{ if eq(parameters.runTests, true) }}:
  - script: dotnet test --no-build --configuration ${{ parameters.buildConfiguration }} --logger trx --collect:"XPlat Code Coverage"
    displayName: 'Run tests with coverage'
  
  - task: PublishTestResults@2
    inputs:
      testResultsFormat: 'VSTest'
      testResultsFiles: '**/*.trx'
    condition: always()
  
  - task: PublishCodeCoverageResults@1
    inputs:
      codeCoverageTool: 'Cobertura'
      summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'

- task: DotNetCoreCLI@2
  inputs:
    command: 'publish'
    publishWebProjects: false
    projects: '**/*.csproj'
    arguments: '--configuration ${{ parameters.buildConfiguration }} --output $(Build.ArtifactStagingDirectory)'
    zipAfterPublish: true
```

### Usar template

```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

stages:
- stage: Build
  jobs:
  - job: BuildApp
    steps:
    - template: templates/build-dotnet.yml
      parameters:
        dotnetVersion: '8.x'
        buildConfiguration: 'Release'
        runTests: true
```

---

## Multi-stage pipeline: Build → Test → Deploy

```yaml
# azure-pipelines-multistage.yml
trigger:
- main

variables:
  azureSubscription: 'Azure-Production'
  webAppName: 'webapp-prod'
  
stages:
- stage: Build
  displayName: 'Build application'
  jobs:
  - job: BuildJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - template: templates/build-dotnet.yml
      parameters:
        buildConfiguration: 'Release'
    
    - publish: $(Build.ArtifactStagingDirectory)
      artifact: drop

- stage: DeployDev
  displayName: 'Deploy to Development'
  dependsOn: Build
  condition: succeeded()
  jobs:
  - deployment: DeployWeb
    environment: 'development'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          
          - task: AzureWebApp@1
            inputs:
              azureSubscription: $(azureSubscription)
              appName: 'webapp-dev'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployProd
  displayName: 'Deploy to Production'
  dependsOn: DeployDev
  condition: succeeded()
  jobs:
  - deployment: DeployProduction
    environment: 'production'
    pool:
      vmImage: 'ubuntu-latest'
    strategy:
      runOnce:
        preDeploy:
          steps:
          - script: echo "Pre-deployment validation"
        
        deploy:
          steps:
          - download: current
            artifact: drop
          
          - task: AzureWebApp@1
            inputs:
              azureSubscription: $(azureSubscription)
              appName: $(webAppName)
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
              deploymentMethod: 'zipDeploy'
        
        postDeploy:
          steps:
          - script: |
              curl -f https://$(webAppName).azurewebsites.net/health || exit 1
            displayName: 'Health check'
```

---

## Environments con approvals

### Configurar environment

```bash
# Azure DevOps CLI
az devops environment create \
  --name production \
  --project MyProject

# Agregar approval (desde UI)
# Project Settings → Environments → production → Approvals and checks
# Add: Approval (select approvers)
```

**YAML con environment:**

```yaml
- stage: DeployProd
  jobs:
  - deployment: DeployToProd
    environment: production  # Requiere approval manual
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to production"
```

---

## Variables y secrets

### Variable groups

```yaml
# azure-pipelines.yml
variables:
- group: prod-secrets  # Variable group creado en Library
- name: buildConfiguration
  value: 'Release'

steps:
- script: |
    echo "Deploying to $(environment)"
    echo "Using connection string: $(sqlConnectionString)"  # From variable group
  env:
    SQL_PASSWORD: $(sqlPassword)  # Secret variable
```

### Key Vault integration

```yaml
- stage: Deploy
  variables:
  - group: prod-keyvault  # Linked to Azure Key Vault
  jobs:
  - job: DeployApp
    steps:
    - task: AzureKeyVault@2
      inputs:
        azureSubscription: 'Azure-Production'
        KeyVaultName: 'kv-prod-secrets'
        SecretsFilter: '*'
        RunAsPreJob: true
    
    - script: |
        echo "Using secret: $(database-password)"  # From Key Vault
```

---

## Estrategias de deployment

### Blue-Green deployment

```yaml
- stage: DeployBlueGreen
  jobs:
  - deployment: DeployGreen
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          # Deploy to slot 'green'
          - task: AzureWebApp@1
            inputs:
              azureSubscription: $(azureSubscription)
              appName: $(webAppName)
              slotName: 'green'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'
          
          # Test green slot
          - script: |
              curl -f https://$(webAppName)-green.azurewebsites.net/health
            displayName: 'Validate green slot'
          
          # Swap slots (green → production)
          - task: AzureAppServiceManage@0
            inputs:
              azureSubscription: $(azureSubscription)
              action: 'Swap Slots'
              webAppName: $(webAppName)
              sourceSlot: 'green'
              targetSlot: 'production'
```

### Canary deployment (AKS)

```yaml
- stage: DeployCanary
  jobs:
  - deployment: CanaryDeploy
    environment: kubernetes-prod
    strategy:
      canary:
        increments: [10, 25, 50, 100]
        preDeploy:
          steps:
          - script: echo "Pre-deploy validation"
        
        deploy:
          steps:
          - task: Kubernetes@1
            inputs:
              connectionType: 'Kubernetes Service Connection'
              kubernetesServiceEndpoint: 'aks-prod'
              command: 'apply'
              arguments: '-f k8s/deployment.yaml'
        
        routeTraffic:
          steps:
          - script: |
              # Update Istio VirtualService to route X% traffic
              kubectl apply -f k8s/virtual-service-canary-$(strategy.increment).yaml
        
        postRouteTraffic:
          steps:
          - script: |
              # Monitor metrics for 5 minutes
              sleep 300
              ERROR_RATE=$(curl -s http://prometheus/api/v1/query?query=error_rate | jq .data.result[0].value[1])
              if [ "$ERROR_RATE" -gt "0.01" ]; then exit 1; fi
            displayName: 'Validate canary metrics'
        
        on:
          failure:
            steps:
            - script: echo "Rolling back canary"
            - task: Kubernetes@1
              inputs:
                command: 'rollout'
                arguments: 'undo deployment/myapp'
          
          success:
            steps:
            - script: echo "Canary successful, promoting to 100%"
```

---

## CI/CD para múltiples microservicios

### Monorepo con path triggers

```yaml
# services/api/azure-pipelines.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - services/api/*
    - shared/libraries/*

stages:
- stage: BuildAPI
  jobs:
  - template: ../../templates/build-dotnet.yml
    parameters:
      projectPath: 'services/api/API.csproj'
```

```yaml
# services/frontend/azure-pipelines.yml
trigger:
  paths:
    include:
    - services/frontend/*
    - shared/ui-components/*

stages:
- stage: BuildFrontend
  jobs:
  - job: Build
    steps:
    - script: |
        cd services/frontend
        npm install
        npm run build
```

### Pipeline orchestrator

```yaml
# azure-pipelines-all.yml
trigger: none  # Manual/scheduled only

stages:
- stage: BuildAll
  jobs:
  - job: TriggerPipelines
    steps:
    - task: TriggerBuild@3
      inputs:
        buildDefinition: 'API-Pipeline'
        queueBuildForUserThatTriggeredBuild: true
        waitForQueuedBuildsToFinish: true
    
    - task: TriggerBuild@3
      inputs:
        buildDefinition: 'Frontend-Pipeline'
        waitForQueuedBuildsToFinish: true
```

---

## Seguridad y compliance

### SonarQube analysis

```yaml
- stage: QualityGate
  jobs:
  - job: SonarAnalysis
    steps:
    - task: SonarQubePrepare@5
      inputs:
        SonarQube: 'SonarQube-Server'
        scannerMode: 'MSBuild'
        projectKey: 'my-project'
    
    - script: dotnet build
    
    - task: SonarQubeAnalyze@5
    
    - task: SonarQubePublish@5
      inputs:
        pollingTimeoutSec: '300'
    
    - script: |
        # Fail pipeline if quality gate fails
        QUALITY_GATE=$(curl -u $(sonarToken): "$(sonarUrl)/api/qualitygates/project_status?projectKey=my-project" | jq -r .projectStatus.status)
        if [ "$QUALITY_GATE" != "OK" ]; then exit 1; fi
```

### Container scanning (Trivy)

```yaml
- stage: SecurityScan
  jobs:
  - job: ScanContainer
    steps:
    - script: |
        docker build -t myapp:$(Build.BuildId) .
      displayName: 'Build container'
    
    - script: |
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:$(Build.BuildId)
      displayName: 'Scan for vulnerabilities'
```

---

## Buenas prácticas

### 1. Usar extends templates

```yaml
# templates/base-pipeline.yml
parameters:
- name: stages
  type: stageList
  default: []

stages:
- stage: Init
  jobs:
  - job: Setup
    steps:
    - script: echo "Initialize environment"

- ${{ each stage in parameters.stages }}:
  - ${{ stage }}

- stage: Cleanup
  jobs:
  - job: TearDown
    steps:
    - script: echo "Cleanup resources"
```

```yaml
# azure-pipelines.yml
extends:
  template: templates/base-pipeline.yml
  parameters:
    stages:
    - stage: Build
      jobs:
      - job: BuildApp
        steps:
        - script: dotnet build
```

### 2. Matrix builds

```yaml
strategy:
  matrix:
    Linux:
      imageName: 'ubuntu-latest'
      dotnetVersion: '8.x'
    Windows:
      imageName: 'windows-latest'
      dotnetVersion: '8.x'
    Mac:
      imageName: 'macOS-latest'
      dotnetVersion: '8.x'

pool:
  vmImage: $(imageName)

steps:
- task: UseDotNet@2
  inputs:
    version: $(dotnetVersion)
- script: dotnet test
```

### 3. Caching dependencies

```yaml
- task: Cache@2
  inputs:
    key: 'nuget | "$(Agent.OS)" | **/packages.lock.json'
    path: $(NUGET_PACKAGES)
    restoreKeys: |
      nuget | "$(Agent.OS)"
  displayName: 'Cache NuGet packages'

- script: dotnet restore
```

---

## Referencias

- [Azure Pipelines YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Templates Documentation](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Deployment Strategies](https://learn.microsoft.com/azure/devops/pipelines/process/deployment-jobs)
