# -------------------------------------------------------------------
# Root module script to import all domain-based functions
# -------------------------------------------------------------------
$Domains = @('Identity', 'Security', 'Compliance', 'Governance')

foreach ($Domain in $Domains) {
    $Path = Join-Path $PSScriptRoot $Domain
    if (Test-Path $Path) {
        $Files = Get-ChildItem -Path "$Path\*.ps1" -Recurse
        foreach ($File in $Files) {
            # Dot-sourcing functions to make them available in the session
            . $File.FullName
        }
    }
}