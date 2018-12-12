[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateScript( {(Test-Path $_) -eq $true})]
    [string]$FilePath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern("^(https:\/\/)[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$")]
    [string]$BlobUri
)

#Helper Functions
function Get-OsType {
    param (
        $Publisher
    )

    switch -Wildcard ($Publisher) {
        "*Microsoft*" {  "Windows" }
        Default { "Linux" }
    }
}

#Parse text file and assign to variables
$file = Get-Content -Path $FilePath

$publisher = ($file | Where-Object {$_ -like "publisherIdentifier*"}).Split(":").Trim()[1]
$offer = ($file | Where-Object {$_ -like "offer*"}).Split(":").Trim()[1]
$sku = ($file | Where-Object {$_ -like "sku*"}).Split(":").Trim()[1]
$version = ($file | Select-String 'version' -Context 0, 2).Context.PostContext[1]
$azPkgUri = -join ($blobUri, "/", ($file | Where-Object {$_ -like "*azpkg*"}).Split("\")[-1])
$osUri = -join ($blobUri, "/", ($file | Where-Object {$_ -like "*.vhd*"}).Split("\")[-1])
$osType = Get-OsType -Publisher $publisher

#Import the VHD from blob storage and publish the VHD to the Marketplace
$params = @{
    Publisher = $publisher
    Offer     = $offer
    Sku       = $sku
    Version   = $version
    OsType    = $osType
    OsUri     = $osUri
}
Add-AzsPlatformImage @params

#Publish the item to the gallery
Add-AzsGalleryItem -GalleryItemUri $azPkgUri