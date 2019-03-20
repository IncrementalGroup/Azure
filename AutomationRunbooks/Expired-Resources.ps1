<#
    .DESCRIPTION
        An example runbook which gets all the ARM resources using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Azure Automation Team
        LASTEDIT: Mar 14, 2016
#>

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 

}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#Set current date in format of tags
$today = Get-Date -Format yyyy-MM-dd

#Get Credentials for sending emails
$creds = Get-AutomationPSCredential -Name 'test account'

#get all resource that have old expirydate tags
$Resources = Get-AzResource -TagName ExpiryDate | Where-Object {$_.Tags['ExpiryDate'] -le $today}
$Resources
foreach($Resource in $Resources)
{
   $body = @"
       Owner: $($Resource.Tags['Owner'])
        Project: $($Resource.Tags['Project'])
        ExpiryDate: $($Resource.Tags['ExpiryDate'])
        ResourceName: $($Resource.Name)
        ResourceGroup: $($Resource.ResourceGroupName)
        ResourceType: $($Resource.ResourceType) 
"@

    Send-MailMessage -from "Zoe Mackay <zoe.mackay@incrementalgroup.com>" `
                     -to "Zoe Mackay <zoe.mackay@incrementalgroup.com>" `
                     -subject "Resource Alert" `
                     -body $Body `
                     -Credential $creds `
                     -Port 587 `
                     -smtpServer 'smtp.office365.com' -UseSsl

}

