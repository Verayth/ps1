@{
    #$guid = [guid]::NewGuid().guid
    GUID = '46f4dd1f-30a2-48db-bc83-8e7b73e92fde'
    RootModule          = 'StarfieldAPI.psm1'
    ModuleVersion       = '1.0.0'
    Author              = 'Rob Brunelle'
    CompanyName         = ''
    Copyright           = '(c) 2023 Rob Brunelle. All rights reserved.'
    Description         = 'functions for accessing the Starfield Console API'
    PowerShellVersion   = '5.0'
    # CompatiblePSEditions = @()
    # PowerShellHostName = ''
    # PowerShellHostVersion = ''
    # DotNetFrameworkVersion = ''
    # CLRVersion = ''
    # ProcessorArchitecture = ''
    #RequiredModules = @('SOS.Common')
    # RequiredAssemblies = @()
    # ScriptsToProcess = @()
    # TypesToProcess = @()
    # FormatsToProcess = @()
    # NestedModules = @()
    FunctionsToExport = @(
        'Add-SFItems'
        'Connect-SFConsoleAPI'
        'Invoke-SFConsoleAPI'
        'Get-SFPlayerAV'
        'Submit-SFBatch'
        )
    CmdletsToExport = @(
        )
    VariablesToExport = @()
    AliasesToExport = @()
    # DscResourcesToExport = @()
    # ModuleList = @()
    # FileList = @()
    PrivateData = @{
        PSData = @{
            # Tags = @()
            # LicenseUri = ''
            # ProjectUri = ''
            # IconUri = ''
            # ReleaseNotes = ''
        }
    } # End of PrivateData hashtable

    # HelpInfoURI = ''
    # DefaultCommandPrefix = ''
}
