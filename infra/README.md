Azure MCP (managed) provisioning - Bicep
========================================

This folder contains a Bicep template and deployment guidance to provision a minimal set of Azure resources for a managed MCP-like service. The template focuses on secure defaults and best practices: managed identity use, Key Vault, ACR, Log Analytics, and a Container Apps Environment.

Files
- `main.bicep` - core infrastructure template (ACR, Log Analytics, Container Apps Env, User-assigned Identity, Key Vault)

Pre-reqs
- Azure CLI installed and logged in
- You have permissions to create resource groups, ACR, Log Analytics, and Container Apps

Quick deploy (example)
```bash
# create resource group
az group create -n my-mcp-rg -l eastus

# deploy bicep
az deployment group create -g my-mcp-rg --template-file infra/main.bicep --parameters prefix=my-mcp location=eastus
```

Post-deploy
- Create role assignments and Key Vault access policies manually (least privilege). Example:
```bash
# assign AcrPull to the container app's principal
az role assignment create --assignee-object-id <principalId> --role AcrPull --scope <acrResourceId>

# set keyvault policy for the identity
az keyvault set-policy -n <keyVaultName> --object-id <principalId> --secret-permissions get list set
```

Security notes
- Use managed identities for services to access Key Vault and ACR.
- Never store secrets in plain text in templates or code.
- Consider enabling private endpoints and restricting public network access.

CI/CD
- Use a service principal with least privilege in pipelines to push images to ACR and to deploy container apps.
- Store pipeline secrets in GitHub Actions secrets or Azure Key Vault accessible via federated credentials.

References
- Container Apps Bicep samples: https://learn.microsoft.com/azure/container-apps/overview
- Azure Bicep docs: https://learn.microsoft.com/azure/azure-resource-manager/bicep/
