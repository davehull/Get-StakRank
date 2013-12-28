<#
.SYNOPSIS
Stacks csv/tsv input by frequency of occurence. Header and delimiter may be passed as arguments.
Output is written to tsv files.
.DESCRIPTION
Get-StakRank.ps1 parses multiple separated values input files, the user may specify the delimiter and 
header just as with import-csv, if not specified csv is assumed with the first row assumed to be the 
header row. The user specifies the fields by which to stack the data, defaulting in ascending order, 
creating a table where less frequently occuring items bubble up, if mutliple fields are provided as 
an argument, those fields in combination will be ranked in combination.

If you don't know the fields and you're frequently working with various separated values files, 
https://github.com/davehull/Get-Fields.ps1, may be useful, alternatively, providing incorrect fields
throws an error that lists the fields found in the first input file that matches the supplied
file name pattern.

.PARAMETER FileNamePattern
Specifies the pattern common to the files to be ranked.
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
Data should be sorted by the value, this is the default.
.PARAMETER Roles
Output should be ranked by roles -- assumes input file names contain some role identifier.
.PARAMETER Fields
Specifies the field or fields to rank.
.EXAMPLE
Get-StakRank -FileNamePattern .\*.autoruns.tsv -delimiter "`t" -Asc -Key -Fields MD5, "Image Path"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$False)]
        [char]$Delimiter=",",
    [Parameter(Mandatory=$False)]
        [string]$Header,
    [Parameter(Mandatory=$False)]
        [switch]$Desc=$False,
    [Parameter(Mandatory=$False)]
        [switch]$Key=$False,
    [Parameter(Mandatory=$False)]
        [string]$RoleFile,
    [Parameter(Mandatory=$True)]
        [array]$Fields
)

function Check-Fields {
<#
.SYNOPSIS
Verifies the user supplied fields are found in the input file.
If user supplied fields are not found in input file header, an 
error is written and the script exits.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [Array]$FileFields,
    [Parameter(Mandatory=$True,Position=1)]
        [Array]$UserFields,
    [Parameter(Mandatory=$True,Position=2)]
        [Char]$Delimiter
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $MissingFields = @()
    foreach($Field in $UserFields) {
        Write-Debug "`$Field is $Field"
        Write-Debug "`$FileFields is $($FileFields -join $Delimiter)"
        if ($FileFields -notcontains $Field) {
            $MissingFields += $Field
        }
    }
    if ($MissingFields.Length -gt 1) {
        Write-Error "[+] Error: User supplied fields, $($MissingFields -join ", "), were not found in `n`t$($FileFields -join $Delimiter)"
        Write-Verbose "Exiting $($MyInvocation.MyCommand)"
        exit
    } elseif ($MissingFields.Length -eq 1) {
        Write-Error "[+] Error: User supplied field, $MissingFields, was not found in `n`t$($FileFields -join $Delimiter)"
        Write-Verbose "Exiting $($MyInvocation.MyCommand)"
        exit
    }
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Get-Files {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$FileNamePattern
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $Files = @()
    Write-Verbose "Looking for files matching user supplied pattern, $FileNamePattern"
    Write-Verbose "This process traverses subdirectories so it may take some time."
    $Files += ls -r $FileNamePattern | % { $_.FullName }
    if ($Files) {
        Write-Verbose "File(s) matching pattern, ${FileNamePattern}:`n$($Files -join "`n")"
        $Files
    } else {
        Write-Error "No input files were found matching the user supplied pattern, ${FileNamePattern}."
        Write-Verbose "Exiting $($MyInvocation.MyCommand)"
        exit
    }
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}


function Get-FileHeader {
<#
.SYNOPSIS
Get the header row from the first file in the list of files supplied by the user.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$File,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $Headr, $Fields = @()
    Write-Verbose "Attempting to extract input file headers from ${File}."
    $HeaderRow = gc $File -TotalCount 1
    $Fields = $HeaderRow -split $Delimiter
    Write-Verbose "Extracted the following fields: $($Fields -join $Delimiter)"
    $Fields
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Get-Roles {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        $RoleFile
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    if (Test-Path $RoleFile) {
        $Roles = gc $RoleFile
        Write-Verbose "Found the following roles in ${RoleFile}: ${Roles}"
    } else {
        Write-Error "User specified role file, ${RoleFile}, was not found."
        Write-Verbose "Exiting $($MyInvocation.MyCommand)"
        exit
    }
    $Roles
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Get-Rank {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$Files
)
Write-Verbose "Entering $($MyInvocation.MyCommand)"

Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

$Files = @()
Write-Verbose "Starting up $($MyInvocation.MyCommand)"
if ($RoleFile) {
    $Roles = Get-Roles $RoleFile
}
$Files = Get-Files $FileNamePattern
$InputFileHeader = Get-FileHeader $Files[0] $Delimiter
Check-Fields $InputFileHeader $Fields $Delimiter
Write-Debug "User supplied fields, ${Fields}, found in input file."
Write-Verbose "Exiting $($MyInvocation.MyCommand)"

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
