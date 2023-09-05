function Get-DeviceUniqueIdentifier {
    $concatStr = ""

    try {
        $wmiClasses = @('Win32_BaseBoard', 'Win32_BIOS', 'Win32_OperatingSystem')
        
        foreach ($class in $wmiClasses) {
            $objects = Get-WmiObject -Class $class
            foreach ($obj in $objects) {
                if ($obj.SerialNumber) {
                    $concatStr += $obj.SerialNumber
                    Write-Host "$class Serial Number: $($obj.SerialNumber)"
                }
            }
        }

        Write-Host "Final Concatenated String: $concatStr"

        $sha1Provider = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider
        $byteArray = [System.Text.Encoding]::UTF8.GetBytes($concatStr)
        $hashedBytes = $sha1Provider.ComputeHash($byteArray)
        $hashString = -join ($hashedBytes | ForEach-Object { $_.ToString("x2") })

        Write-Host "Computed Hash: $hashString"
        return $hashString

    } catch {
        Write-Host $_.Exception.ToString()
        return ""
    }
}

function GenerateEncryptedHwidDate {
    param (
        [DateTime]$date
    )

    $iv = New-Object byte[] 16

    $aes = New-Object System.Security.Cryptography.AesManaged
    $hwid = Get-DeviceUniqueIdentifier
    Write-Host "HWID: $hwid"
    
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($hwid)

    # Resize to 32 bytes
    $resizedKey = New-Object byte[] 32
    [Array]::Copy($keyBytes, $resizedKey, [Math]::Min($keyBytes.Length, $resizedKey.Length))
    
    Write-Host "Date to encrypt: $($date.ToString('yyyy/MM/dd'))"
    Write-Host "AES Key (bytes): $resizedKey"

    $aes.Key = $resizedKey
    $aes.IV = $iv

    $encryptor = $aes.CreateEncryptor($aes.Key, $aes.IV)

    $memoryStream = New-Object System.IO.MemoryStream
    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream -ArgumentList $memoryStream, $encryptor, 'Write'
    $streamWriter = [System.IO.StreamWriter]::new($cryptoStream)

    $streamWriter.Write($date.ToString("yyyy/MM/dd"))
    $streamWriter.Close()

    $encryptedBytes = $memoryStream.ToArray()
    $memoryStream.Close()

    $base64Result = [Convert]::ToBase64String($encryptedBytes)
    Write-Host "Encrypted Base64 Result: $base64Result"
    
    return $base64Result
}

function CreateHwidRegistryKey {
    param (
        [string]$encrypted
    )

    Write-Host "Preparing to save encrypted value: $encrypted"
    $value = [System.Text.Encoding]::UTF8.GetBytes($encrypted + "`0")

    $registryPath = 'HKCU:\Software\Heat\Heat'
    $registryKey = 'HWID'
    Write-Host "Setting registry value at $registryPath under key: $registryKey"

    Set-ItemProperty -Path $registryPath -Name $registryKey -Value $value

    Write-Host "Registry key successfully set."
}


$deviceIdentifier = Get-DeviceUniqueIdentifier
Write-Host "Device identifier: $deviceIdentifier"
$dateTime = [DateTime]::MaxValue
Write-Host "Setting valid till to: $dateTime"
$encrypted = GenerateEncryptedHwidDate -date $dateTime
Write-Host "Encrypted: $encrypted"
CreateHwidRegistryKey -encrypted $encrypted
Write-Host "HWID key created"

