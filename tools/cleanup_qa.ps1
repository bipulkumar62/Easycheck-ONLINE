# Removes the QA claim/membership created during end-to-end verification and
# restores CLN-84920 to its unclaimed seeded state.
$ErrorActionPreference = "Stop"

$configPath = Join-Path $env:USERPROFILE ".config\configstore\firebase-tools.json"
$config = Get-Content $configPath -Raw | ConvertFrom-Json
$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body @{
  client_id     = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
  client_secret = "j9iVZfS8kkCEFUPaAeJV0sAi"
  refresh_token = $config.tokens.refresh_token
  grant_type    = "refresh_token"
}
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }
$baseUri = "https://firestore.googleapis.com/v1/projects/easycheck-online/databases/(default)/documents"
$qaUid = "HhDInNZC8deqVDxXnLWvbiB43LA2"
$clinicId = "CLN-84920"
$sessionId = "${clinicId}_2026-11-03"

function FS-String([string]$value) { @{ stringValue = $value } }
function FS-Bool([bool]$value) { @{ booleanValue = $value } }
function FS-Int([int]$value) { @{ integerValue = [string]$value } }
function FS-Time([datetime]$value) { @{ timestampValue = $value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") } }

Write-Host "Deleting QA membership..."
try {
  Invoke-RestMethod -Method Delete -Uri "$baseUri/clinic_members/${qaUid}_${clinicId}" -Headers $headers | Out-Null
  Write-Host "  deleted clinic_members/${qaUid}_${clinicId}"
} catch {
  Write-Host "  membership not found or already deleted"
}

Write-Host "Restoring clinic $clinicId..."
$clinicBody = @{
  fields = @{
    adminUid       = FS-String ""
    adminClaimCode = FS-String "482913"
    updatedAt      = FS-Time ([datetime]::UtcNow)
  }
} | ConvertTo-Json -Depth 10 -Compress
Invoke-RestMethod -Method Patch -Uri "$baseUri/clinics/$clinicId?updateMask.fieldPaths=adminUid&updateMask.fieldPaths=adminClaimCode&updateMask.fieldPaths=updatedAt" -Headers $headers -ContentType "application/json" -Body $clinicBody | Out-Null
Write-Host "  restored adminUid='' and claim code"

Write-Host "Restoring today's queue session..."
$sessionBody = @{
  fields = @{
    clinicId            = FS-String $clinicId
    date                = FS-String "2026-11-03"
    currentParchaNumber = FS-Int 42
    status              = FS-String "active"
    updatedAt           = FS-Time ([datetime]::UtcNow)
  }
} | ConvertTo-Json -Depth 10 -Compress
Invoke-RestMethod -Method Patch -Uri "$baseUri/queue_sessions/$sessionId?updateMask.fieldPaths=clinicId&updateMask.fieldPaths=date&updateMask.fieldPaths=currentParchaNumber&updateMask.fieldPaths=status&updateMask.fieldPaths=updatedAt" -Headers $headers -ContentType "application/json" -Body $sessionBody | Out-Null
Write-Host "  reset live counter to 42"

Write-Host "Removing QA queue history..."
$history = Invoke-RestMethod -Method Get -Uri "$baseUri/queue_history" -Headers $headers
$deleted = 0
foreach ($doc in $history.documents) {
  if ($doc.fields.performedBy.stringValue -eq $qaUid) {
    Invoke-RestMethod -Method Delete -Uri "https://firestore.googleapis.com/v1/$($doc.name)" -Headers $headers | Out-Null
    $deleted++
  }
}
Write-Host "  deleted $deleted history entries"

Write-Host "Deleting QA auth account..."
try {
  Invoke-RestMethod -Method Post -Uri "https://identitytoolkit.googleapis.com/v1/projects/easycheck-online/accounts:delete" -Headers $headers -ContentType "application/json" -Body (@{ localId = $qaUid } | ConvertTo-Json) | Out-Null
  Write-Host "  deleted auth user $qaUid"
} catch {
  Write-Host "  auth user already deleted or deletion failed: $($_.Exception.Message)"
}

Write-Host "Cleanup complete."
