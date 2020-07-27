<#
.Synopsis
Configuration file

.Description
v 2020.07.23
Please see https://github.com/EducationPerfect/class-list-formatter/ for more details
#>

$global:config = @{

	files = @{
		rejectsFile = "Config\rejects.csv"
		classCodesFile = "Config\classCodes.csv"
		inputFile = "export.csv"
		studentOutFile = "students.csv"
		teacherOutFile = "teachers.csv"
		rejectsOutFile = "rejects.csv"
		unknownOutFile = "unknown.csv"
	}
	
	teachers = @{
		forename = "Teacher forename"
		surname = "Teacher surname"
		email = "Teachers email"
		LTI = ""
		SSO = ""
		code = ""
	}
	
	students = @{
		forename = "FORENAME"
		surname = "SURNAME"
		studentID = "UPN Student"
		email = "Email"
		LTI = ""
		SSO = ""
		UID = "UPN Student"
	}
	
	classes = @{
        prepend = ""
		classCode = "CLASS NAME"
		regEx1 = "(?i)^(?'Year'\d+)(?'Code'[A-Z]{3})(?'Modifier'[A-z0-9]*)$"
		regEx2 = ""
		regEx3 = ""
	}
	
	yearLevels = @{
	"X"  = "10"
	"AE" = "11"
	"AT" = "12"
	
	"L1" = "11"
	"L2" = "12"
	"L3" = "13"
	"0001" = "00/01"
	"0102" = "01/02"
	"34" = "03/04"
	"45" = "04/05"
	"56" = "05/06"
	"67" = "06/07"
	"78" = "07/08"
	"89" = "08/09"
	"1011"="10/11"
	"1112"="11/12"
	"1213"="12/13"
	
	""   = "??"
	}
	
	showSummary = $false
}

