# -------------------------------------------------------------------
# Root module script to import all domain-based and private functions
# -------------------------------------------------------------------

# 1. Load Private Infrastructure Functions First 
$PrivatePath = Join-Path $PSScriptRoot "Private"
if (Test-Path $PrivatePath) {
    $PrivateFiles = Get-ChildItem -Path "$PrivatePath\*.ps1" -Recurse
    foreach ($File in $PrivateFiles) {
        # Dot-sourcing internal helper functions into module scope
        . $File.FullName
    }
}

# 2. Load Public Business Logic Functions (Domain folders)
$Domains = @('Identity', 'Security', 'Compliance', 'Governance')

foreach ($Domain in $Domains) {
    $Path = Join-Path $PSScriptRoot $Domain
    if (Test-Path $Path) {
        $Files = Get-ChildItem -Path "$Path\*.ps1" -Recurse
        foreach ($File in $Files) {
            # Dot-sourcing public functions to make them available to the user
            . $File.FullName
        }
    }
}