# Oracle Database Deployment Script

$deployDate = Get-Date -Format "yyyyMMdd"
$baseDir = "D:\Apps\AI project\Deployment\oracle-deployment-$deployDate"
$configDir = "$baseDir\config"
$scriptsDir = "$baseDir\scripts"
$logDir = "$baseDir\logs"
$rollbackDir = "$baseDir\rollback"

# Create folder structure
$folders = @($baseDir, $configDir, $scriptsDir, "$scriptsDir\01_tables", "$scriptsDir\02_indexes", "$scriptsDir\03_sequences", "$scriptsDir\04_views", "$scriptsDir\05_types", "$scriptsDir\06_packages", "$scriptsDir\07_package_bodies", "$scriptsDir\08_triggers", "$scriptsDir\09_synonyms", $logDir, $rollbackDir)
foreach ($folder in $folders) { if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null } }

# Copy config file
Copy-Item "D:\Apps\AI project\Deployment\db_config.env" "$configDir\db_config_dev.env" -Force

# Copy SQL scripts to appropriate folders (customize as needed)
Copy-Item "D:\Apps\AI project\warehouse_order_management.sql" "$scriptsDir\01_tables\" -Force
Copy-Item "D:\Apps\AI project\warehouse_order_management_with_orderid_limit.sql" "$scriptsDir\01_tables\" -Force

# Load environment variables
Get-Content "$configDir\db_config_dev.env" | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$") {
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2])
    }
}
$user = $env:ORACLE_USER
$password = $env:ORACLE_PASSWORD
$tns = $env:ORACLE_TNS

# Prepare log file
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = "$logDir\deploy_$timestamp.log"

# Deploy scripts in order
$scriptFolders = @("01_tables", "02_indexes", "03_sequences", "04_views", "05_types", "06_packages", "07_package_bodies", "08_triggers", "09_synonyms")
foreach ($folder in $scriptFolders) {
    $folderPath = "$scriptsDir\$folder"
    if (Test-Path $folderPath) {
        $sqlFiles = Get-ChildItem -Path $folderPath -Filter *.sql | Sort-Object Name
        foreach ($sqlFile in $sqlFiles) {
            Write-Host "Deploying $($sqlFile.Name)..."
            $sqlplusCmd = "sqlplus -L $user/$password@$tns @$($sqlFile.FullName)"
            Write-Host "Running: $sqlplusCmd"
            Invoke-Expression "$sqlplusCmd | Tee-Object -FilePath $logFile"
        }
    }
}

Write-Host "Deployment completed. Check $logFile for details." 