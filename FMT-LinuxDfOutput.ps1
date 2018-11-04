(
    @{Name="Filesystem"  ;Alignment='Left' ;Expression={$_.Filesystem}},
    @{Name="1K-blocks"   ;Alignment='Right';Expression={$_.'1K-blocks'}},
    @{Name="Used"        ;Alignment='Right';Expression={Get-FriendlySize $_.Used}},
    @{Name="Available"   ;Alignment='Right';Expression={Get-FriendlySize $_.Available}},
    @{Name="Capacity"    ;Alignment='Right';FormatString='{0:N0}%';Expression={$_.Capacity*100}},
    @{Name="MountedOn"   ;Alignment='Left' ;Expression={$_.MountedOn}}
)
