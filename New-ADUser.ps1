<#
 # Zur Abfrage aller OUs unterhalb von einer OU Benutzerverwaltung:
 #
 # (&(objectCategory=organizationalUnit)(distinguishedName=*OU=BenutzerVerwaltung,*))
 #>


# Importiert das ActiveDirectory Modul
Import-Module ActiveDirectory

# Parameterdefinitionen
param(
    [string]$GivenName,
    [string]$Surname,
    [string]$SamAccountName,
    [string]$UserPrincipalName,
    [string]$DisplayName,
    [string]$Email,
    [string]$Password,
    [string]$Path = "OU=Users,DC=example,DC=com", # Hier die gewünschte Organisationseinheit (OU) und Domain angeben
    [string]$TemplateUserSamAccountName, # Der SAM-Account-Name des Benutzers, von dem die Gruppen kopiert werden sollen
    [string]$DefaultGroupName = "StandardGruppe" # Hier den Namen der Standardgruppe angeben, falls abweichend
)

# Erstellt den Benutzer
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

# Fügt den neu erstellten Benutzer zur Standardgruppe hinzu
Add-ADGroupMember -Identity $DefaultGroupName -Members $SamAccountName

# Überprüft, ob ein TemplateUserSamAccountName angegeben wurde
if ($TemplateUserSamAccountName) {
    # Ruft die Gruppen des angegebenen Benutzers ab
    $groups = Get-ADUser -Identity $TemplateUserSamAccountName -Properties MemberOf | Select-Object -ExpandProperty MemberOf

    # Fügt den neu erstellten Benutzer diesen Gruppen hinzu
    foreach ($group in $groups) {
        Add-ADGroupMember -Identity $group -Members $SamAccountName
    }
}

