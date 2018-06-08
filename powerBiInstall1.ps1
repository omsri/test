$1 = "storageAccountName1"
$2 = "storageAccountName"
$dest= "C:/sysgain.txt"
$1  | Out-File $dest
$2  | Out-File $dest -Append
