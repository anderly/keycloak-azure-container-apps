# Keycloak Azure Container Apps

This repo contains a customized docker container of [keycloak](https://www.keycloak.org/) designed to run on [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/overview) via the included `push.ps1` (powershell) or `push.sh` (bash) scripts.

See docs: https://learn.microsoft.com/en-us/azure/container-apps/tutorial-deploy-first-app-cli?tabs=bash

The scripts assume the following has already been provisioned:
- Azure Container Apps Environment

If not, you can provision one like so ([see docs](https://learn.microsoft.com/en-us/azure/container-apps/tutorial-deploy-first-app-cli?tabs=bash#create-an-environment)):
```bash
    az containerapp env create \
      --name $CONTAINERAPPS_ENVIRONMENT \
      --resource-group $RESOURCE_GROUP \
      --location "$LOCATION"
```

## Setup

- Copy the `.env.example` to `.env` and modify the variables.
- Login to Azure the desired Azure Tenant: `az login --tenant xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`
- Ensure latest CLI version by running: `az upgrade`
- Add Container Apps extension by running: `az extension add --name containerapp --upgrade`
- Register `Microsoft.App` and `Microsoft.OperationalInsights` namespaces by running:
  - `az provider register --namespace Microsoft.App`
  - `az provider register --namespace Microsoft.OperationalInsights`
- Deploy to Azure Container Apps by running: `./push.ps1` or `sh ./push.sh`