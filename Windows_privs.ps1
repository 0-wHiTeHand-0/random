# https://github.com/cutaway-security/chaps
# To run it:
# Open Powershell as admin
# Set-ExecutionPolicy Bypass -scope Process
# IEX (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/cutaway-security/chaps/master/chaps.ps1')

$FolderPath = dir -Directory -Path "C:\<PATH TO FOLDER>\" -Recurse -Force
$Report = @()
Foreach ($Folder in $FolderPath) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $acl.Access)
        {
            $Properties = [ordered]@{'FolderName'=$Folder.FullName;'ADGroup or User'=$Access.IdentityReference;'Permissions'=$Access.FileSystemRights;'Inherited'=$Access.IsInherited}
            if ( ($Access.IdentityReference -like "*Users*") -and ($Access.FileSystemRights -like "*Modify*") )
            {
                $Report += New-Object -TypeName PSObject -Property $Properties
            }
        }
}
$Report | Export-Csv -path "C:\<PATH>\Desktop\Permissions.csv"