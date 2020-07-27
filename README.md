# ![EP](https://www.educationperfect.com/logo_16_16.png) class-list-formatter

This script is intended to reformat school class data exports into a format that can be automatically processed by Education Perfect.

## What is included
| File | Purpose |
| ---- | ------- |
| ```EPProcess.ps1``` | Script that handles all the re-formatting |
| ```config/classCodes.csv``` | Class codes to be included and what their description is |
| ```config/config.ps1``` | How to process your school's export file and any other configuration options required |
| ```config/rejects.csv``` | Class codes to be excluded, these are usually non-academic classes such as form rooms and study periods |

## Requirements
[PowerShell](https://docs.microsoft.com/en-us/powershell/)
This is included on all recent versions of Microsoft Windows and versions are avaliable for Linux, MacOS and ARM. EP is unable to provide support for installation of PowerShell.

## Installation
Download the repo and place anywhere on your machine.

Before running for the first time, you will need to modify all files within config folder for your school's particular set up.

## Usage
Copy your school's export file into the same folder you extracted the repo (default name is ```export.csv```), open a PowerShell terminal and run:
```sh
$ .\EPProcess.ps1
```

Depending on what is in the configuration files, you will usually find the following files have been created once the script has run (please note that larger files may require few minutes to run, depending on your system):

| File | Purpose |
| ---- | ------- |
| ```students.csv``` | Processed student data |
| ```teachers.csv``` | Processed teacher data |
| ```rejects.csv``` | Lines that have been rejected according to ```config/rejects.csv``` |
| ```unknown.csv``` | Lines that have no matching class code in ```config/classCodes.csv``` |

The first two files can be uploaded to EP's SFTP server (once configured with EP) or used in a Self Service Upload.
The last two files may need to be checked for classes that should have been included.

# Configuration
## ```config/config.ps1```
This file defines how to read your school's export format and any other processing particular to your school.
This can be edited in any plain text editor, but using Windows inbuilt PowerShell editor ***ISE*** is highly recommended.

#### files
This defines the input, output and required confguration file locations/names.
All file locations are relative to the main script.
| Variable | Usage | Required |
| -------- | ----- | -------- |
| rejectsFile | This is the file location that contains a list of Regular Expressions to reject class codes by | Yes |
| classCodesFile | This is the file location that contains a list of codes to accept and name classes by | Yes |
| inputFile | This is the name of the file that will be processed. This will usually be ```export.csv``` or ```relationships.csv``` At this time only CSV files are supported | Yes |
| studentOutFile | CSV file where student data will be placed | No |
| teacherOutFile | CSV file where teacher data will be placed | No |
| rejectsOutFile | CSV file where rejected data will be placed | No |
| unknownOutFile | CSV file where unknown data will be placed | No |
Please use "" to suppress creation of unrequired files

These file locations can be temporarily overwritten by providing the same variable and a file location when running ```.\EPProcess.sp1``` in PowerShell.
See ```get-help .\EPProcess.ps1 -Full ```
for a list of these parameters.

#### teachers
This defines how the script will read data pertaining to teachers.
Each variable matches to named column in your school's export file.
| Variable | Usage | Required |
| -------- | ----- | -------- |
| forename | Teacher forename | Yes |
| surname | Teacher surname. If both forename and surname are contained in one column, name that column in ```forename``` and leave this field blank.| No | 
| email | Teacher email address | Required to create new accounts and highly recommended |
| lti | Teacher LTI Identifier. Can be the same as ```teacher.email``` if your LTI identifier is the same.| No |
| sso | Teacher SSO Identifier. Can be the same as ```teacher.email``` if your SSO identifier is the same.| No |
| code | Teacher code | No |
Please use "" for any fields that are not required, for example, ```lti``` if your school does not have a LTI integration with EP.

#### students
This defines how the script will read data pertaining to students.
Each variable matches to a named column in your school's export file.
| Variable | Usage | Required |
| -------- | ----- | -------- |
| forename | Student forename | Yes |
| surname | Student surname | Yes | 
| studentID | Student ID | Sometimes |
| email | Student email address | Sometimes |
| lti | Student LTI Identifier. Can be the same as ```student.email``` if your LTI identifier is the same.| No |
| sso | Student SSO Identifier. Can be the same as ```student.email``` if your SSO identifier is the same.| No |
| UID | Unique Identifer for each student. Can be the same as ```student.email``` or ```student.studentID``` and must be on every single line | Yes |

Please use "" for any fields that are not required, for example under ```lti``` if your school does not have a LTI integration with EP

#### classes
This defines how the script will read data pertaining to classes.
Each variable matches to a named column in your school's export file.
| Variable | Usage | Required |
| -------- | ----- | -------- |
| prepend | Column to prepend to final class names | No |
| classCode | Class Code | Yes |
| regEx1,2,3 | Regular expressions to apply to ```classes.classCode``` | At least 1 of 3 |

Please use "" for any fields that are not required

##### Regular Expressions
Regular Expressions to be applied to ```classes.classCode```
For example: ```(?i)^(?'Year'\d+)(?'Code'[A-Z]{3})(?'Modifier'[A-z0-9]*)$``` which will match codes like the following:
* 7ENG1
* 12CHE10
* 08BIO2
* 7MATH (Stream H of MAT class, not MATH)

Avaliable named capture fields are:
| Name | Purpose | Required |
| --- | --- | --- |
| Campus | Code to prepend to start of final class name after ```[Current Year]``` | No |
| Year | Academic year | No |
| Modifier | Class modifier or stream code | No |
| Code | Class code used for look up in ```files.classCodes``` | Yes |

A final class name is generated on EP using the following formula:
```
[Current Year ][regEx.Campus ][classes.prepend ]Year [regEx.Year][.regEx.Modifier] [Class Description] ([Class Code]) - [Teacher/s Surnames]
```
```[Current Year ]``` and ```[Teacher/s Surnames]``` are added automatically at EP's end.

#### yearLevels
This list is used as a look up for year levels.
For example, a class code of ```XENG2```, the 'X' will become 'Year 10'

#### showSummary
Set this value to true to have a small summary output when the script is completed

## ```config/rejects.csv```
This file contains a list of Regular Expressions to reject class codes by.
For example:
| code | Description | Human readable |
| --- | --- | --- |
| ^(\d+STU) | Study periods | Any class starting with a number then STU (this is so ```Business Studies``` will still pass) |
| ^(\d+ASS) | Assembly | Remove Assembly classes (number included so that ```PASS``` wont be rejected |

## ```config/classCodes.csv```
This file contains a list of class codes and their human readable descriptions. Included is an example of the more common codes used by schools, but each school will have a few different codes.

For example:
| code | Description |
| --- | --- |
| SCI | Science |
| DSI | Double Science |

Any codes not on this list will be sent to ```files.unknown```

If there are any codes that you do not want to send to EP, for example, if only Languages is being purchased, then all others can be removed to stop them from being added to ```files.studentOutfile```

Only one description is avaliable per code (if more than one is found, the first will be used), so for example your school uses ```9MAT``` for **Mathematics 1** and ```10MAT``` for **Mathematics 2**, you would need to add ```MAT``` once with the description **Mathematics** to cover both cases.

## PreProcess and PostProcess
If these functions are included, they will run before and after processing respectively
