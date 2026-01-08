<#
.SYNOPSIS
    Runs the LocalhostWebServer.
.PARAMETER BuildRoot
    The root of the build output directory for LocalhostWebServer
.PARAMETER StaticFileRoot
    The root of the static files to be served through Localhost
.PARAMETER CertPath
    Path to HTTPS Development Certificate File (pfx)
.PARAMETER CertPassword
    Secure Password for HTTPS Certificate
.PARAMETER OutCertFile
    Export cert location.
.PARAMETER LocalSourceJson
    Local source json definition
.PARAMETER SourceCert
    The certificate of the source package.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$BuildRoot,

    [Parameter(Mandatory=$true)]
    [string]$StaticFileRoot,

    [Parameter(Mandatory=$true)]
    [string]$CertPath,

    [Parameter()]
    [string]$CertPassword,

    [Parameter()]
    [string]$OutCertFile,

    [Parameter()]
    [string]$LocalSourceJson,

    [Parameter()]
    [string]$SourceCert,

    [Parameter()]
    [string]$TestDataPath,

    [Parameter()]
    [switch]$ExitBeforeRun
)

if (-not [System.String]::IsNullOrEmpty($sourceCert))
{
    # Requires admin
    Write-Host "Adding certificate to TRUSTEDPEOPLE store: $sourceCert"
    if (-not (Test-Path $sourceCert)) {
        Write-Error "Source certificate not found at: $sourceCert"
        throw "Certificate file not found"
    }
    $result = & certutil.exe -addstore -f "TRUSTEDPEOPLE" $sourceCert
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to add certificate to TRUSTEDPEOPLE store"
        throw "Certificate installation failed with exit code: $LASTEXITCODE"
    }
    Write-Host "Certificate added successfully"
}

$exePath = Join-Path $BuildRoot "LocalhostWebServer.exe"
if (-not (Test-Path $exePath)) {
    Write-Error "LocalhostWebServer.exe not found at: $exePath"
    throw "LocalhostWebServer.exe not found"
}

Push-Location $BuildRoot

$startProcessArguments = @{
    FilePath = $exePath
    ArgumentList = "StaticFileRoot=$StaticFileRoot CertPath=$CertPath CertPassword=$CertPassword OutCertFile=$OutCertFile LocalSourceJson=$LocalSourceJson TestDataPath=$TestDataPath ExitBeforeRun=$ExitBeforeRun"
    PassThru = $true
}

if (-not [System.string]::IsNullOrEmpty($env:artifactsDir))
{
    $startProcessArguments.RedirectStandardOutput = Join-Path $env:artifactsDir "LocalhostWebServer.out"
    $startProcessArguments.RedirectStandardError = Join-Path $env:artifactsDir "LocalhostWebServer.err"
}

try {
    Write-Host "Starting LocalhostWebServer..."
    $Local:process = Start-Process @startProcessArguments
    Write-Host "LocalhostWebServer started with PID: $($Local:process.Id)"
    
    if ($ExitBeforeRun)
    {
        Wait-Process -InputObject $Local:process
        if ($Local:process.ExitCode -ne 0) {
            Write-Error "LocalhostWebServer exited with code: $($Local:process.ExitCode)"
            throw "LocalhostWebServer failed"
        }
        Write-Host "LocalhostWebServer completed successfully"
    }
} catch {
    Write-Error "Failed to start LocalhostWebServer: $_"
    throw
} finally {
    Pop-Location
}
