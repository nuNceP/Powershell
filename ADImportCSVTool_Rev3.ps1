##################################################
####                Parameters                ####
##################################################

####!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!####
#!!! Remember to disable password complexity  !!!#
#!!!     requirements during the execution    !!!#
#!!!                 of this script           !!!#
####!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!####

    $csvpath = "C:$($env:HOMEPATH)\Downloads\Migration Scripts" #Folder to read from CSV Export
    $logpath = $csvpath #Path where to save log files and password list
    $rootDomain = "DC=edu,DC=ndc,DC=nato,DC=int" #AD style domain root
    $rootUpn = "@edu.ndc.nato.int" #UPN Style DESTINATION domain root
    $sourceUpn = "@public.ndc.nato.int" #UPN Style SOURCE domain root
    $dcname = "EDUAD1" #DC to operate on


##################################################
####                 Switches                 ####
##################################################


    $commit = $true

    #Disable import functions, use with caution!
    $createGroups = $true #Will automatically disable memberships process
    $applyMemberships = $true
    $createMailboxes = $true

    #The following switches will not work if commit is active
    $printUsers  = $false
    $printGroups = $false
    $printMemberships = $false
    $printMailboxes = $true

#################################################
#################################################
#################################################

function New-Passwd {
<#

#Credits https://community.spiceworks.com/scripts/show/4632-new-passwd-a-human-pronounceable-password-generator

.SYNOPSIS
A simple script that generates a random, but human-pronounceable password.

.DESCRIPTION
Version: 2.0
This script creates a random password based on human-pronounceable syllables.
You can adjust the number of syllables, and when working with it interactively,
includes the ability to generate multiple passwords. The generated password
will include a symbol character in a random location, and a 2-4 digit number suffix.

When integrating this function into a script, you'll likely want to use the -HideOutput
switch to prevent the password from being outputted to the console.

.EXAMPLE
New-Passwd

Default generates one password that is four (4) syllables long, 15-17 character length total.

Example output:
PS > Jabgot@darsay8472

.EXAMPLE
New-Passwd -Length 20 -Count 5

Generates 5 passwords that are each 20-syllables long.

Example output:
PS > Neoreonuasantotlenlodjusveitavfihpotretvifruajigvuolua;tiuket6348
PS > Coasuukocfekbestajbacnutbabheptaksegcui.sesnadsotjuncaesojpou7255
PS > Paeruamohsadheimukbanneakui;pujgodmejsuinegjaobitfoffejgafheu2701
PS > Hapdaobagtiecokbihlubkiurubroelephep-munlijdumgemcuspagmuvkub4728
PS > Dejtegbia{gonbimpilpiltavvardiiribdujsevvujfovripdornopjiodoj3586

.EXAMPLE
New-Passwd -HideOutput

Generates one default password that is four (4) syllables long, 15-17 character length total,
and does not show the output. It is useful to include this switch when calling from within
a script where you will be using the $script:Passwd variable elsewhere.
Default is to write output.

Example output:
PS > 

#>
    [cmdletbinding()]
    param(
        [Parameter(Position=0)]
        #Default length in syllables.
        [Int]$Length = 4,
        [Parameter(Position=1)]
        #Default number of passwords to create.
        [Int]$Count = 1,
        [Parameter(Position=2)]
        #Hides the output. useful when used within a script.
        [Switch]$HideOutput
    )
    Begin {
        #consonants except hard to speak ones
        [Char[]]$lowercaseConsonants = "bcdfghjklmnprstv"
        [Char[]]$uppercaseConsonants = "BCDFGHJKLMNPRSTV"
        #vowels
        [Char[]]$lowercaseVowels = "aeiou"
        #both
        $lowercaseConsantsVowels = $lowercaseConsonants+$lowercaseVowels
        #numbers
        [Char[]]$numbers = "0123456789"
        #special characters
        [Char[]]$specialCharacters = '!$.;#@{+&}?:+_="%>-*/^'+"'"

        $countNum = 0
    }
    Process {
        while ($countNum -le $Count-1) {
            $script:Passwd = ''
            #random location for special char between first syllable and length
            $specialCharSpot = Get-Random -Minimum 1 -Maximum $Length
            for ($i=0; $i -lt $Length; $i++) {
                if ($i -eq $specialCharSpot) {
                    #add a special char
                    $script:Passwd += ($specialCharacters | Get-Random -Count 1)
                }
                #Start with uppercase
                if ($i -eq 0) {
                    $script:Passwd += ($uppercaseConsonants | Get-Random -Count 1)
                } else {
                    $script:Passwd += ($lowercaseConsonants | Get-Random -Count 1)
                }
                $script:Passwd += ($lowercaseVowels | Get-Random -Count 1)
                $script:Passwd += ($lowercaseConsantsVowels | Get-Random -Count 1)
            }
            #add a number at the end
            $randNumNum = Get-Random -Minimum 2 -Maximum 5
            $script:Passwd += (($numbers | Get-Random -Count $randNumNum)-join '')
            if ($HideOutput) {
                # The $Passwd is not shown as output.
            } else {
                Write-Output "$script:Passwd"
            }
            $countNum++
        }
    }
}

function pathLevelUp ($dname) {
    $dname = domainReplace $dname
    #Returns DN= on 1 , name on 2 and basepath on 3
    $void = $dname -match "([A-Z]{2}=)(.+?),(.*)"
    return $matches
}

function domainReplace ($adpath) {
    #Replace domain root for imported data
    $adpath -replace "(DC=[A-Za-z]+?,)+(DC=[A-Za-z]+?$)", $rootDomain
    return
}

function upnDomainReplace ($upn, $upnRoot) {
    #Replace email and up domain
    $result = $upn -replace "@.+(\..+)+", $upnRoot
    return
}

function timeDoc {
    $currDate = Get-Date -Format ("yyyyMMdd_hhmmss")
    return $currDate
}

function createUser ($givenname, $surname, $name, $samname, $oupath, $description, $email, $enabled, $password) {
    $oupath = domainReplace $oupath

    #Check if OUs exist, if not create them
    If ($commit -eq $true) {
        createOU $oupath
    }
    #Check if user is enabled
    If ($enabled -eq "True") {
        $uEnabled = $true
    } else {
        $uEnabled = $false
    }

    $basePath = (pathLevelUp $oupath)[3]

    #Generate a password for the new user, create it and log the related data
    try {
        If ($commit -eq $true) {
            If ($givenname -eq "" -and $surname -eq "") {
                $displayname = $name
            } Else {
                $displayname = ("$($givenname) $($surname)").Trim()
            }
        New-ADUser -Name $name -Surname $surname -GivenName $givenname -DisplayName $displayname -Description $description -EmailAddress $email -SamAccountName $samname -UserPrincipalName $samname$rootupn -ChangePasswordAtLogon $true -Path $basePath -Enabled $uEnabled -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Server $dcname
        } ElseIf ($printUsers -eq $true) {
            Write-Host New-ADUser -Name $name -Surname $surname -GivenName $givenname -DisplayName "$($givenname) $($surname)" -Description $description -EmailAddress $email -SamAccountName $samname -UserPrincipalName $samname$rootupn -ChangePasswordAtLogon $true -Path $basePath -Enabled $uEnabled -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Server $dcname
        }
        $now = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
        Out-File -FilePath $logpath\passwords_$($startTime).csv -Append -InputObject "$($now),$($samname),$($name),$($newPassword)"
        Out-File -FilePath $logfile -InputObject "$samname,User,SUCCESS" -Append
    } catch {
        Write-Warning "User creation $samname - $Error[0]"
        Out-File -FilePath $logfile -InputObject "$samname,User,FAILED,Password:$password $Error[0]" -Append
    }
}

function createGroup ($name, $samname, $oupath, $scope, $type, $description) {
    $oupath = domainReplace $oupath
    #Check if OUs exist, if not create them
    createOU $oupath

    $basePath = (pathLevelUp $oupath)[3]

    #Create group based on exported data
    try {
        If ($commit -eq $true) {        
            New-ADGroup -Name $name -SamAccountName $samname -Path $basePath -GroupScope $scope -GroupCategory $type -Description $description -Server $dcname
        } ElseIf ($printGroups -eq $true) {
            Write-Host New-ADGroup -Name $name -SamAccountName $samname -Path $basePath -GroupScope $scope -GroupCategory $type -Description $description -Server $dcname
        }
        Out-File -FilePath $logfile -InputObject "$name,Group,SUCCESS" -Append
    } catch {
        Write-Warning "Group creation $samname - $Error[0]"
        Out-File -FilePath $logfile -InputObject "$name,Group,FAILED,$Error[0]" -Append
    }
}

function createMailbox ($samname, $smtpAddresses) {
    #New-Mailbox -FirstName $firstname -LastName $lastname -Name "$($firstname) $($lastname)" -UserPrincipalName $email -ResetPasswordOnNextLogon $true -Password (ConvertTo-SecureString $password -AsPlainText -Force)
    $newEmail, $aliasEmails = $smtpAddresses
    $newEmail = $newEmail -replace "SMTP:", ""
    If ($newEmail -ne "" -and $newEmail -match ".+$($sourceUpn -replace "\.", "\.")") {
        If ($commit -eq $true) {   
            try {
                #Enable mailbox from AD User
                Enable-Mailbox -Identity $($samname).Trim() -DomainController $dcname -Alias ($newEmail -replace "@.+(\..+)+", "")
                Out-File -FilePath $logfile -InputObject "$samname,Mailbox,SUCCESS" -Append    
            } catch {
                Write-Warning "Mailbox creation $samname ($newEmail) $Error[0]"
                Out-File -FilePath $logfile -InputObject "$samname,Mailbox,FAILED,$Error[0]" -Append  
            }
            If ($aliasEmails.Count -gt 0) {
                #Configure aliases and set default one
                Set-Mailbox -Identity $($samname).Trim() -DomainController $dcname -EmailAddressPolicyEnabled $false -EmailAddresses ($smtpAddresses -replace $sourceUpn, $rootUpn)
                Set-Mailbox -Identity $($samname).Trim() -DomainController $dcname -EmailAddressPolicyEnabled $false -PrimarySmtpAddress ($newEmail -replace $sourceUpn, $rootUpn)
            }
        } Elseif ($printMailboxes -eq $true) {
            Write-Host Enable-Mailbox -Identity $samname -DomainController $dcname -Alias ($newEmail -replace "@.+(\..+)+", "")
            Write-Host Set-Mailbox -Identity $samname -EmailAddresses ($smtpAddresses -replace $sourceUpn, $rootUpn)
            Write-Host Set-Mailbox -Identity $samname -PrimarySmtpAddress ($newEmail -replace $sourceUpn, $rootUpn)
        }
    }
}

function createOU ($adpath) {
    #Check if the current OU exists, if not create the whole structure
    $adpath = domainReplace $adpath
    $currentPath = (pathLevelUp $adpath)[3]
    $currentName = (pathLevelUp $currentPath)[2]
    $parentPath = (pathLevelUp $currentPath)[3]
    
    #If reached domain root stop recursion
    if ($currentPath -match "^(CN=[A-Za-z0-9]+?,)?(DC=[A-Za-z0-9]+?,)+(DC=[A-Za-z0-9]*)$") {
        return
    }
    try {
        #Test if OU exists
        $void = Get-ADOrganizationalUnit $currentPath -Server $dcname
        return
    } catch {
        #Check nested structure by reiterating the function
        createOU $currentPath
        #Write-Host "OU $currentPath Needs creation under $parentPath with name $currentName"
        New-ADOrganizationalUnit -Path $parentPath -Name $currentName -ProtectedFromAccidentalDeletion $false -Server $dcname
        Out-File -FilePath $logfile -InputObject "$currentName,OU,SUCCESS" -Append
    }

}
#LogFile
$startTime = timeDoc
$logfile = "$($logpath)\import_$($startTime).log"
Out-File -FilePath $logfile -InputObject "Name,Type,Result,Notes"

#Create Users
$userList = Import-Csv -Path $csvpath\Users.csv -Delimiter "#"
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
Foreach ($user in $userList) {

    $newPassword = New-Passwd
    createUser `
        $($user.GivenName).Trim() `
        $($user.Surname).Trim() `
        $($user.Name).Trim() `
        $($user.SamAccountName).Trim() `
        $($user.DistinguishedName).Trim() `
        $($user.Description).Trim() `
        $($user.EmailAddress).Trim() `
        $user.Enabled $newPassword

    If ($user.Enabled -eq $true -and $createMailboxes -eq $true) {
        #If user is enabled create mailbox
        $smtpAddresses = $user.ProxyAddresses -Split ","
        createMailbox $user.SamAccountName $smtpAddresses
    }
}

#Create Groups
$groupList = Import-Csv -Path $csvpath\Groups.csv -Delimiter "#"
If ($createGroups -eq $true) {
    Foreach ($group in $groupList) {
        createGroup `
            $($group.Name).Trim() `
            $($group.SamAccountName).Trim() `
            $($group.DistinguishedName).Trim() `
            $($group.GroupScope).Trim() `
            $($group.GroupCategory).Trim() `
            $($group.Description).Trim()
    }
}

#Group Memberships
$memberships = Import-Csv -Path $csvpath\Memberships.csv -Delimiter "#"

Foreach ($member in $memberships) {
    If ($commit -eq $true -and $applyMemberships -eq $true -and $createGroups -eq $true) {
        try {
            Add-ADGroupMember -Members $($member.SamAccountName).Trim() -Identity $($member.GroupName).Trim() -Server $dcname
            Out-File -FilePath $logfile -InputObject "$($member.SamAccountName)->$($member.GroupName),Membership,SUCCESS" -Append
        } catch {
            Write-Warning $Error[0]
            Out-File -FilePath $logfile -InputObject "$($member.SamAccountName)->$($member.GroupName),Membership,FAILED,$Error[0]" -Append
        }
    } ElseIf ($printMemberships -eq $true) {
        Write-Host Add-ADGroupMember -Members $member.SamAccountName -Identity $member.GroupName -Server $dcname
    }
}
