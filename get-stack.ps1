<#
.SYNOPSIS
Stacks csv/tsv input by frequency of occurence. Header and delimiter may be passed as arguments.
.DESCRIPTION
Get-Stack.ps1 takes a separated values input file, the user may specify the delimiter and header just
as with import-csv, if not specified csv is assumed with the first row assumed to be the header row. 
The user specifies the fields by which to stack the data, defaulting in ascending order, creating a 
table where less frequently occuring items bubble up, if mutliple fields are provided as an argument,
those fields in combination will be paired or tupled.

If you don't know the fields and you're frequently working with various separated values files, 
https://github.com/davehull/Get-Fields.ps1, may be useful.

.PARAMETER Path
Specifies the path to the separated values file.
.PARAMETER LiteralPath
Specifies the literal path to the separated values file.
.PARAMETER Delimiter
Specifies the single character delimiter.
.PARAMETER Header
Specifies header values for the delimited file.
.PARAMETER Asc
Specifies output should be in ascending order, default.
.PARAMETER Desc
Specifies output should be in descending order.
.PARAMETER Key
Data should be sorted by the key.
.PARAMETER Value
Data should be sorted by the value.
.PARAMETER Fields
Specifies the field or fields to rank.
.Parameter ShowFields
Causes the script to return the field names.
.EXAMPLE
Get-Stack -Path .\autouns.tsv -delimiter "`t" -Asc -Key
#>

[CmdletBinding()]
Param(
    [Parameter(ParameterSetName='Path',Mandatory=$True,Position=0)]
        [string]$Path,
    [Parameter(ParameterSetName='LitPath',Mandatory=$True,Position=0)]
        [string]$LiteralPath,
    [Parameter(Mandatory=$False)]
        [char]$Delimiter=",",
    [Parameter(Mandatory=$False)]
        [string]$Header,
    [Parameter(Mandatory=$False)]
        [switch]$Desc=$False,
    [Parameter(Mandatory=$False)]
        [switch]$Key=$False,
    [Parameter(Mandatory=$True)]
        [array]$fields
)

switch ($PSCmdlet.ParameterSetName) {
    Path { 
        if ($Header.Length -gt 0) {
            $Data = Import-Csv -Path $Path -Delimiter $Delimiter -Header $Header
        } else {
            $Data = Import-Csv -Path $Path -Delimiter $Delimiter
        }
    }
    LitPath {
        if ($Header.Length -gt 0) {
            $Data = Import-Csv -LiteralPath $Path -Delimiter $Delimiter -Header $Header
        } else {
            $Data = Import-Csv -LiteralPath $Path -Delimiter $Delimiter
        }
    }
}

function Missing-Fields {
<#
.SYNOPSIS
Verifies the user supplied fields are found in the input file.
Returns list of missing fields or $
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [PSCustomObject]$Data,
    [Parameter(Mandatory=$True,Position=1)]
        [Array]$Fields
)
    $fileFields = $missingFields = @()
    $fileFields = $data | get-member | ? { $_.MemberType -eq "NoteProperty" } | Select Name
    foreach($Field in $Fields) {
        if ($fileFields.name -notcontains $Field) {
            $missingFields += $Field
        }
    }
    if ($missingFields.Length -gt 1) {
        Write-Host "[+] Error: User supplied fields, " + ($missingFields -join ", ") + ", were not found."
        exit
    } elseif ($missingFields.Length -eq 1) {
        Write-Host "[+] Error: User supplied field, $missingFields, was not found."
        exit
    }
}

Missing-Fields $Data $Fields
Write-Debug "[*] User supplied fields, $Fields, found in input file."

<#
$stackDict = @{}

$Data | ? { $_.FailureReason -eq "" } | % { $fieldValue = $_.$field + "`t" + $_.LogonType + "`t" +$_.SubjectUserName
    if ($stack.containskey($fieldValue)) {
        $stack.set_item($fieldValue, $stack.get_item($fieldValue) + 1)
    } else {
        $stack.add($fieldValue, 1)
    }
}

$data_out = $stack.GetEnumerator() | sort-object value,key | % {[string]$_.value + "`t" + $_.key + "`r`n"}

$data_out.trim()
#> 
