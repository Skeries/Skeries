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

output acrLoginServer string = acr.properties.loginServer
output acrResourceId string = acr.id
output logAnalyticsId string = logAnalytics.id
output containerAppsEnvId string = containerAppsEnv.id
output userAssignedIdentityClientId string = userIdentity.properties.clientId
output userAssignedIdentityPrincipalId string = userIdentity.properties.principalId
output keyVaultId string = keyVault.id

// Notes: We intentionally avoid role assignments in this template so that operator can review
// and run them under the security context of a subscription principal. After deployment run:
// az role assignment create --assignee-object-id <principalId> --role AcrPull --scope <acr.id>
// az keyvault set-policy --name <keyVaultName> --object-id <principalId> --secret-permissions get list set
