# Certificate Automation Scripts for Azure Stack Deployment
The AzureStackCertAutomation.ps1 file contains several helper scripts that assist in the request, import/export and validation of certificates required for an Azure Stack multi-node deployment. Prior to using these scripts, review the certificate documentation for Azure Stack here: https://docs.microsoft.com/en-us/azure/azure-stack/azure-stack-pki-certs

## Requirements
The script interact with cmdlets in the Azure Readiness Checker module, which require PowerShell version 5 on *Windows 10* or *Windows Server 2016*. In order to install the module by default, PowerShell must be run as an Administrator.

## How the helper scripts improve the certificate request process
The Azure Stack documentation details the requirements for requesting, preparing and validating certificates for use in an Azure Stack deployment. A number of these steps are manual, and because they involve the preparation of many certificates, this process can be time consuming. The helper scripts assist in the following ways:
* __Certificate requests__ - The New-AsCertificateRequest cmdlet executes the cert request cmdlets and creates a .zip file as an option to distribute the requests to a CA admin.
* __Importing certificates__ - The certs you receive back from the CA must be imported into the same workstation that the requests were generated, so the private keys can be associated. The Import-AsCertificates cmdlet automates the import of all certificates into the correct certificate store, so these do not have to be manually imported one at a time.
* __Exporting certificates__ - The Azure Stack deployment process requires that certificates have the private key exported, are stored in .pfx format and all have an identical password. The Export-AsCertificates cmdlet automatically exports the certificates in the correct format, with the correct name, and with the same password.
* __Validating certificates__ - The validation cmdlet requires that some certificates are stored in specific directories and others are referenced in a hash table that requires manual preparation to create directories, organize individual certificates, and prepare PowerShell code ahead of time. The Validate-AsCertificates cmdlet automates this process by creating directories, copying certificates to the appropriate directories, and formulating hash tables on your behalf.

## How to use
To use the the AzureStackCertAutomation.ps1 helper scripts, simply dot source the file in your script.

```powershell
# Dot sources the AzureStackCertAutomation.ps1 file so that the functions can be used
. .\AzureStackCertAutomation.ps1
```
The UsingCertAutomationExample.ps1 script provides an example for using the cmdlets. Change the variables in the top section.
First, execute the New-AsCertificates cmdlet to generate the certificate requests. Once the CA returns the generated certificates,
create a .zip file called __$regionName-certs.zip__ where $regionName is the name of the Azure Stack region. For example, if the
region name is "east", then name the zip file east-certs.zip, and store the zip file in the "east" folder on the Desktop (by default).

Now, the remaining cmdlets can be used. First, run the Import-AsCertificates cmdlet, then the Export-AsCertificates cmdlet, and finally
the Validate-AsCertificates cmdlet. Review the output of the validation script to ensure that all certificates report "OK". Once
all certificates are validated, they can be retrieved from the $regionName\Export folder and delivered to the OEM to start the deployment process.
