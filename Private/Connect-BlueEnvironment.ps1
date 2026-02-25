<#
.SYNOPSIS
    Establishes secure, Zero Trust connections to specified Microsoft Cloud environments.
.DESCRIPTION
    Authenticates to Microsoft Graph, Azure Resource Manager (ARM), and sets up 
    the token broker for Dataverse/Power Platform. Auto-detects Azure Functions 
    (Managed Identity) versus local development (Interactive MFA).
.EXAMPLE
    Connect-BlueEnvironment -Audience Graph, Dataverse
#>
function Connect-BlueEnvironment {
    [CmdletBinding()]
    param (
        # Defines the target APIs to authenticate against
        [Parameter(Mandatory = $false)]
        [ValidateSet('Graph', 'AzureRM', 'Dataverse')]
        [string[]]$Audience = @('Graph'),

        # Required scopes for Microsoft Graph interactive login
        [Parameter(Mandatory = $false)]
        [string[]]$GraphScopes = @("AuditLog.Read.All", "Directory.Read.All"),

        # Optional: User Assigned Managed Identity (ClientId, ObjectId, or ResourceId)
        [Parameter(Mandatory = $false)]
        [string]$AccountId
    )

    process {
        try {
            # Detect Azure Functions environment by checking specific environment variables
            $IsAzureFunction = [bool]$env:FUNCTIONS_WORKER_RUNTIME
            
            # Use a hashtable to track connections and avoid redundant auth prompts
            $ConnectionState = @{
                GraphConnected = [bool](Get-MgContext -ErrorAction SilentlyContinue)
                AzConnected    = [bool](Get-AzContext -ErrorAction SilentlyContinue)
            }

            foreach ($Target in $Audience) {
                Write-Verbose "Processing authentication for audience: $Target"

                switch ($Target) {
                    'Graph' {
                        if ($ConnectionState.GraphConnected) {
                            Write-Verbose "Existing Graph context found. Skipping."
                            continue
                        }

                        if ($IsAzureFunction) {
                            Write-Verbose "[Graph] Azure Function detected. Initiating Managed Identity."
                            if ($AccountId) {
                                Connect-MgGraph -Identity -AccountId $AccountId -NoWelcome
                            } else {
                                Connect-MgGraph -Identity -NoWelcome
                            }
                        } else {
                            Write-Verbose "[Graph] Local environment detected. Initiating Interactive MFA."
                            Connect-MgGraph -Scopes $GraphScopes -NoWelcome
                        }
                        $ConnectionState.GraphConnected = $true
                    }

                    { $_ -in 'AzureRM', 'Dataverse' } {
                        # Dataverse requires Az.Accounts to act as a token broker
                        if ($ConnectionState.AzConnected) {
                            Write-Verbose "Existing Azure context found. Skipping."
                            continue
                        }

                        if ($IsAzureFunction) {
                            Write-Verbose "[Azure/Dataverse] Azure Function detected. Initiating Managed Identity."
                            if ($AccountId) {
                                Connect-AzAccount -Identity -AccountId $AccountId | Out-Null
                            } else {
                                Connect-AzAccount -Identity | Out-Null
                            }
                        } else {
                            Write-Verbose "[Azure/Dataverse] Local environment detected. Initiating Interactive MFA."
                            Connect-AzAccount -UseDeviceAuthentication | Out-Null
                        }
                        $ConnectionState.AzConnected = $true
                    }
                }
            }
        }
        catch {
            # Critical failure point: Ensure logs are written for SIEM/Sentinel integration
            Write-Error "Failed to authenticate to requested audiences: $($_.Exception.Message)"
            throw $_
        }
    }
}