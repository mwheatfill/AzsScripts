
<#
  This example script demonstrates how to use the AzureStackCertAutomation helper functions.
 #>

# Dot sources the AzureStackCertAutomation.ps1 file so that the functions can be used
. .\AzureStackCertAutomation.ps1

# Install the Azure Stack Readiness Checker module
Install-Module Microsoft.AzureStack.ReadinessChecker

<#
    VARIABLE DECLARATION
    The variables below should be customized for your enivornment
#>
$subjectHash = [ordered]@{"OU" = "AzureStack"; "O" = "Company"; "L" = "Redmond"; "ST" = "Washington"; "C" = "US"}
$identitySystem = "AAD" # "AAD" or "ADFS"
$regionName = 'region' # Region name for the Azure Stack deployment (ie. 'east')
$externalFQDN = 'domain.com' # Domain for the Azure Stack deployment (ie. 'cloud.contoso.com')
$parentFolder = "$ENV:USERPROFILE\Desktop" # Creates a folder with the region name in the $parentFolder
$pfxPassword = Read-Host -Prompt "PFX Password" -AsSecureString # Prompts for a secure string representing the PFX password to be used
$certificateArchive = "$parentFolder\$regionName\$regionName-certs.zip" # Specifies the .zip file containing all the generated certs received from the CA (this needs to be created)
# END VARIABLE DECLARATION - DO NOT CHANGE ANYTHING BELOW THIS LINE


# Runs New-AsCertificateRequest to generate the requests files and create a .zip file to provide to the
# Certificate Authority
$params = @{
    SubjectHash    = $subjectHash
    IdentitySystem = $identitySystem
    Region         = $regionName
    Domain         = $externalFQDN
    ParentFolder   = $parentFolder
}

New-AsCertificateRequest @params

# Runs Import-AsCertificates to import the certificates received from the Certificate Authority
# into the local machine Enterprise Trust store. This matches up the private key from the request
# to the generated certificate
Import-AsCertificates -CertificateArchive $certificateArchive -ParentFolder $parentFolder -Region $regionName

# Runs Export-AsCertificates to export the certificates as PFX files protected by the password provided
Export-AsCertificates -ParentFolder $parentFolder -Region $regionName -PfxPassword $pfxPassword 

# Runs Validate-AsCoreCertificates and Validate-AsPaaSCertificates to verify that the certificates
# meet the requirements for Azure Stack.
$validateAsCoreCertificatesSplat = @{
    Region         = $regionName
    IdentitySystem = $identitySystem
    Domain         = $externalFQDN
    PfxPassword    = $pfxPassword
    ParentFolder   = $parentFolder
}
Validate-AsCoreCertificates @validateAsCoreCertificatesSplat

$validateAsPaaSCertificatesSplat = @{
    Region       = $regionName
    Domain       = $externalFQDN
    PfxPassword  = $true
    ParentFolder = $parentFolder
}
Validate-AsPaaSCertificates @validateAsPaaSCertificatesSplat