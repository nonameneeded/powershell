<#
 # Zur Abfrage aller OUs unterhalb von einer OU Benutzerverwaltung:
 #
 # (&(objectCategory=organizationalUnit)(distinguishedName=*OU=BenutzerVerwaltung,*))
 #>
# Importiert das ActiveDirectory Modul
Import-Module ActiveDirectory

# Funktion zum Generieren eines komplexen Kennworts
function Generate-ComplexPassword {
    param (
        [int]$length = 30
    )

    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '1234567890'
    $specialChars = '!@#$%^&*()-_=+{}[]|\;:",.<>?'

    $password = -join ($lowercase | Get-Random) +
               -join ($uppercase | Get-Random) +
               -join ($numbers | Get-Random) +
               -join ($specialChars | Get-Random)

    $allChars = $lowercase + $uppercase + $numbers + $specialChars
    $password += -join (1..($length - 4) | ForEach-Object { Get-Random -InputObject $allChars })

    return -join ($password.ToCharArray() | Get-Random -Count $length)
}

# Parameterdefinitionen
param(
    [string]$GivenName,
    [string]$Surname,
    [string]$UserPrincipalName,
    [string]$DisplayName,
    [string]$Email,
    [string]$Path = "OU=Users,DC=example,DC=com",
    [string]$DefaultGroupName,
    [string]$TemplateUserSamAccountName
)

# Generiere SAM Account Name
$SamAccountName = ($GivenName[0] + $Surname).ToLower()
$count = 1
while (Get-ADUser -Filter { SamAccountName -eq $SamAccountName }) {
    $SamAccountName = ($GivenName[0] + $Surname + $count).ToLower()
    $count++
}

# Generiere Passwort
$Password = Generate-ComplexPassword

# Erstelle den Benutzer
New-ADUser -GivenName $GivenName `
          -Surname $Surname `
          -SamAccountName $SamAccountName `
          -UserPrincipalName $UserPrincipalName `
          -DisplayName $DisplayName `
          -EmailAddress $Email `
          -Name "$GivenName $Surname" `
          -Path $Path `
          -AccountPassword (ConvertTo-SecureString -AsPlainText $Password -Force) `
          -Enabled $true

# Füge den neu erstellten Benutzer zur optionalen Standardgruppe hinzu, falls angegeben
if ($DefaultGroupName) {
    Add-ADGroupMember -Identity $DefaultGroupName -Members $SamAccountName
}

# Überprüft, ob ein TemplateUserSamAccountName angegeben wurde
if ($TemplateUserSamAccountName) {
    $groups = Get-ADUser -Identity $TemplateUserSamAccountName -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    foreach ($group in $groups) {
        Add-ADGroupMember -Identity $group -Members $SamAccountName
    }
}

# Ausgabe des generierten Passworts
Write-Output "Generiertes Passwort für $SamAccountName: $Password"

