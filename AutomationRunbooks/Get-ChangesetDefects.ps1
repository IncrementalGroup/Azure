
$TokenAccess = Get-AutomationVariable -Name 'Token' 
$SMTPServer = Get-AutomationVariable -Name 'SMTPServer' 
Write-Output $SMTPServer
$baseAuthInfo =  @{Authorization = ‘Basic ‘ + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(“:$($TokenAccess)”))}

$url = 'https://dev.azure.com/incrementalgroup/SMS%20D365%20Finance%20and%20Operations/_apis/tfvc/changesets?api-version=5.0'


$changesets = Invoke-RestMethod -Uri $url -headers $baseAuthInfo -Method GET -ContentType "application/json" #-Body $bodyJson

$array = @()
foreach($changeset in $changesets.value)
{
    $id = $changeset.changesetid
    $createdDate = $changeset.createdDate -replace "T", " "
    
    $uri = "https://dev.azure.com/incrementalgroup/_apis/tfvc/changesets/$id/workItems?api-version=5.0"
    $workitems = Invoke-RestMethod -Method GET -Uri $URI -Headers $baseAuthInfo -ContentType "application/json"
    
    if($workitems.count -ne 0)
    {

        foreach($workitem in $workitems.value)
        {
            $Object = New-Object PSObject –Property @{
                ChangesetID = $id
                CreationDate=$createdDate
                CheckedIn = $changeset.author.displayName
                ChangesetComment = $changeset.comment
                WorkitemID = $workitem.id
                WorkitemTitle = $workitem.title
                WorkitemType = $workitem.workitemType     
            }

            $array +=  $object
        }
    }
}

$fileName = 'Changeset-Workitems.csv'
$array | Export-Csv $fileName -NoTypeInformation


$creds = Get-AutomationPSCredential -Name SMTPCreds 
Send-MailMessage `
        -from "Zoe Mackay <zoe.mackay@incrementalgroup.com>" `
        -to "Zoe Mackay <zoe.mackay@incrementalgroup.com>" `
        -subject "Azure DevOps Report" `
        -body "Attached is the latest changeset/workitem report" `
        -Attachment $fileName `
        -Credential $creds `
        -smtpServer $SMTPServer -UseSsl
