    #Parameter Definition
    Param
    (
    [Parameter(mandatory = $true)] [String] $DPMServer,
    [String] $SendEmailTo,
    [String] $OutputDirectory,
    [String] $SMTPServer
    )

    $a = "<html><head><style>"
    $a = $a + "BODY{font-family: Calibri;font-size:14;font-color: #000000}"
    $a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"
    $a = $a + "TH{border-width: 1px;padding: 4px;border-style: solid;border-color: black;background-color: #BDBDBD}"
    $a = $a + "TD{border-width: 1px;padding: 4px;border-style: solid;border-color: black;background-color: #ffffff	}"
    $a = $a + "</style></head><body>"

    $b = "</body></html>"

   
    $DataSources = Get-ProtectionGroup -DPMServerName $DPMServer| %{Get-Datasource -ProtectionGroup $_} 

    $Out = @()

    $Heading = "<bR><H1>DPM Resource Utilization</h1><br><br>"

    Foreach($D in $DataSources)
    {

    $RecoveryStr = ($d.diskallocation).split('|')[1]

    $RecoveryAllocated, $RecoveryUsed  = $RecoveryStr -split "allocated,"
    $RecoveryAllocated = [int](($RecoveryAllocated -split ": ")[1] -split " ")[0]
    $RecoveryUsed = [int]((($RecoveryUsed -split " used")[0]) -split " ")[1]
    $RecoveryPointVolUtilization =[int]("{0:N2}" -f (($RecoveryUsed/$RecoveryAllocated)*100))

    $ReplicaSize = "{0:N2}" -f $($d.ReplicaSize/1gb)
    $ReplicaSpaceUsed = "{0:N2}" -f ($d.ReplicaUsedSpace/1gb)
    $ReplicaUtilization =[int]("{0:N2}" -f (($ReplicaSpaceUsed/$ReplicaSize)*100))

    $NumOfRecoveryPoint = ($d | get-recoverypoint).count

    $Out += $d|select ProtectionGroupName, Name, @{name='Replica Size (In GB)';expression={$ReplicaSize}}, @{name='Replica Used Space (In GB)';expression={$ReplicaSpaceUsed}} , @{name='RecoveryPointVolume Allocated (In GB)';expression={$RecoveryAllocated}}, @{name='RecoveryPoint Used Space (In GB)';expression={$RecoveryUsed}},@{name='Total Recovery Points';expression ={$NumOfRecoveryPoint}} , @{name='Replica Utilization %';expression={$ReplicaUtilization}}, @{name='RecoveryPoint Volume Utilization %';expression={$RecoveryPointVolUtilization}}

    }


    disconnect-dpmserver -dpmservername $DPMServer

    $ResourceUtil = $Out | Sort -property name -descending | convertto-html -fragment

    $html = $a + $heading + $ResourceUtil + $b

    If(-not $OutputDirectory)
    {
    $FilePath = "$((Get-Location).path)\DPM_ResourceUtlization_Report.html"
    }
    else
    { 
        If($OutputDirectory[-1] -ne '\')
        {
        
            $FilePath = "$OutputDirectory\DPM_ResourceUtlization_Report.html"
        }
        else
        {
            $FilePath = $OutputDirectory+"DPM_ResourceUtlization_Report.html"
        }
    }

    $html | set-content $FilePath -confirm:$false
    Write-Host "A DPM Resource Utilization Report has been generated on Location : $filePath" -ForegroundColor Yellow
    

    If($SendEmailTo -and $SMTPServer)
    {
    Send-MailMessage -To $SendEmailTo -From "PowershellReporting@egonzehnder.com" -Subject "DPM Space Utilization" -SmtpServer $SMTPServer -Body ($html| Out-String) -BodyAsHtml 
    Write-Host "DPM Resource Utilization Report has been sent to email $SendEmailTo" -ForegroundColor Yellow
    }
