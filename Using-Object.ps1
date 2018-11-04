<#
https://davewyatt.wordpress.com/2014/04/11/using-object-powershell-version-of-cs-using-statement/
https://stackoverflow.com/questions/42107851/how-to-implement-using-statement-in-powershell
#>

#function Using-Object
#{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    try
    {
        . $ScriptBlock
    }
    finally
    {
        if ($null -ne $InputObject -and $InputObject -is [System.IDisposable])
        {
            $InputObject.Dispose()
        }
    }
#}
