# Seeds the EasyCheck Online Firestore database with the clinics from the
# Stitch design prototype and today's live queue sessions.
#
# Uses the refresh token already stored by the Firebase CLI. Run from the
# project root:  powershell -ExecutionPolicy Bypass -File tools/seed_firestore.ps1

$ErrorActionPreference = "Stop"

$configPath = Join-Path $env:USERPROFILE ".config\configstore\firebase-tools.json"
if (-not (Test-Path $configPath)) {
  throw "Firebase CLI credentials not found. Run 'firebase login' first."
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json
$refreshToken = $config.tokens.refresh_token
if (-not $refreshToken) {
  throw "Firebase CLI refresh token missing. Run 'firebase login' again."
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body @{
  client_id     = "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com"
  client_secret = "j9iVZfS8kkCEFUPaAeJV0sAi"
  refresh_token = $refreshToken
  grant_type    = "refresh_token"
}
$accessToken = $tokenResponse.access_token
$headers = @{ Authorization = "Bearer $accessToken" }
$baseUri = "https://firestore.googleapis.com/v1/projects/easycheck-online/databases/(default)/documents"

function FS-String([string]$value) { @{ stringValue = $value } }
function FS-Bool([bool]$value) { @{ booleanValue = $value } }
function FS-Int([int]$value) { @{ integerValue = [string]$value } }
function FS-Time([datetime]$value) { @{ timestampValue = $value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") } }

function Write-Document([string]$collection, [string]$documentId, [hashtable]$fields) {
  $uri = "$baseUri/$collection/$documentId"
  $body = @{ fields = $fields } | ConvertTo-Json -Depth 12 -Compress
  Invoke-RestMethod -Method Patch -Uri $uri -Headers $headers -ContentType "application/json" -Body $body | Out-Null
  Write-Host "  wrote $collection/$documentId"
}

$now = Get-Date
$today = $now.ToString("yyyy-MM-dd")
$utcNow = [datetime]::UtcNow

Write-Host "Seeding clinics..."

Write-Document "clinics" "CLN-84920" @{
  name                 = FS-String "Al-Shifa Family Health Clinic"
  address              = FS-String "Suite 402, Medical City Blvd, Near Civic Center"
  city                 = FS-String "Lahore"
  region               = FS-String "Punjab"
  phone                = FS-String ""
  email                = FS-String ""
  description          = FS-String "Family health, cardiology and general physician consultations."
  adminUid             = FS-String ""
  isActive             = FS-Bool $true
  isOnline             = FS-Bool $true
  doctorName           = FS-String "Dr. Rajesh Kumar"
  doctorCredentials    = FS-String "MD"
  doctorSpecialty      = FS-String "Consultant Cardiologist & General Physician"
  doctorPhotoUrl       = FS-String "assets/images/dr_rajesh_kumar.jpg"
  doctorStatus         = FS-String "available"
  doctorTiming         = FS-String "Mon-Sat, 9:00 AM - 5:00 PM"
  todayParchiCount     = FS-Int 42
  yesterdayParchiCount = FS-Int 38
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Document "clinics" "CLN-84921" @{
  name                 = FS-String "Crescent Memorial Hospital"
  address              = FS-String "72 Gulberg Road, Block B, Main Market"
  city                 = FS-String "Lahore"
  region               = FS-String "Punjab"
  phone                = FS-String ""
  email                = FS-String ""
  description          = FS-String "Pediatric and family outpatient care."
  adminUid             = FS-String ""
  isActive             = FS-Bool $true
  isOnline             = FS-Bool $true
  doctorName           = FS-String "Dr. Fatima Zahra"
  doctorCredentials    = FS-String "MBBS, FCPS"
  doctorSpecialty      = FS-String "Pediatric Specialist"
  doctorPhotoUrl       = FS-String "assets/images/dr_fatima_zahra.jpg"
  doctorStatus         = FS-String "available"
  doctorTiming         = FS-String "Mon-Fri, 10:00 AM - 6:00 PM"
  todayParchiCount     = FS-Int 28
  yesterdayParchiCount = FS-Int 31
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Document "clinics" "CLN-84922" @{
  name                 = FS-String "St. Jude Community Medicare"
  address              = FS-String "Plot 18, Commercial Zone, Phase 3"
  city                 = FS-String "Lahore"
  region               = FS-String "Punjab"
  phone                = FS-String ""
  email                = FS-String ""
  description          = FS-String "Orthopedic and community Medicare services."
  adminUid             = FS-String ""
  isActive             = FS-Bool $true
  isOnline             = FS-Bool $false
  doctorName           = FS-String "Dr. Tariq Mahmood"
  doctorCredentials    = FS-String "FRCS"
  doctorSpecialty      = FS-String "Orthopedic Consultant"
  doctorPhotoUrl       = FS-String "assets/images/dr_tariq_mahmood.jpg"
  doctorStatus         = FS-String "offDuty"
  doctorTiming         = FS-String "Mon-Sat, 8:30 AM - 2:00 PM"
  todayParchiCount     = FS-Int 0
  yesterdayParchiCount = FS-Int 22
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Host "Seeding today's queue sessions ($today)..."

Write-Document "queue_sessions" "CLN-84920_$today" @{
  clinicId             = FS-String "CLN-84920"
  date                 = FS-String $today
  currentParchaNumber  = FS-Int 42
  status               = FS-String "active"
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Document "queue_sessions" "CLN-84921_$today" @{
  clinicId             = FS-String "CLN-84921"
  date                 = FS-String $today
  currentParchaNumber  = FS-Int 28
  status               = FS-String "active"
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Document "queue_sessions" "CLN-84922_$today" @{
  clinicId             = FS-String "CLN-84922"
  date                 = FS-String $today
  currentParchaNumber  = FS-Int 0
  status               = FS-String "closed"
  createdAt            = FS-Time $utcNow
  updatedAt            = FS-Time $utcNow
}

Write-Host ""
Write-Host "Done. Clinics and today's queue sessions are seeded."
Write-Host "Clinic admin access is provisioned by the trusted Super Admin backend."
