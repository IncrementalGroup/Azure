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
#Set current time
$Time = Get-Date -Format HH:00

#get all virtual machines
#$VMs = Get-AzureRmResource -ResourceType 'Microsoft.Compute/virtualMachines' -ExpandProperties
$VMs = Get-AzVM -Status

#Count of VMs
Write-Output "VM Count:" $VMs.Count
foreach($VM in $VMs) 
{
    #if virtual machine has current time tag and shutdown tag is set to yes
    if($VM.Tags.Time -eq $Time)
    {
        if($VM.Tags.Shutdown -eq "Yes")
        {
            Write-Output "Shutting down VM: $($VM.Name), $($VM.PowerState)"
            #Stop-AzVM -Id $VM.Id -AsJob -Force
        }else
        {
            Write-Output  "Resetting Tag for tomorrows schedule on VM: $($VM.Name), $($VM.PowerState)"
            #Set-AzResource -ResourceID $VM.ResourceID -Tag @{Shutdown="Yes"} -Force
        }
    }
    
}



