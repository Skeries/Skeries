@description('Location for all resources')
param location string = resourceGroup().location

@description('Name prefix used for created resources')
param prefix string = 'mcp'

@description('Container registry SKU')
param acrSku string = 'Standard'

@description('Log Analytics SKU is determined by service; workspace retention days')
param laRetentionDays int = 30

var acrName = toLower('${prefix}acr')
var laName = '${prefix}-law'
var envName = '${prefix}-ca-env'
var identityName = '${prefix}-uid'
var keyVaultName = toLower('${prefix}-kv')
var containerAppName = '${prefix}-app'

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {}
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: laName
  location: location
  properties: {
    retentionInDays: laRetentionDays
  }
}

resource containerAppsEnv 'Microsoft.Web/kubeEnvironments@2022-03-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: listKeys(logAnalytics.id, '2021-06-01').primarySharedKey
      }
    }
  }
  dependsOn: [logAnalytics]
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enablePurgeProtection: false
    enableSoftDelete: true
  }
}

// Container App that runs the mcp-mock image from ACR. The container app uses
// the user-assigned managed identity to authenticate to ACR. The role assignment
// below grants AcrPull on the registry to that identity.
resource containerApp 'Microsoft.App/containerApps@2023-10-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: {
            type: 'UserAssigned'
            userAssignedIdentity: userIdentity.id
          }
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'mcp-mock'
          // Image should be pushed to ACR under the repository name 'mcp-mock'
          image: '${acr.properties.loginServer}/mcp-mock:latest'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
    }
  }
  dependsOn: [containerAppsEnv, acr, userIdentity]
}

// Role assignment: give the user-assigned identity AcrPull role on the ACR so
// the Container App can pull images. Use a deterministic GUID for the role
// assignment name.
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(acr.id, userIdentity.properties.principalId, 'acrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: userIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [acr, userIdentity]
}

output acrLoginServer string = acr.properties.loginServer
output acrResourceId string = acr.id
output logAnalyticsId string = logAnalytics.id
output containerAppsEnvId string = containerAppsEnv.id
output userAssignedIdentityClientId string = userIdentity.properties.clientId
output userAssignedIdentityPrincipalId string = userIdentity.properties.principalId
output keyVaultId string = keyVault.id
output containerAppId string = containerApp.id
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output acrPullRoleId string = acrPullRole.id

// Notes: We intentionally avoid role assignments in this template so that operator can review
// and run them under the security context of a subscription principal. After deployment run:
// az role assignment create --assignee-object-id <principalId> --role AcrPull --scope <acr.id>
// az keyvault set-policy --name <keyVaultName> --object-id <principalId> --secret-permissions get list set
