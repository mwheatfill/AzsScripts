function New-AsCertificateRequest {
    param (
        $SubjectHash, $IdentitySystem, $Region, $Domain, $ParentFolder
    )
    
    Import-Module Microsoft.AzureStack.ReadinessChecker
    $outputDirectory = "$ParentFolder\$Region\CSR"
    if (!(Test-Path $outputDirectory)) {New-Item -Path $outputDirectory -ItemType Directory -Force}

    $params = @{
        RegionName        = $Region
        FQDN              = $Domain
        Subject           = $SubjectHash
        OutputRequestPath = $outputDirectory
        IdentitySystem    = $IdentitySystem
        IncludePaaS       = $true
    }
    New-AzsCertificateSigningRequest @params
    Compress-Archive $outputDirectory -DestinationPath "$outputDirectory\$Region-csr.zip"

}

function Import-AsCertificates {
    param (
        $CertificateArchive, $ParentFolder, $Region
    )
    
    $outputDirectory = "$ParentFolder\$Region\Import"
    $certStoreLocation = "Cert:\LocalMachine\Trust"
    
    #Clear out Trust location
    Get-ChildItem $certStoreLocation | Remove-Item

    #Unzip cert archive
    if (!(Test-Path $outputDirectory)) {New-Item -Path $outputDirectory -ItemType Directory -Force}
    Expand-Archive -Path $CertificateArchive -DestinationPath $outputDirectory -Force

    foreach ($cert in (Get-ChildItem $outputDirectory)) {Import-Certificate $cert.VersionInfo.FileName -CertStoreLocation $certStoreLocation}
}

function Export-AsCertificates {
    param (
        $ParentFolder, $Region, [SecureString]$PfxPassword
    )

    $outputDirectory = "$ParentFolder\$Region\Export"
    $certStoreLocation = "Cert:\LocalMachine\Trust"

    if (!(Test-Path $outputDirectory)) {New-Item -Path $outputDirectory -ItemType Directory -Force}
    foreach ($cert in (Get-ChildItem $certStoreLocation)) {
        if ($null -ne $cert.PrivateKey) {
            #Create file names for export
            $pfxFilePath = "{0}.pfx" -f $cert.Subject.Split(",").Replace("CN=", "").Replace("*", "wildcard").Replace(".", "_")
            Export-PfxCertificate -Cert $cert -FilePath $outputDirectory\$pfxFilePath -Password $PfxPassword
        }
    } 
}

function Validate-AsCoreCertificates {
    param (
        $ParentFolder, $Region, $Domain, $IdentitySystem, [SecureString]$PfxPassword
    )

    Import-Module Microsoft.AzureStack.ReadinessChecker -Force

    $sourceDirectory = "$ParentFolder\$Region\Export"
    $outputDirectory = "$ParentFolder\$Region\Validation"
    if (!(Test-Path $outputDirectory)) {New-Item -Path $outputDirectory -ItemType Directory -Force}

    #Create directory structure required by ReadinessChecker module
    $directories = 'ACSBlob', 'ACSQueue', 'ACSTable', 'Admin Portal', 
    'ARM Admin', 'ARM Public', 'KeyVault', 'KeyVaultInternal', 'Public Portal'
    
    $directories | ForEach-Object { 
        New-Item -Path (Join-Path $outputDirectory $PSITEM) -ItemType Directory -Force}
    
    #Copy certs from Export to the directories created above
    $certs = Get-ChildItem -Path $sourceDirectory

    $certs | Where-Object {$_.Name -like "wildcard_blob_*"} | Copy-Item -Destination $outputDirectory\ACSBlob
    $certs | Where-Object {$_.Name -like "wildcard_queue_*"} | Copy-Item -Destination $outputDirectory\ACSQueue
    $certs | Where-Object {$_.Name -like "wildcard_table_*"} | Copy-Item -Destination $outputDirectory\ACSTable
    $certs | Where-Object {$_.Name -like "adminportal_*"} | Copy-Item -Destination "$outputDirectory\Admin Portal"
    $certs | Where-Object {$_.Name -like "adminmanagement_*"} | Copy-Item -Destination "$outputDirectory\ARM Admin"
    $certs | Where-Object {$_.Name -like "management_*"} | Copy-Item -Destination "$outputDirectory\ARM Public"
    $certs | Where-Object {$_.Name -like "wildcard_vault_*"} | Copy-Item -Destination "$outputDirectory\KeyVault"
    $certs | Where-Object {$_.Name -like "wildcard_adminvault_*"} | Copy-Item -Destination "$outputDirectory\KeyVaultInternal"
    $certs | Where-Object {$_.Name -like "portal_*"} | Copy-Item -Destination "$outputDirectory\Public Portal"
    
    #Start the readiness checker cmdlet
    $startAzsReadinessCheckerSplat = @{
        FQDN            = $Domain
        CertificatePath = $outputDirectory
        pfxPassword     = $PfxPassword
        IdentitySystem  = $IdentitySystem
        RegionName      = $Region
    }
    Start-AzsReadinessChecker @startAzsReadinessCheckerSplat
}

function Validate-AsPaaSCertificates {
    param (
        $ParentFolder, $Region, $Domain, [SecureString]$PfxPassword
    )

    Import-Module Microsoft.AzureStack.ReadinessChecker
    $directory = "$ParentFolder\$Region\Export"
    $dnsFileName = -join ("_", $Region, "_", $Domain.Replace(".", "_"), ".pfx")

    $PaaSCertificates = @{
        'PaaSDBCert'      = @{'pfxPath' = "$directory\wildcard_dbadapter$dnsFileName"; 'pfxPassword' = $PfxPassword}
        'PaaSDefaultCert' = @{'pfxPath' = "$directory\wildcard_sso_appservice$dnsFileName"; 'pfxPassword' = $PfxPassword}
        'PaaSAPICert'     = @{'pfxPath' = "$directory\api_appservice$dnsFileName"; 'pfxPassword' = $PfxPassword}
        'PaaSFTPCert'     = @{'pfxPath' = "$directory\ftp_appservice$dnsFileName"; 'pfxPassword' = $PfxPassword}
        'PaaSSSOCert'     = @{'pfxPath' = "$directory\sso_appservice$dnsFileName"; 'pfxPassword' = $PfxPassword}
    }

    Start-AzsReadinessChecker -PaaSCertificates $PaaSCertificates -RegionName $Region -FQDN $Domain  
}