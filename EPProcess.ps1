<#
.Synopsis
Reformatter for your schools data export.
Will reformat your schools SMS export to 'students.csv' and 'teachers.csv' for upload to EPs SFTP server

.Description
v 2020.07.23
This tool will reformat your schools data export in to a format that can be automatically processed by EP.

The following file(s) are required:
-Config\config.ps1
 This file contains configuration data required by the tool and is contained in a seperate file as this data will be particular to your school.
 Please see https://github.com/EducationPerfect/class-list-formatter/ for more details

.PARAMETER rejectsFile
Override location and file name for rejects input file.

.PARAMETER classCodesFile
Override location and file name for classCodes input file.

.PARAMETER inputFile
Override location and file name for export input file.

.PARAMETER studentOutFile
Override location and file name for student output file. Use "" to suppress creation.

.PARAMETER teacherOutFile
Override location and file name for teacher output file. Use "" to suppress creation.

.PARAMETER rejectsOutFile
Override location and file name for rejects output file. Use "" to suppress creation.

.PARAMETER unknownOutFile
Override location and file name for unknown output file. Use "" to suppress creation.
#>

param(
    [string]$rejectsFile,
    [string]$classCodesFile,
    [string]$inputFile,
    [string]$studentOutFile,
    [string]$teacherOutFile,
    [string]$rejectsOutFile,
    [string]$unknownOutFile
    )

Set-PSDebug -Strict

#Load configuration parameters, not done before param() as it needs to run first
. Config\config.ps1

#Load defaults if not overridden
#Input files
if (!$PSBoundParameters.ContainsKey('rejectsFile')) {$rejectsFile = $global:config.files.rejectsFile}
if (!$PSBoundParameters.ContainsKey('classCodesFile')) {$classCodesFile = $global:config.files.classCodesFile}
if (!$PSBoundParameters.ContainsKey('inputFile')) {$inputFile = $global:config.files.inputFile}

#Output files
if (!$PSBoundParameters.ContainsKey('studentOutFile')) {$studentOutFile = $global:config.files.studentOutFile}
if (!$PSBoundParameters.ContainsKey('teacherOutFile')) {$teacherOutFile = $global:config.files.teacherOutFile}
if (!$PSBoundParameters.ContainsKey('rejectsOutFile')) {$rejectsOutFile = $global:config.files.rejectsOutFile}
if (!$PSBoundParameters.ContainsKey('unknownOutFile')) {$unknownOutFile = $global:config.files.unknownOutFile}

#Convert csv to utf8 due to bug in Import-CSV
$tempFile = "utf8" + $inputFile
Rename-Item -Path $inputFile -NewName $tempFile
Get-Content $tempFile | Set-Content -Encoding utf8 $inputFile
Remove-Item $tempFile

#Run any required PreProcess from config
if (Get-Command 'PreProcess' -ErrorAction SilentlyContinue){
    PreProcess
}

#Import reject list and create regex to use on CLASS NAME column
try {
    $rejectFile = Import-CSV $rejectsFile | select -ExpandProperty regex -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    "Error: $rejectsFile file not found"
    exit
}

#Add key to account for empty file, or else everything gets rejected
$rejectRegex = if($rejectFile.Count -gt 0){ $rejectFile -join "|"} else { "abc1234" }

#Import class code data
try {
    $classCodes = Import-Csv $classCodesFile | group -AsHashTable -Property Code -ErrorAction Stop
    if ($classCodes.Count -eq 0) {
        "Error: Class Codes file $classCodesFile empty"
        exit
    }
} catch [System.IO.FileNotFoundException] {
    "Error: Class Codes File $classCodesFile not found"
    exit
}

#Import spreadsheet data
try {
    $spreadsheet = Import-Csv $inputFile -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    "Error: Input file $inputFile not found"
    exit
}

