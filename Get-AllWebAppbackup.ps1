#Login to Azure Account
Login-AzureRmAccount

#Get list of all Subscription
Get-AzureRmSubscription

#Select appropriate subscription from the List
$sbName = "<name of Subscription>"
Select-AzureRmSubscription -SubscriptionName $sbName

#Get all the webapp in slected subscription
$webApps = Get-AzureRmWebApp
Write-Host ($webApps | Measure-Object).Count #to get count of webapps

#Below code will create csv file for each webapp backup
foreach($webapp in $webApps)
{
    $webappBackups = Get-AzureRmWebAppBackupList -Name $webapp.SiteName -ResourceGroupName $webapp.ResourceGroup
    $name = $webapp.SiteName
    
    #if backup is configured for the webapp
    if($webappBackups){
        $webappBackups | Select-Object -Property ResourceGroupName, Name , Created | Export-Csv "C:\tmp\$name.csv"    
    }else{
        Write-Host $name "backup has not been configured"
    }
}

#Since the backup list is sorted in backup date. So we can fetch the oldest and the latest backup date. And keeping the header as backup created and LatestRecoveryPoint
$getFirstLine = $true
Get-ChildItem "C:\tmp\*.csv" | foreach{
    $filePath = $_
    $top3data = Get-Content $filePath | select -First 3
    $linesToWrite = Switch($getFirstLine){
        $true {$top3data}
        $false {$top3data | Select -Skip 2}
    }
    $getFirstLine = $false
    Add-Content "C:\tmp\AllFirstRowData" $linesToWrite

    $lastRow = (Get-Content $filePath)[-1]
    $lastRow = $lastRow.Split(,)
    $lastRowData = $lastRow[2]
    Add-Content "C:\tmp\LastRowData.csv" $lastRowData
}

import-csv "C:\tmp\LastRowData.csv" -Header LatestRecoveryPoint | 
  export-csv "C:\tmp\LastRowData1.csv"

#Combing result of oldest backup and latest backup and keeping in a new file.
$file1 = Import-Csv "C:\tmp\AllFirstRowData"
$file2 = impoer-csv "C:\tmp\LastRowData1.csv"
$i=0
$file1 | foreach {
    $_ | Add-memeber -type NoteProperty -name LatestRecoveryPoint -value $file2[i].LatestRecoveryPoint
    $i++
}
$file1 | export-csv "C:\result.csv" -nottype

#Delete all the files which are not required, created in tmp folder.
Get-ChildItem "C:\tmp\*.csv" | foreach{
    Remove-Item $_
}