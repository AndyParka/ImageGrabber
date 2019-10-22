#Script to grab images from IP cameras and Save them into a directory.
#Directory is rotated daily
#script is intended to be run a scheduled task in windows
#By Andrew Parkinson



### Global Variables ###

$date = Get-Date -Format yyyy-MM-dd
$datetime = Get-Date -Format yyyy-MM-dd---hh-mm
$day = (get-date).dayofweek



### HOW TO USE ###

# 1. Fill out this list of cameras and URLs
# 2. Define Folder location of Today's captures
# 3. Define Folder location of previous day's captures
# 4. Define retention time on folders


############### 1. Fill out this list of cameras and URLs 
#
# NOTE: Last item in array does not end with a comma ,
#
### FORMAT:    [PSCustomObject]@{Name = "Tomago Shed 8";  URL = "http://i.imgur.com/gCSVwkml.jpg"},


$cameraURLArray = (

    [PSCustomObject]@{Name = "Tomago Shed 8";  URL = "http://i.imgur.com/gCSVwkml.jpg"},
    [PSCustomObject]@{Name = "Carrington"; URL = "http://i.imgur.com/AOgfU1q.jpg"}

)




############### 2. Define Folder location of Today's captures
#
# NOTE: This is the folder that the slideshow will be looking at
# EG:   "C:\Camera\Today"
#

# Location of Today's captures

$today = "C:\Camera\Today\"




############### 3. Define Folder location of previous day's captures
#
# NOTE: This is the folder that stores archives
#       Currently includes $date variable as a foldername to store each day's images in a new folder
# EG:   "C:\Camera\$date"
#       "C:\Camera\2019-10-22"
#

# Root location of historical captures - used for folder retention
$folderRoot = "C:\Camera\"

# Folder format - used by daily image captures
$folder = (  $folderRoot  +  $date  +  " - "  +  $day  +  "\"  ).ToString()




############### 4. Define retention time on folders 
#
# NOTE: Number represents the amount of days that images are kept before being deleted
#
# EG:   30 = today's date minus 30 days

$retentionDays = 2




######################################################################################################################

### Rest of the script ###


#Makes sure $today path exists to avoid exception
If (Test-Path  $today){

    #Checks $today folder for creation date
    $creationDate = (Get-Item -Path $today).CreationTime | Get-Date -f yyyy-MM-dd

    #If $today folder was created yesterday, delete it
    If ($creationDate -ne $date) 
    {
        Remove-Item $today –recurse -Verbose
    }
}
#


#Check existance of $today path, create if non-existant
If (!(Test-Path $today)){
    New-Item -ItemType "directory" -Path $today -Verbose
}
#


#Check existance of $folder path, create if non-existant
If (!(Test-Path $folder)){ 
    New-Item -ItemType "directory" -Path $folder -Verbose
}
#


#Invokes the WebClient PS object that is needed to download a file from a url
#
$webclient = New-Object System.Net.WebClient
#


#loop through #1 list of cameras and URLs and download each camera's image
#Copy image into the $today folder for viewing on the big screen
#
foreach($camera in $cameraURLArray) {
    

    #Output filename of each camera's image
    #This combines the file path with the current camera's name and current date-time.
    #EG output: C:\Camera\2019-10-22\Carrington - 2019-10-22---08-02.jpg
    #
    $filename = (  $folder  +  $camera.Name  +  " - "  +  $datetime  +  ".jpg"  ).ToString()
    #
    

    #Downloads the file
    #
    $webclient.DownloadFile($camera.URL, $filename)
    #


    #Copies the current photo into the $today folder
    #
    Copy-Item -Path $filename -Destination $today -Verbose
    #
}
#



# Delete folders older than specified retention time
#
# apply $retentionDays number as date variable
#
$age = (Get-Date).AddDays(-$retentionDays)
#


# Get all the files in the folder and subfolders | foreach file
#
Get-ChildItem $folderRoot -Recurse | foreach{

    # if creationtime is 'le' (less or equal) than $retentionDays days
    if ($_.CreationTime -le $age){

        # delete the folder
        Remove-Item $_.fullname -Recurse -Force -Verbose
        #
    }
}
#