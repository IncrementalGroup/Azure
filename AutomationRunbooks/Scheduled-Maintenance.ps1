<#
    .DESCRIPTION
        Runbook to highlight all resources that have gone past their expiry date

    .NOTES
        AUTHOR: Zoe Mackay
        LASTEDIT: Mar 13, 2019
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

#get all virtual machines
$VMs = Get-AzVM -Status | Where-Object {$_.MaintenanceRedeployStatus -ne $null}

foreach($VM in $VMs)
{
    Write-Output $VM
    
    $body = @"
        Machine: $($VM.Name)
        ResourceGroup: $($VM.ResourceGroupName)
        Owner:$($VM.Tags['Owner'])
        Project:$($VM.Tags['Project'])
        ExpiryDate:$($VM.Tags['ExpiryDate'])
        MaintenanceAllowed: $($VM.MaintanceAllowed)
        MaintenanceRedeployStatus: $($VM.MaintenanceRedeployStatus)
"@
    $creds = Get-AutomationPSCredential -Name 'test account'
    
    Send-MailMessage -from "Zoe Mackay <test.zoemackay@incrementalgroup.com>" `
                       -to "Zoe Mackay <zoe.mackay@incrementalgroup.com>" `
                       -subject "Sending the Attachment" `
                       -body $body `
                       -Credential $creds `
                       -Port 587 `
                       -smtpServer 'smtp.office365.com' -UseSsl
}