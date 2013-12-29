<#
.SYNOPSIS
Stacks csv/tsv input by frequency of occurence. Header and delimiter may be passed as arguments.
Output is written to tsv files.
.DESCRIPTION
Get-StakRank.ps1 parses multiple separated values input files, the user may specify the delimiter and 
header just as with import-csv, if not specified csv is assumed with the first row assumed to be the 
header row. The user specifies the fields by which to stack the data, defaulting in ascending order, 
creating a table where less frequently occuring items bubble up, if mutliple fields are provided as 
an argument, those fields will be ranked in combination.

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
Specifies output should be in descending order. Ascending is default.
.PARAMETER Key
Data should be sorted by the key.
.PARAMETER Value
Data should be sorted by the value, this is the default. The values sorted by are the
elements supplied by the user via the Fields argument.
.PARAMETER Roles
Output should be ranked by roles -- assumes input file names contain some role identifier.
.PARAMETER Fields
Specifies the field or fields to rank.
.EXAMPLE
Get-StakRank -FileNamePattern .\CADataCenter\*autoruns.csv -Roles .\CADataCenter\ServerRoles.txt -Fields MD5, "Image Path"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FileNamePattern,
    [Parameter(Mandatory=$False)]
        [char]$Delimiter=",",
    [Parameter(Mandatory=$False)]
        [string]$Header="",
    [Parameter(Mandatory=$False)]
        [switch]$Desc=$False,
    [Parameter(Mandatory=$False)]
        [switch]$Key=$False,
    [Parameter(Mandatory=$False)]
        [string]$RoleFile="",
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
<#
.SYNOPSIS
Returns the list of input files matching the user supplied file name pattern.
Traverses subdirectories.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$FileNamePattern
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    Write-Verbose "Looking for files matching user supplied pattern, $FileNamePattern"
    Write-Verbose "This process traverses subdirectories so it may take some time."
    $Files = @(ls -r $FileNamePattern | % { $_.FullName })
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
    $Fields = @()
    Write-Verbose "Attempting to extract input file headers from ${File}."
    $HeaderRow = gc $File -TotalCount 1
    $Fields = @($HeaderRow -split $Delimiter)
    Write-Verbose "Extracted the following fields: $($Fields -join $Delimiter)"
    $Fields
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Get-Roles {
<#
.SYNOPSIS
Reads roles from a text file, one role per line. Think of roles as smart name elements 
common to specific groups of things (i.e. computernames from HR dept. containing "HR")
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$RoleFile
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

function Get-FieldList {
<#
.SYNOPSIS
Returns the user supplied fields as a scriptblock to be used in the ranking.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [array]$Fields
)
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $FieldList = $Fields -join "`" + `"``t`" + `$_.`""
    $FieldList += "`""
    $FieldList = "`$_.`"" + $FieldList
    Write-Verbose "`$FieldList is ${FieldList}."
    $FieldList
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

function Get-Rank {
<#
.SYNOPSIS
The heart of the script where the actual ranking of the data happens. I'm looking for way to refactor and improve
readability and performance.
#>
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [array]$Files,
    [Parameter(Mandatory=$True,Position=1)]
        [char]$Delimiter,
    [Parameter(Mandatory=$True,Position=2)]
        [Array]$Header,
    [Parameter(Mandatory=$False)]
        [array]$Roles,
    [Parameter(Mandatory=$False)]
        [boolean]$Desc,
    [Parameter(Mandatory=$False)]
        [boolean]$Key,
    [Parameter(Mandatory=$True)]
        [Array]$Fields
)        
    Write-Verbose "Entering $($MyInvocation.MyCommand)"
    $FieldList = Get-FieldList $Fields

    $DictScriptblock = {
        if ($Dict.ContainsKey($Element)) {
            Write-Verbose "Incrementing ${Element}."
            $Dict.Set_Item($Element, $Dict.Get_Item($Element) + 1)
        } else {
            Write-Verbose "Adding ${Element}."
            $Dict.add($Element, 1)
        }
    }

    $OutScriptblock = {
        if ($Role) {
            $Outheader = "Count`tRole`t"
        } else {
            $Outheader = "Count`t"
        }
        $Outheader += $Fields -join "`t"
        $Outheader += "`r`n"
        $Output = ""
        if ($Key) {
            Write-Verbose "Writing out by key."
            if ($Desc) {
                $Output += $Dict.GetEnumerator() | Sort-Object -Desc key,value | % {[string]$_.Value + "`t" + $_.Key + "`r`n"}
            } else {
                $Output += $Dict.GetEnumerator() | Sort-Object key,value | % {[string]$_.Value + "`t" + $_.Key + "`r`n"}
            }
        } else {
            Write-Verbose "Writing out by value."
            if ($Desc) {
                $Output += $Dict.GetEnumerator() | Sort-Object -Desc value,key | % {[string]$_.Value + "`t" + $_.Key + "`r`n"}
            } else {
                $Output += $Dict.GetEnumerator() | Sort-Object value,key | % {[string]$_.value + "`t" + $_.key + "`r`n"}
            }
        }
        $Output = $Outheader += $Output
        $FieldsFileName = $Fields -join "-"
        if ($Role) {
            $Output | Set-Content -Encoding Ascii ${Role}-${FieldsFileName}.tsv
        } else {
            $Output | Set-Content -Encoding Ascii -Path $(${FieldsFileName} + ".tsv")
        }
    }

    if ($Roles) {
        Write-Verbose "We have roles..."
        $PrefixFieldList = "`$Element = `$Role + `"``t`" + "
        $PrefixFieldList += $FieldList
        $FieldList = $PrefixFieldList
        $FieldList += $DictScriptblock
        $Scriptblock = [scriptblock]::Create($FieldList)
        foreach ($Role in $Roles) {
            Write-Verbose "Processing role ${Role}."
            $InputData = @()
            $Dict = @{}
            $FilesInRole = $Files | ? { $_ -match $Role}
            if ($FilesInRole) {
                foreach ($File in $FilesInRole) {
                    Write-Verbose "Reading ${File}."
                    $InputData += Import-Csv -Path $File -Delimiter $Delimiter -Header $Header
                }
            } else {
                Write-Verbose "No files found matching role, ${Role}. Continuing."
                Continue
            }
            Write-Verbose "Building dictionary of stack ranked elements for ${Role}."
            $InputData | % $Scriptblock
            & $OutScriptblock
        }
    } else {
        Write-Verbose "We have no roles..."
        $PrefixFieldList = "`$Element = `"``t`" + "
        $PrefixFieldList += $FieldList
        $FieldList = $PrefixFieldList
        $FieldList += $DictScriptblock
        $Scriptblock = [scriptblock]::Create($FieldList)
        Write-Verbose "Processing all up."
        $InputData = @()
        $Dict = @{}
        foreach($File in $Files) {
            Write-Verbose "Reading ${File}."
            $InputData += Import-Csv -Path $File -Delimiter $Delimiter -Header $Header
        }
        Write-Verbose "Building dictionary of stack ranked elements all up."
        $InputData | % $Scriptblock
        & $OutScriptblock
    }
    Write-Verbose "Exiting $($MyInvocation.MyCommand)"
}

$Files, $Roles, $InputFileHeader = @()
$FieldList = ""
Write-Verbose "Starting up $($MyInvocation.MyCommand)"
if ($RoleFile) {
    $Roles = @(Get-Roles $RoleFile)
}
$Files = @(Get-Files $FileNamePattern)
$InputFileHeader = @(Get-FileHeader $Files[0] $Delimiter)
Check-Fields $InputFileHeader $Fields $Delimiter
Write-Debug "User supplied fields, ${Fields}, found in input file."
Get-Rank -Files $Files -Delimiter $Delimiter -Header $InputFileHeader -Roles $Roles -Desc $Desc -Key $Key -Fields $Fields
Write-Verbose "Exiting $($MyInvocation.MyCommand)"
