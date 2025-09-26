Azure AD workload identity federation (GitHub Actions) — setup guide
=================================================================

This document walks through creating an Azure AD application and a federated credential so GitHub Actions can authenticate to Azure using OIDC without long-lived secrets.

Steps summary
1. Create an Azure AD app registration
2. Create a federated credential in the app registration that trusts GitHub Actions
3. Assign least-privilege roles (AcrPush/AcrPull, Contributor for resource group scoped deploy, etc.) to the application principal
4. Configure repository secrets with the Azure subscription ID, tenant ID, and client ID

Detailed commands

# 1. Create an app registration

```bash
az ad app create --display-name "github-actions-mcp-deployer" --identifier-uris "api://github-actions-mcp-deployer" \
  --optional-claims @- <<'JSON'
{
  "idToken": [],
  "accessToken": []
}
JSON
```

This returns an `appId` (use as CLIENT_ID).

# 2. Create a service principal for the app (this creates an identity you can assign roles to)

```bash
az ad sp create --id <APP_ID>
# get the principal id
APP_PRINCIPAL_ID=$(az ad sp show --id <APP_ID> --query objectId -o tsv)
```

# 3. Create a federated credential that allows GitHub Actions OIDC tokens to be exchanged

Replace <APP_ID>, <REPO>, <BRANCH_OR_TAG>, and <SUB> below.

```bash
az rest --method POST --uri "https://graph.microsoft.com/v1.0/applications/<APP_OBJECT_ID>/federatedIdentityCredentials" --headers "Content-Type=application/json" --body '{
  "name": "github-actions-mcp-federated",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<YOUR_ORG_OR_USER>/<YOUR_REPO>:ref:refs/heads/<BRANCH_OR_TAG>",
  "description": "Federated credential for GitHub Actions for MCP deploy",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

Notes:
- `subject` can be scoped to `repo:owner/repo:ref:refs/heads/main` or to `repo:owner/repo:*` if you want broader access.
- You must call the Microsoft Graph API with appropriate permissions (use az cli authenticated as a user with app permissions or use Graph Explorer).

# 4. Assign roles to the service principal (least privilege)

Example: grant AcrPush to push images and Contributor on the resource group for deployments

```bash
az role assignment create --assignee-object-id $APP_PRINCIPAL_ID --role AcrPush --scope /subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>

az role assignment create --assignee-object-id $APP_PRINCIPAL_ID --role Contributor --scope /subscriptions/<SUB>/resourceGroups/<RG>
```

# 5. Configure GitHub repository secrets

- AZURE_CLIENT_ID -> appId from step 1
- AZURE_TENANT_ID -> your tenant
- AZURE_SUBSCRIPTION_ID -> subscription id

# 6. Update workflow

Use `azure/login@v1` in your workflow with the `client-id`, `tenant-id`, and `subscription-id` (no client secret required). The action will obtain a short-lived access token using the OIDC assertion from GitHub Actions.

References
- https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-configure
- https://learn.microsoft.com/azure/developer/github/connect-from-azure

Security notes
- Keep the federated credential's `subject` as narrow as possible (limit to specific repo/branch/workflow).
- Use role-scoped assignments instead of subscription-wide roles.
- Audit and rotate permissions periodically.