#Extract teachers if requried/possible
if ($teacherOutFile -ne "" -and $global:config.teachers.surname -ne ""){
    #Do teachers
    $teachers = $spreadsheet | Select -Property `
    @{label="Forename";expression={$_.($global:config.teachers.forename)}},
    @{label="Surname";expression={$_.($global:config.teachers.surname)}},
    @{label="Email";expression={$_.($global:config.teachers.email).ToLower()}},
    @{label="SSO Identifier";expression={$_.($global:config.teachers.SSO).ToLower()}},
    @{label="LTI Identifier";expression={$_.($global:config.teachers.LTI).ToLower()}},
    @{label="Teacher Code";expression={$_.($global:config.teachers.code).ToUpper()}} `
    | Sort "Email" -Unique `
    | Where-Object{$_.Email -and $_.Forename -and $_.Surname}
    
    #Do post processing that can't be done in the select
    #SSO
    if ($global:config.teachers.SSO -eq ""){
        $teachers = $teachers | Select-Object -Property * -ExcludeProperty "SSO Identifier"
    }

    #LTI
    if ($global:config.teachers.LTI -eq ""){
        $teachers = $teachers | Select-Object -Property * -ExcludeProperty "LTI Identifier"
    }

    #Code
    if ($global:config.teachers.code -eq ""){
        $teachers = $teachers | Select-Object -Property * -ExcludeProperty "Teacher Code"
    }
    
    #Finally save it
    $teachers | Export-Csv -Path $global:config.files.teacherOutFile -Force -NoTypeInformation -Encoding utf8
}

#Join teachers forename and surname together if required else assume entire name
if ($global:config.teachers.surname -ne ""){
    $spreadsheet = $spreadsheet | Select-Object *, @{Name="Teacher/s";Expression={$_.($global:config.teachers.forename)+" "+$_.($global:config.teachers.surname)}}
} else {
    $spreadsheet = $spreadsheet | Select-Object *, @{Name="Teacher/s";Expression={$_.($global:config.teachers.forename)}}
    #TODO Split name up depending on comma or first space or capitals?
}

#Join staff name columns and group by student/classname for classes with more than one teacher
$spreadsheet = $spreadsheet | Group-Object -Property {$_.($global:config.students.UID) + $_.($global:config.classes.classCode)} 

#Set up collections for output files: uploads, rejects and unknown codes
$upload = @()
$rejected = @()
$unknown = @()

#Generate a nicely formatted output row that should be able to be automatically proccessed.
#Assume that class code matches at this point
function Generate-OutputRow($matches, $row){
    $campus = ""
    $prepend = ""
    $year = ""
    $modifier = ""
    $subject = ""
    $code= ""


    #Campus code
    if($matches['Campus'].Length -gt 0){
        $campus = $matches['Campus']+" ";
    }

    #Prepend field
    if($global:config.classes.prepend.Length -gt 0){
        $prepend = $row.Group[0].($global:config.classes.prepend)+" ";
    }

    #Year, look up code or convert to two digits
    if($matches['Year'].Length -gt 0){
	    if($global:config.yearLevels.($matches['Year']).Length -gt 0) {
			$yearLevel = $global:config.yearLevels.($matches['Year'])
			#Check if we already have a word else, prepend Year
		    if ($yearLevel -like "* *"){
				$year = $yearLevel
			} else {
				$year = "Year "+ $yearLevel
			}
	    } else {
		    $year = "Year {0:d2}" -f [int32]($matches['Year'])
	    }
    }

    #Modifier
    if ($year.Length -gt 0){
        if ($matches['Modifier'].Length -gt 0){
            $modifier ="." + $matches['Modifier'] + " "
        } else {
            $modifier = " "
        }
    }

    #Subject
    $subject = $classCodes[$matches['Code']].Description

    #code
    $code = $matches[0]

    #Generate class name
    $classname = $campus + $prepend + $year + $modifier + $subject + " (" + $code + ")"

    #Generate student row
    $outputrow = [PSCustomObject]@{
        Forename = $row.Group[0].($global:config.students.forename)
        Surname = $row.Group[0].($global:config.students.surname)
        Class = $classname
        "Teacher/s" = $row.Group."Teacher/s" -Join ", "
        "Student ID" = $row.Group[0].($global:config.students.studentID)
        Email = $row.Group[0].($global:config.students.email)
        "LTI Identifier" = $row.Group[0].($global:config.students.LTI)
        "SSO Identifier" = $row.Group[0].($global:config.students.SSO)
    }

    #Do post processing that can't be done in the custom object
    #Student ID
    if ($global:config.students.studentID -eq ""){
        $outputrow = $outputrow | Select-Object -Property * -ExcludeProperty "Student ID"
    } 

    #LTI
    if ($global:config.students.LTI -eq ""){
        $outputrow = $outputrow | Select-Object -Property * -ExcludeProperty "LTI Identifier"
    }

    #SSO
    if ($global:config.students.SSO -eq ""){
        $outputrow = $outputrow | Select-Object -Property * -ExcludeProperty "SSO Identifier"
    }
   
    return $outputrow
}

#Progress indicator
$currentCount = 1
$totalRows = $spreadsheet.Count
#Loop through all row data
Foreach ($row IN $spreadsheet)
{
Write-Progress -Activity "Processing" -Status "Progress: Row $currentCount of $totalRows" -PercentComplete ((($currentCount++)/$totalRows)*100)
#Cascading if statements here instead of a switch?
    switch -regex ($row.Group.($global:config.classes.classCode))
    {
        #Ditch rejected class codes
        $rejectRegex
        {
            $rejected += $row.Group
            break
        }

        #Work on class codes that match expected format 1
        $global:config.classes.regEx1
        {            
            if ($global:config.classes.regEx1 -ne ""){
                #Do we have a matching code?
                If ($classCodes.ContainsKey($matches['Code'])) {
                    $upload += Generate-OutputRow $matches $row
                } else {
                    $unknown += $row.Group
                }
                break
            }
        }

        #Work on class codes that match expected format 2
        $global:config.classes.regEx2
        {            
            if ($global:config.classes.regEx2 -ne ""){
                #Do we have a matching code?
                If ($classCodes.ContainsKey($matches['Code'])) {
                    $upload += Generate-OutputRow $matches $row
                } else {
                    $unknown += $row.Group
                }
                break
            }
        }

        #Work on class codes that match expected format 3
        $global:config.classes.regEx3
        {            
            if ($global:config.classes.regEx3 -ne ""){
                #Do we have a matching code?
                If ($classCodes.ContainsKey($matches['Code'])) {
                    $upload += Generate-OutputRow $matches $row
                } else {
                    $unknown += $row.Group
                }
                break
            }
        }

        #Anything else: Didn't match any RegEx pattern provided
        ""
        {
            $unknown += $row.Group
            break
        }
    }
}

#Export processed data
if ($studentOutFile -ne "") {$upload | Export-Csv -Path $studentOutFile -NoTypeInformation -Force -Encoding utf8}

#Export rejected data
if ($rejectsOutFile -ne "") {$rejected | Export-Csv -Path $rejectsOutFile -NoTypeInformation -Force -Encoding utf8}

#Export unknown class codes
if ($unknownOutFile -ne "") {$unknown | Export-Csv -Path $unknownOutFile -NoTypeInformation -Force -Encoding utf8}

if($global:config.showSummary){
    Write-Output "Processing Report"
    Write-Output "-----------------"

    Write-Output "`nProcessed Rows:"
    Write-Output "---------------"
    $tmp_accepted = $upload.length
    $tmp_rejected = $rejected.length
    $tmp_unknown = $unknown.length
    $tmp_total = ($tmp_accepted + $tmp_rejected + $tmp_unknown)
    Write-Output "Accepted:`t $tmp_accepted"
    Write-Output "Rejected:`t $tmp_rejected"
    Write-Output "Unknown:`t $tmp_unknown"
    Write-Output "Total:`t`t $tmp_total"


    Write-Output "`nProcessed Classes:"
    Write-Output "------------------"
    $tmp_accepted = ($upload | sort-Object -Property "Class" -Unique).Count
    $tmp_rejected = ($rejected | sort-Object -Property "CLASS NAME" -Unique).Count
    $tmp_unknown = ($unknown | sort-Object -Property "CLASS NAME" -Unique).Count
    $tmp_total = ($tmp_accepted + $tmp_rejected + $tmp_unknown)
    Write-Output "Accepted:`t $tmp_accepted"
    Write-Output "Rejected:`t $tmp_rejected"
    Write-Output "Unknown:`t $tmp_unknown"
    Write-Output "Total:`t`t $tmp_total"


    Write-Output "`nProcessed Students:"
    Write-Output "-------------------"
    $tmp_accepted = ($upload | sort-Object -Property "Student ID" -Unique).Count
    $tmp_rejected = ($rejected | sort-Object -Property "UPN Student" -Unique).Count
    $tmp_unknown = ($unknown | sort-Object -Property "UPN Student" -Unique).Count
    $tmp_total = ($spreadsheet.Group | sort-Object -Property "UPN Student" -Unique).Count
    Write-Output "In accepted classes:`t $tmp_accepted"
    Write-Output "In rejected classes:`t $tmp_rejected"
    Write-Output "In unknown classes:`t`t $tmp_unknown"
    Write-Output "In all classes:`t`t`t $tmp_total"
}

#Run any required PostProcess from config
if (Get-Command 'PostProcess' -ErrorAction SilentlyContinue){
    PostProcess
}