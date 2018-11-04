#requires -version 3
# -modules FormatPx

param([string[]] $Text)


function ConvertFrom-LinuxDfOutput {
    param([string[]] $Text)
    [regex] $HeaderRegex = '\s*File\s*system\s+(1024|1K)-blocks\s+Used\s+Avail(able)?\s+Capacity\s+Mounted\s*on\s*'
    [regex] $LineRegex = '^\s*(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\s*%)\s+(.+)\s*$'
    $Lines = @($Text -split '[\r\n]+')
    if ($Lines[0] -match $HeaderRegex) {
        foreach ($Line in ($Lines | Select -Skip 1)) {
            if ($Line -match $LineRegex) {
                [regex]::Matches($Line, $LineRegex) | foreach {
                    New-Object -TypeName PSObject -Property @{
                        Filesystem = $_.Groups[1].Value
                        '1K-blocks' = [decimal] $_.Groups[2].Value
                        Used = [decimal] $_.Groups[3].Value * 1024
                        Available = [decimal] $_.Groups[4].Value * 1024
                        Capacity = [decimal] ($_.Groups[5].Value -replace '\D') / 100
                        MountedOn = $_.Groups[6].Value
                    } | Select Filesystem, 1K-blocks, Used, Available, Capacity, MountedOn
                }
            } else {
                Write-Warning -Message "Error matching data line: $Line"
            }
        }
    }
    else {
        Write-Warning -Message "Error in output. Failed to recognize headers from 'df --portability' output."
    }
}

$format=(
    @{Name="Filesystem"  ;Alignment='Left' ;Expression={$_.Filesystem}},
    #@{Name="1K-blocks"   ;Alignment='Right';Expression={$_.'1K-blocks'}},
    @{Name="Used     "   ;Alignment='Right';Expression={Get-FriendlySize $_.Used}},
    @{Name="Available"   ;Alignment='Right';Expression={Get-FriendlySize $_.Available}},
    @{Name="Capacity"    ;Alignment='Right';FormatString='{0:N0}%';Expression={$_.Capacity*100}},
    @{Name="MountedOn"   ;Alignment='Left' ;Expression={$_.MountedOn}}
)

ConvertFrom-LinuxDfOutput -Text $Text | Format-Table ($format)

#$Text
#$Lines
