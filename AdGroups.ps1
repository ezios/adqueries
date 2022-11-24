#Import-Module ActiveDirectory
# Get ad groups
#$OUpath = 'ou=groups,dc=ad,dc=google,dc=com'
$Groups = (Get-AdGroup -filter * | Where {$_.name -like "**"} | select name -ExpandProperty name)
#$groups = (Get-ADGroup -Filter * -SearchBase ^$OUpath | Select name -ExpandProperty name)
$liste = @()
$Record = @{
  "Groupe" = ""
  "Nom" = ""
  "username" = ""
}
Foreach ($Group in $Groups) {
  $members = Get-ADGroupMember -identity $Group -recursive | select name,samaccountname
  foreach ($Member in $members) {
    $Record."Groupe" = $Group
    $Record."Nom" = $Member.name
    $Record."Username" = $Member.samaccountname
    $objRecord = New-Object PSObject -property $Record
    $liste += $objrecord
  }
}
$liste | export-csv "C:\temp\SecurityGroups.csv" -NoTypeInformation