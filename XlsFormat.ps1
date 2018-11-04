#requires -modules ImportExcel

[CmdletBinding()]
param (
	[parameter(mandatory=$true)] [string]$File,
    #Columns containing Byte Values
    [string[]]$ByteCols
)

if (-not (Test-Path($File))) {Write-Warning "$File not found!";exit 1}

$xlPkg = Export-Excel $File -PassThru -KillExcel -FreezePane 2,1 -AutoSize -AutoFilter -BoldTopRow
$ws=$xlPkg.Workbook.Worksheets[1]

#Process {[OfficeOpenXml.ExcelAddress]::GetAddress(1,$columnNumber) -replace '1',''}

#must be done first, or will unhide columns
$ws.Cells.AutoFitColumns()
$lines = 1

for($i = 1; $i -le $ws.Dimension.Columns; $i++) {
    $cell = [OfficeOpenXml.ExcelAddress]::GetAddress(1,$i)
    $col = $cell -replace '1',''
    #$ws.Cells[$cell].Value
    $val = $ws.Cells[$cell].Value -replace '\|',"`r`n"
    $lines = [math]::max($lines, ($val|measure -line|% Lines))
    if ($val -ne $ws.Cells[$cell].Value) {$ws.Cells[$cell].Value = $val}
    #"${cell}: $val"
    if ($val -in 'BMV_LOCATION_ID') {
        #Set-ExcelColumn -Worksheet $ws -Column $i -Hide -AutoSize
        $ws.Column($i) | Set-ExcelRange -Hidden
        "Hiding Column ${col}: $val"
    }
    if ($col -in $ByteCols) {
        Set-ExcelColumn -Worksheet $ws -Column $i -NumberFormat '[<500000]#,##0" B ";[<500000000]#,##0,," MB";#,##0,,," GB"' -AutoSize
    }
    if ($val -like '*date' -or $val -like 'DT_*') {
        Set-ExcelColumn -Worksheet $ws -Column $i -NumberFormat 'yyyy-mm-dd' -AutoSize
        "Setting Date Format for ${col}: ${val}"
    }
    if ($val -like '*phone*' -or $val -like '*fax*') {
        Set-ExcelColumn -Worksheet $ws -Column $i -NumberFormat '(000) 000-0000' -AutoSize
        "Setting Phone Format for ${col}: ${val}"
    }
    if ($val -like '*Zip5' -or $val -in 'ID_TOWN') {
        Set-ExcelColumn -Worksheet $ws -Column $i -NumberFormat '00000' -AutoSize
        "Setting Zip5 Format for ${col}: ${val}"
    }
    if ($val -like '*Zip4') {
        Set-ExcelColumn -Worksheet $ws -Column $i -NumberFormat '0000' -AutoSize
        "Setting Zip5 Format for ${col}: ${val}"
    }
}
Write-Verbose "Header Lines: $lines"
$height = 15 * $lines

$ws.Row(1) | Set-ExcelRange -Height $height

$xlPkg.Save()
$xlPkg.Dispose()

#Invoke-Item $file
