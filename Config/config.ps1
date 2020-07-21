<#
.Synopsis
Configuration file

.Description
v 2020.07.08
Required files(inputs):
-----------------------
-files.rejectsFile
	This file defines regular expressions to be applied to class names to reject by.
	Rejected classes are usually non-academic classes. This is an exclusion list.
	Any data that matches these Regular Expressions will be output to files.rejectsOutFile
	This file will usually have been provided by EP staff based on existing provided data, but below is a base to create your own.
	Please note that adding a regular expression to this list will not remove it from EP, it just stops it being sent/updated from your end.
	___________________________________________
	|regex             | Description          |
	-------------------------------------------
	|(STUDY)           | Remove study periods |
	|([A-Z]{1}\d{1,2}) | Remove form classes  |
	-------------------------------------------

-files.classCodesFile
	This file contains mappings of 3-4 letter class codes to human readable descriptions.
	These mappings are required for licencing and categorizations. This is an inclusion-list.
	Any data that doesn't match these codes will be output to files.unknownOutFile
	This file will usually have been provided by EP staff based on existing provided data, but below is a base to create your own.
	Modifying a class description will not change the name on EP, it will likely create a duplicate class instead. Please change the name in the Control Panel as well if this is required.
	Please note that any duplicate codes, will result in only the first Description found being used.
	
	__________________________________
	|Code      | Description         |
	----------------------------------
	|SCI       | Science             |
	|ENG       | English             |
	|EENG      | Essential English   |
	|MAT       | Maths               |
	----------------------------------

	It is possible to add extra codes to the bottom of this file to have them included in the student upload file.
	For example, if your school is also signing up for Languages, you could add the following:
	|GER       | German              |
	|FRE       | French              |
	|SPA       | Spanish             |
	|CHI       | Chinese             |
	----------------------------------
	Please note that the above are only suggestions and will depend on the particular naming conventions for class codes in your school.
	Do not include the year level or the modifier/stream code(eg the class codes of 12SCIA, 11SCIB and 12SCIB, would only require SCI to be added to this file)
 
-files.inputFile
	This is the file to process, usually the export from your student management system
	
Optional File(outputs):
-----------------------
-files.studentOutFile
	Where to output processed student data, this file is to be uploaded to '/students/' on EPs SFTP server
	Use "" to suppress creation
	
-files.teacherOutFile
	Where to output teacher data, this file is to be uploaded to '/teachers/' on EPs SFTP server
	Use "" to suppress creation
	
-files.rejectsOutFile
	Where to output rejected student data, please review this file to double check none of these classes should be in files.studentOutFile
	Use "" to suppress creation
	
-files.unknownOutFile
	Where to output unknown student data, please review this file to double check none of these classes should be in files.studentOutFile
	Any classes that are in this file that should have been in files.studentOutFile will need to be added to files.classCodes and process script re-run.
	
	For example, if 12SCIA and 11SCIB are in this file, please add the following to files.classCodes
	|SCI       | Science             |
	----------------------------------
	Use "" to suppress creation
  
Teacher data:
-------------
-teachers.forename
	Column name containing Teachers Forename. Please do not include titles eg Mr. This is a required column.
	
-teachers.surname
	Column name containing Teachers Surname. Use "" if entire name is contained in teachers.forename. If there is only one field for a teachers full name, files.teachers will not be able to be generated.

-teachers.email
	Column name containing Teacher Email address. This is a required column.
	
-teachers.LTI
	Column name containing Teachers LTI Identifier.
	Can be the same as teacher.email if your LTI identifier is the same.
	Use "" if your school does not use LTI Identifiers with EP
	
-teachers.SSO
	Column name containing Teachers SSO Identifier.
	Can be the same as teacher.email if your SSO identifier is the same.
	Use "" if your school does not use SSO Identifiers with EP
	
Student data:
-------------
-students.forename
	Column name containing Students Forename. This is a required column.
	
-students.surname
	Column name containing Students Surname. This is a required column.

-students.email
	Column name containing Students Email address. This is a highly reccomended column.
	
-students.studentID
	Column name containing Students ID. This is an optional column but highly reccommended, use "" if not required.
	
-students.LTI
	Column name containing Students LTI Identifier.
	Can be the same as students.email if your LTI identifier is the same.
	Use "" if your school does not use LTI Identifiers with EP
	
-students.SSO
	Column name containing Students SSO Identifier.
	Can be the same as students.email if your SSO identifier is the same.
	Use "" if your school does not use SSO Identifiers with EP

-students.UID
	Column name containing a unique identifier for each student in your school and *must* be provided on *every* row in your export.
	This will usually be the same as -students.email column unless your school doesn't use email addresses or has partial coverage, in which case it will need to be something like the students.studentID column
	This value is required as it is used to group classes that have more than one teacher. Mistyping this value will well break things.

Class data:
-----------
-classes.prepend
    Column name to be prepended to the start of the class name, used for EP schools that have more than one Campus
    Use "" if the field is not required

-classes.classCode
	Column name containing unique class codes, eg 12SCIA. This is a required column
	
-classes.rexEx1
-classes.regEx2
-classes.regEx3
	These field defines Regular Expressions to be applied to -classes.classCode
	The default is "(?i)^(?'Year'\d+)(?'Code'[A-Z]{2,})(?'Modifier'\d*)$" which will match codes like the following
	7ENG1
	12CHE10
	08BIO2
	7MATH
	
	The named capture field "Code" is required at a minimum.
	Capture fields are:
	- Campus
	- Year
	- Modifier
	- Code
	
    A final class name is generated on EP using the following formula:
    [Current Year ][-regEx.Campus ][-classes.prepend ]Year [-regEx.Year][.-regEx.Modifier] [Class Description] ([Class Code]) - [Teacher/s Surnames]

	Use "" if the regEx[2-3] fields are not required

Additional functions:
---------------------
-PreProcess
-PostProcess
	If the above functions are provided in this file, they will run before and after processing is done in the main script.
	Often these will be provided to perform additional tasks particular to your school, such as adding a term number to class names
	
	Not required, but please do not remove if provided
	
-showSummary
	If set to true, a small summary of the processing will be output
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
		regEx1 = "(?i)^(?'Year'\d+)(?'Code'[A-Z]{3,})(?'Modifier'\d+)$"
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