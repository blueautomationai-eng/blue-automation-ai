<#
.SYNOPSIS
    Inventories all Copilot Studio Bots (Chatbots) across environments.
.DESCRIPTION
    Queries the Power Platform Admin API to list all AI Agents, including their 
    state, owner, and modification history. Critical for building an AI Asset Register.
    Requires Connect-BlueEnvironment -Audience Dataverse (or AzureRM for token).
.EXAMPLE
    Get-BlueCopilotInventory -EnvironmentId "12345678-abcd-1234-efgh-1234567890ab"
#>
function Get-BlueCopilotInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    process {
        try {
            Write-Verbose "Fetching Copilot Agents for Environment: $EnvironmentId"
            
            # Power Platform Admin API Endpoint for Bot Inventory
            $Uri = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments/$EnvironmentId/bots?api-version=2020-10-01"
            
            # Using our custom broker to get a token for the Power Platform API
            # Note: For BAP API, we often use the management.azure.com resource or specific BAP resource
            $TokenResponse = Get-AzAccessToken -ResourceUrl "https://api.bap.microsoft.com/" -ErrorAction Stop
            $Token = $TokenResponse.Token
            
            $Headers = @{
                Authorization  = "Bearer $Token"
                "Content-Type" = "application/json"
            }

            Write-Verbose "Executing REST call to Power Platform Admin API..."
            $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get
            
            if ($Response.value) {
                Write-Information "Found $($Response.value.Count) Copilot agents."
                return $Response.value | Select-Object `
                    @{Name="AgentName"; Expression={$_.displayName}}, 
                    @{Name="Owner"; Expression={$_.createdBy.displayName}},
                    @{Name="Status"; Expression={$_.state}},
                    @{Name="LastModified"; Expression={$_.modifiedTime}},
                    @{Name="BotType"; Expression={$_.botType}},
                    @{Name="EnvironmentId"; Expression={$EnvironmentId}}
            } else {
                Write-Warning "No Copilot agents found in environment $EnvironmentId."
            }
        }
        catch {
            Write-Error "Failed to inventory Copilot agents: $($_.Exception.Message)"
            throw $_
        }
    }
}