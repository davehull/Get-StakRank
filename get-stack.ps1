<#
.SYNOPSIS
Stacks csv/tsv input by frequency of occurence. Header and delimiter may be passed as arguments.
.DESCRIPTION
Get-Stack.ps1 takes a separated values input file, the user may specify the delimiter and header just
as with import-csv, if not specified csv is assumed with the first row assumed to be the header row. 
The user specifies the fields by which to stack the data, defaulting in ascending order, creating a 
table where less frequently occuring items bubble up, if mutliple fields are provided as an argument,
those fields in combination will be paired or tupled.
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

function Get-Data {
<#
.SYNOPSIS
Open delimite file, read into variable, return variable
.PARAMETER Path
Specifies the full path to the input file
.PARAMETER Delimiter
Specifies the delimiter for the input file
.PARAMETER Header
Specifies the header for the input file, if none, first line of file is used
#>
Param(
    [Parameter(ParameterSetname='path',Mandatory=$True,Position=0)]
        [string]$Path,
    [Parameter(ParameterSetname='litpath',Mandatory=$True,Position=0)]
        [string]$LiteralPath,
    [Parameter(Mandatory=$False,Position=1)]
        [char]$Delimiter=",",
    [Parameter(Mandatory=$False,Position=2)]
        [string]$Header
)
    if ($Header.Length -gt 0) {
        try {
            import-csv -Path $Path -Delimiter $Delimiter -Header $Header
        } catch {}
    }


}

switch ($PSCmdlet.ParameterSetName) {
    Path { 
        if ($Header.Length -gt 0) {
            $data = get-data -Path $Path -Delimiter $Delimiter -Header $Header
        } else {
            $data = get-data -Path $Path -Delimiter $Delimiter
        }
    }
    LitPath {
        if ($header.Length -gt 0) {
            $data = get-data -Path $Path -Delimiter $Delimiter -Header $Header
        } else {
            $data = get-data -Path $Path -Delimiter $Delimiter
        }
    }

<# 
$data = import-csv -delimiter "`t" $file

$stack = @{}

$data | ? { $_.FailureReason -eq "" } | % { $fieldValue = $_.$field + "`t" + $_.LogonType + "`t" +$_.SubjectUserName
    if ($stack.containskey($fieldValue)) {
        $stack.set_item($fieldValue, $stack.get_item($fieldValue) + 1)
    } else {
        $stack.add($fieldValue, 1)
    }
}

$data_out = $stack.GetEnumerator() | sort-object value,key | % {[string]$_.value + "`t" + $_.key + "`r`n"}

$data_out.trim()
#>
