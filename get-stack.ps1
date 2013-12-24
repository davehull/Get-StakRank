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
.EXAMPLE
Get-Stack -Path .\autouns.tsv -delimiter "`t" -Asc -Key
#>

Param(
    [Parameter(Mandatory=$True,Position=1)]
        [string]$Path,
    [Parameter(Mandatory=$False,Position=2)]
        [char]$Delimiter=",",
    [Parameter(Mandatory=$False,Position=3)]
        [string]$Header,
    [Parameter(Mandatory=$False,Position=4)]
        [switch]$Asc,
    [Parameter(Mandatory=$False,Position=5)]
        [switch]$Desc,
    [Parameter(Mandatory=$False,Position=6)]
        [switch]$Key,
    [Parameter(Mandatory=$False,Position=7)]
        [switch]$Value
)

function Get-Delimiter {
<#
.SYNOPSIS
Determines what delimiter was provided, if none, returns comma
.PARAMETER Delimiter
Specifies the single character delimiter.
#>
Param(
    [Parameter(Mandatory=$False)]
        [char]$Delimiter=","
)
    $Delimiter
}

Get-Delimiter $Delimiter
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
