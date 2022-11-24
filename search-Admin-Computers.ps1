[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$oupaths

)
#Add-WindowsCapability –online –Name “Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0”
$Folder = "C:/Temp"
# Retrieve all organizational unit within the domain, proceed by OU in case of interruption. 
function Get-Oupath {
     $Oufile = Join-Path $Folder "$(Get-Date -Format 'yyyy-MM-dd.ssmmHH')_organizationalUnit.csv"
     $ADOu = Get-ADOrganizationalUnit -Properties CanonicalName -Filter * | Sort-Object CanonicalName |
     ForEach-Object {
        [pscustomobject]@{
        Name          = Split-Path $_.CanonicalName -Leaf
        CanonicalName = $_.CanonicalName
        DistinguishedName = $_.DistingshedName
        #ComputerCount     = @(Get-ADComputer -Filter * -SearchBase $_.DistinguishedName -SearchScope OneLevel).Count
        }
    }
    $ADOu | Export-Csv -Path $Oufile -Delimiter ";" -NoTypeInformation -Encoding UTF8 -Force 
    Write-Host("Exported list of Organizational unit in $Oufile")
    return $ADOu
}

#pour chaque OU, récupérer la liste des groupes, et pour chaque groupe récupérer la liste des membres
foreach ($oupath in $oupaths ){
    $liste = @()
    $Record = @{
    "Groupe" = ""
    "Nom" = ""
    "Compte" = ""
    "Conteneur" = ""}
    Write-Host "[$((Get-date).datetime)] - Get list of groups in $oupath"
    $Groups = (Get-ADGroup -Filter * -SearchBase $oupath | Select name -ExpandProperty name)
    
    foreach ($Group in $Groups) {
        Write-Host "`t[$((Get-date).datetime)] - Get members of group : $Group"
        $members = Get-ADGroupMember -identity $Group -recursive | select name,samaccountname
        foreach ($Member in $members) {
            $Record."Group" = $Group
            $Record."Machine Name" = $Member.name
            $Record."SAM Account" = $Member.samaccountname
            $Record."Oupath" = $oupath
            $objRecord = New-Object PSObject -property $Record
            $liste += $objrecord
        }
    }
    
}
$liste | export-csv "C:\temp\SecurityGroups.csv" -NoTypeInformation