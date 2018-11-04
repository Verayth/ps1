<#
.SYNOPSIS
    Enumeration of Win32_ComputerSystem.PCSystemType

#>

#([CimSession]::Create('.')).GetClass('ROOT/CIMV2', 'Win32_ComputerSystem',
#    [Microsoft.Management.Infrastructure.Options.CimOperationOptions]@{Flags = [Microsoft.Management.Infrastructure.Options.CimOperationFlags]::LocalizedQualifiers})
#exit 0

param([string]$Type)

$session = [CimSession]::Create('.')
try {
    # Add operation options that retrieve localized values for mappings
    $operationOptions = [Microsoft.Management.Infrastructure.Options.CimOperationOptions]@{
        Flags = [Microsoft.Management.Infrastructure.Options.CimOperationFlags]::LocalizedQualifiers
    }

    $class = $session.GetClass('ROOT/CIMV2', 'Win32_ComputerSystem', $operationOptions)
    $qualifiers = $class.CimClassProperties['PCSystemType'].Qualifiers
    $mappedQualifiers = @{}

    # Keys and values are stored as separate arrays
    $keys = $qualifiers['ValueMap'].Value
    $values = $qualifiers['Values'].Value
    for ($i = 0; $i -lt $keys.Length; $i++) {
        $mappedQualifiers[$keys[$i]] = $values[$i]
    }

    # yield
    if ($Type) {
        $mappedQualifiers["$Type"]
    } else {
        $mappedQualifiers
    }
} finally {
    $session.Dispose()
}
