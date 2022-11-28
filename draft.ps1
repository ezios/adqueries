#to run on domain controller, list of computer in a specific group
function getCOmputersInLocalGroup {
    param ([string]$group)
    $computers = net localgroup $group /domain | select-string '\$$'
    if ($computers.match){
        return $computers.Line
    }
}

Function _GetServerNameFromPath {
    param([string]$oupath)
    return ($oupath | Select-String "dc=.+").Matches.Value.replace('dc=','').replace(',','.')
}
Function getACLs {
    param ([string[]]$searchBase)
    $report = @()
    $schemaIDGUID = @{}
    $server = _GetServerNameFromPath $searchBase
    $computers= Get-ADComputer -Filter * -SearchBase * -server $server | Select-Object -ExpandProperty DistinguishedName

#Loop through each of the AD computer and retrieve their permissions.
ForEach ($computer in $computers) {
    $report += Get-Acl -Path "AD:\$computer" |
     Select-Object -ExpandProperty Access | 
     Select-Object @{name='DN';expression={$computer}}, `
                   @{name='objectTypeName';expression={if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') {'All'} Else {""}}}, `
                   *}
                    # Filter by single user and export to a CSV file.
    $report  | Select-Object IdentityReference, ActiveDirectoryRights, DN, IsInherited -Unique |
Export-Csv -Path "Permissions.csv" -NoTypeInformation
Write-Host $report
}


Import-Module ActiveDirectory
# Array for report.
$report = @()
$schemaIDGUID = @{}
# ignore duplicate errors if any #
$ErrorActionPreference = 'SilentlyContinue'
Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID |
 ForEach-Object {$schemaIDGUID.add([System.GUID]$_.schemaIDGUID,$_.name)}
Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID |
 ForEach-Object {$schemaIDGUID.add([System.GUID]$_.rightsGUID,$_.name)}
$ErrorActionPreference = 'Continue'
# Get a list of AD objects.
$AOs  = @(Get-ADDomain | Select-Object -ExpandProperty DistinguishedName)
$AOs += Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
$AOs += Get-ADObject -SearchBase (Get-ADDomain).DistinguishedName -SearchScope Subtree -LDAPFilter '(objectClass=*)' | Select-Object -ExpandProperty DistinguishedName
# Loop through each of the AD objects and retrieve their permissions.
# Add report columns to contain the path.
ForEach ($AO in $AOs) {
    $report += Get-Acl -Path "AD:\$AO" |
     Select-Object -ExpandProperty Access | 
     Select-Object @{name='organizationalunit';expression={$AO}}, `
                   @{name='objectTypeName';expression={if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') {'All'} Else {$schemaIDGUID.Item($_.objectType)}}}, `
                   @{name='inheritedObjectTypeName';expression={$schemaIDGUID.Item($_.inheritedObjectType)}}, `
                   *
} # Filter by single user and export to a CSV file.
$User ='Username'
$report | Where-Object {$_.IdentityReference -like "*$User*"} | Select-Object IdentityReference, ActiveDirectoryRights, OrganizationalUnit, IsInherited -Unique |
Export-Csv -Path "C:\data\explicit_permissions.csv" -NoTypeInformatio
