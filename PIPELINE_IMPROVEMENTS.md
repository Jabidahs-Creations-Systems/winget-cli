# Build Pipeline Error Handling Improvements

## Overview
This document describes the error handling and cleanup improvements made to the Azure Pipelines build configuration and related scripts.

## Objective
Enhance the reliability and debuggability of the build pipeline by:
- Adding comprehensive error checking
- Implementing proper cleanup procedures
- Providing clear error messages for troubleshooting
- Preventing failures from edge cases

## Changes Summary

### 1. Azure Pipelines Configuration (`azure-pipelines.yml`)

#### LocalhostWebServer Process Cleanup
**Problem**: Pipeline would fail if LocalhostWebServer process wasn't running when trying to stop it.

**Solution**: Added error handling to check if process exists before attempting to stop it.

**Locations**: 
- Test job (line ~482)
- BuildPowerShellModule job (line ~587)

**Code**:
```powershell
$process = Get-Process -Name LocalhostWebServer -ErrorAction SilentlyContinue
if ($process) {
  Stop-Process -InputObject $process -Force
  Write-Host "LocalhostWebServer stopped successfully"
} else {
  Write-Host "LocalhostWebServer process not found"
}
```

#### Sysinternals PsTools Installation
**Problem**: Installation could fail silently or cleanup could fail if package wasn't installed.

**Solution**: Added try-catch blocks with proper error handling.

**Location**: Test job (line ~333)

**Improvements**:
- Installation wrapped in try-catch
- Better error messages
- Graceful handling of Repair-WingetPackageManager failures
- Throws error on critical failures

#### Sysinternals PsTools Cleanup
**Location**: Test job (line ~348)

**Improvements**:
- Catches errors if package not installed
- Logs success/failure appropriately

#### Vcpkg Integration
**Problem**: Pipeline would fail if vcpkg.exe was missing or integration failed.

**Solution**: Added validation and error checking.

**Locations**:
- Build job (line ~95)
- Fuzzing job (line ~685)

**Code**:
```batch
if not exist "$(VCPKG_INSTALLATION_ROOT)\vcpkg.exe" (
  echo ERROR: vcpkg.exe not found at $(VCPKG_INSTALLATION_ROOT)
  exit /b 1
)
$(VCPKG_INSTALLATION_ROOT)\vcpkg.exe integrate install
if errorlevel 1 (
  echo ERROR: vcpkg integrate install failed
  exit /b 1
)
```

### 2. E2E Setup Template (`templates/e2e-setup.yml`)

#### Test Code Signing Certificate Creation
**Problem**: Certificate creation could fail silently.

**Solution**: Added comprehensive error handling and validation.

**Improvements**:
- Wrapped in try-catch block
- Added -Force to ConvertTo-SecureString (required for -AsPlainText)
- Validates certificate files were created
- Provides clear error messages

#### HTTPS Certificate Creation
**Problem**: Similar to code signing certificate.

**Solution**: Added validation and error handling.

**Improvements**:
- Validates certificate file exists after creation
- Wrapped in try-catch block
- Clear error messages

### 3. LocalhostWebServer Script (`src/LocalhostWebServer/Run-LocalhostWebServer.ps1`)

#### Certificate Installation
**Problem**: Could fail if certificate file didn't exist or certutil failed.

**Solution**: Added comprehensive validation.

**Improvements**:
- Validates certificate file exists before installation
- Checks certutil exit code
- Provides clear error messages

#### Process Execution
**Problem**: Could fail if executable missing or process failed.

**Solution**: Added validation and error handling.

**Improvements**:
- Validates LocalhostWebServer.exe exists before starting
- Wrapped in try-catch-finally for robust cleanup
- Checks exit code when ExitBeforeRun is specified
- Enhanced logging throughout
- Ensures Pop-Location is always called via finally block

## Benefits

### Improved Reliability
- Pipeline failures are more deterministic
- Edge cases are handled gracefully
- Cleanup operations don't cause cascading failures

### Better Debuggability
- Clear error messages indicate what went wrong
- Success messages confirm operations completed
- Logging helps trace execution flow

### Maintainability
- Code is more defensive against changes
- Error handling follows consistent patterns
- Comments explain non-obvious behavior

## Testing Recommendations

### Smoke Tests
1. Run full build pipeline to ensure no regressions
2. Verify all jobs complete successfully
3. Check logs for new error/success messages

### Error Scenarios
1. Test with LocalhostWebServer not running (cleanup should succeed)
2. Test with missing certificates (should fail with clear message)
3. Test with vcpkg missing (should fail with clear message)

### Edge Cases
1. Multiple consecutive builds (cleanup from previous runs)
2. Build cancellation mid-execution
3. Network/resource unavailability

## Migration Notes

### Breaking Changes
None. All changes are backward compatible.

### Behavior Changes
- Some operations that previously failed silently now provide error messages
- Cleanup operations continue even if processes don't exist
- More verbose logging may increase log file sizes

## Future Improvements

### Potential Enhancements
1. Add retry logic for transient failures
2. Implement timeout handling for long-running operations
3. Add telemetry for error tracking
4. Create cleanup script to run before builds

### Monitoring
Consider adding:
- Build duration metrics
- Failure rate tracking by error type
- Success rate of cleanup operations

## References

### Related Documentation
- [Azure Pipelines YAML schema](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [PowerShell Error Handling Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-exceptions)
- [ConvertTo-SecureString Documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring)

### Version History
- 2026-01-08: Initial improvements implemented
  - Enhanced error handling in Azure Pipelines
  - Improved certificate creation in E2E setup
  - Enhanced LocalhostWebServer script error handling
