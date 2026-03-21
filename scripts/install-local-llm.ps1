# BENCHMARK.me Local LLM Installation Script (Docker-based)
# Installs Ollama via Docker with NVIDIA GPU support and Nemotron Super 8B Q4_K_M model
# Also helps set up the BENCHMARK.me vault structure for health data

Write-Host "BENCHMARK.me Local LLM Installation Script (Docker-based)" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""

# Check if running as administrator (needed for some Docker operations)
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script may require administrator privileges for Docker operations."
    Write-Host "Consider running this script as administrator if you encounter permission issues." -ForegroundColor Yellow
}

# Function to check if Docker is installed
function Check-DockerInstalled {
    return Get-Command docker -ErrorAction SilentlyContinue
}

# Check Docker installation
if (-not (Check-DockerInstalled)) {
    Write-Error "Docker is not installed or not in PATH."
    Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    Write-Host "Make sure to enable WSL2 backend during installation." -ForegroundColor Yellow
    exit 1
}

# Check Docker version and status
Write-Host "Checking Docker installation..." -ForegroundColor Cyan
try {
    docker version
    Write-Host "Docker is installed and accessible." -ForegroundColor Green
}
catch {
    Write-Error "Docker is installed but not responding. Please ensure Docker Desktop is running."
    exit 1
}

# Check if NVIDIA Container Toolkit is available (for GPU support)
Write-Host "Checking for NVIDIA GPU support..." -ForegroundColor Cyan
$nvidiaSupport = $false
try {
    $dockerInfo = docker info
    if ($dockerInfo -match "nvidia") {
        $nvidiaSupport = $true
        Write-Host "NVIDIA Container Toolkit detected - GPU support available!" -ForegroundColor Green
    }
    else {
        Write-Warning "NVIDIA Container Toolkit not detected in Docker info."
        Write-Host "For GPU acceleration with your RTX 5070, you need to install NVIDIA Container Toolkit:" -ForegroundColor Yellow
        Write-Host "1. With Docker Desktop running, open WSL2 terminal (Ubuntu)" -ForegroundColor Yellow
        Write-Host "2. Run: curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -" -ForegroundColor Yellow
        Write-Host "3. Run: distribution=$(. /etc/os-release;echo $ID$VERSION_ID)" -ForegroundColor Yellow
        Write-Host "4. Run: curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list" -ForegroundColor Yellow
        Write-Host "5. Run: sudo apt-get update && sudo apt-get install -y nvidia-docker2" -ForegroundColor Yellow
        Write-Host "6. Run: sudo systemctl restart docker" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Continuing without GPU support (will use CPU only)..." -ForegroundColor Yellow
    }
}
catch {
    Write-Warning "Could not check Docker info for NVIDIA support."
    Write-Host "Continuing without guaranteed GPU support..." -ForegroundColor Yellow
}

# Ask user for vault location
Write-Host "" -ForegroundColor Green
Write-Host "BENCHMARK.me Vault Setup" -ForegroundColor Yellow
Write-Host "=======================" -ForegroundColor Yellow
$vaultPath = Read-Host "Enter the path where you want to create your BENCHMARK.me vault (e.g., C:\Users\YourName\vaults\health or ./my-health-vault)"
if (-not $vaultPath) {
    $vaultPath = "./vault"
    Write-Host "Using default path: $vaultPath" -ForegroundColor Yellow
}

# Resolve the path
try {
    $resolvedPath = Resolve-Path -Path $vaultPath -ErrorAction Stop
    $vaultPath = $resolvedPath.Path
}
catch {
    # If path doesn't exist, we'll create it
    $vaultPath = $vaultPath.TrimEnd('\')
}

Write-Host "Vault will be created at: $vaultPath" -ForegroundColor Green

# Create vault directory structure
Write-Host "" -ForegroundColor Green
Write-Host "Creating BENCHMARK.me vault structure..." -ForegroundColor Yellow

$directories = @(
    "base-stats",
    "conditions", 
    "facts",
    "llm-clusters",
    "templates",
    "inbox"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $vaultPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "Created: $fullPath" -ForegroundColor Cyan
    }
    else {
        Write-Host "Already exists: $fullPath" -ForegroundColor Yellow
    }
}

# Copy template files to vault/templates if they don't exist
Write-Host "" -ForegroundColor Green
Write-Host "Setting up template files..." -ForegroundColor Yellow
$templateSource = Join-Path $PSScriptRoot "..\templates"
$templateDest = Join-Path $vaultPath "templates"

if (Test-Path $templateSource) {
    # Copy all .md files from source templates to vault templates
    Get-ChildItem -Path $templateSource -Filter "*.md" | ForEach-Object {
        $destFile = Join-Path $templateDest $_.Name
        if (-not (Test-Path $destFile)) {
            Copy-Item -Path $_.FullName -Destination $destFile -Force
            Write-Host "Copied template: $_.Name" -ForegroundColor Cyan
        }
        else {
            Write-Host "Template already exists: $_.Name" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Warning "Source templates not found at $templateSource"
}

# Create example files in each directory
Write-Host "" -ForegroundColor Green
Write-Host "Creating example files..." -ForegroundColor Yellow

# Example measurement
$weightFile = Join-Path $vaultPath "base-stats\weight.md"
if (-not (Test-Path $weightFile)) {
    $weightContent = @"
---
type: measurement
stat: weight
value: 75.5
unit: kg
source: manual
date: 2026-03-20
version: 1
confidence: high
tags: [body-comp, routine]
---
# Weight Measurement

Recorded weight during morning routine. Felt hydrated and well-rested.
"@
    Set-Content -Path $weightFile -Value $weightContent -Encoding UTF8
    Write-Host "Created example: base-stats/weight.md" -ForegroundColor Cyan
}

# Example condition
$adhdFile = Join-Path $vaultPath "conditions\adhd.md"
if (-not (Test-Path $adhdFile)) {
    $adhdContent = @"
---
type: condition
name: ADHD
subtype: predominantly inattentive presentation
icd10: F90.0
diag_date: 2020-06-15
diagnosed_by: Dr. Smith, Neurologist
status: active
severity: moderate
treatment: Behavioral therapy, lifestyle modifications
source: medical-record
version: 1
tags: [neurodevelopmental, focus, attention]
---
# Attention Deficit Hyperactivity Disorder (ADHD)

Diagnosed in adulthood after years of struggling with focus and organization. Primarily inattentive type with some hyperactive-impulsive traits. Managed through behavioral strategies and environmental accommodations.
"@
    Set-Content -Path $adhdFile -Value $adhdContent -Encoding UTF8
    Write-Host "Created example: conditions/adhd.md" -ForegroundColor Cyan
}

# Example fact
$caffeineFile = Join-Path $vaultPath "facts\caffeine-after-2pm-bad.md"
if (-not (Test-Path $caffeineFile)) {
    $caffeineContent = @"
---
type: fact
claim: Consuming caffeine after 2 PM negatively impacts my sleep quality and increases sleep latency.
confidence: medium
basis: personal-observation
date: 2026-03-15
version: 1
validated: false
tags: [sleep, caffeine, lifestyle]
---
# Caffeine After 2 PM Effect

I've noticed that when I consume caffeine (coffee, tea, or soda) after 2 PM, I tend to:
- Take longer to fall asleep (increased sleep latency)
- Experience more restless sleep
- Feel less rested the next morning

This observation is based on tracking my sleep times and subjective restfulness over several weeks.
"@
    Set-Content -Path $caffeineFile -Value $caffeineContent -Encoding UTF8
    Write-Host "Created example: facts/caffeine-after-2pm-bad.md" -ForegroundColor Cyan
}

# Example LLM cluster
$clusterFile = Join-Path $vaultPath "llm-clusters\sleep-caffeine-correlation.md"
if (-not (Test-Path $clusterFile)) {
    $clusterContent = @"
---
type: cluster
title: Sleep and Caffeine Consumption Correlation
generated: 2026-03-21
model: nemotron-super-8b-q4
linked_notes: [[vault/facts/caffeine-after-2pm-bad.md], [vault/base-stats/weight.md]]
confidence: medium
status: hypothesis
tags: [sleep, caffeine, correlation]
---
# Sleep and Caffeine Consumption Correlation

## Evidence Chain:
1. [[vault/facts/caffeine-after-2pm-bad.md]] (2026-03-15) — Personal observation that caffeine after 2 PM affects sleep
2. [[vault/base-stats/weight.md]] (2026-03-20) — Weight measurement showing routine tracking

## Interpretation:
There appears to be a correlation between caffeine consumption timing and sleep quality based on personal observations. The user notes that avoiding caffeine after 2 PM may improve sleep latency and restfulness.

## Confidence: medium
## Status: hypothesis
"@
    Set-Content -Path $clusterFile -Value $clusterContent -Encoding UTF8
    Write-Host "Created example: llm-clusters/sleep-caffeine-correlation.md" -ForegroundColor Cyan
}

# Create sample input
$inboxFile = Join-Path $vaultPath "inbox\sample-input.txt"
if (-not (Test-Path $inboxFile)) {
    $inboxContent = @"
March 20, 2026
- Weight: 75.5 kg (morning measurement)
- Resting HR: 62 bpm (from Apple Health)
- Had coffee at 3 PM today, noticed trouble falling asleep
- Exercise: 30-minute walk in the evening
- Mood: felt good after walk, slightly anxious about work deadline
"@
    Set-Content -Path $inboxFile -Value $inboxContent -Encoding UTF8
    Write-Host "Created sample input: inbox/sample-input.txt" -ForegroundColor Cyan
}

# Pull Ollama Docker image
Write-Host "" -ForegroundColor Green
Write-Host "Pulling Ollama Docker image..." -ForegroundColor Yellow

try {
    docker pull ollama/ollama
    Write-Host "Ollama Docker image pulled successfully." -ForegroundColor Green
}
catch {
    Write-Error "Failed to pull Ollama Docker image: $_"
    exit 1
}

# Create Ollama volume for persistent storage
Write-Host "Creating Ollama volume for persistent storage..." -ForegroundColor Cyan
try {
    docker volume create ollama
    Write-Host "Ollama volume created." -ForegroundColor Green
}
catch {
    if ($_ -match "already exists") {
        Write-Host "Ollama volume already exists." -ForegroundColor Green
    }
    else {
        Write-Error "Failed to create Ollama volume: $_"
        exit 1
    }
}

# Stop and remove existing Ollama container if present
Write-Host "Checking for existing Ollama container..." -ForegroundColor Cyan
try {
    docker stop ollama > $null 2>&1
    docker rm ollama > $null 2>&1
    Write-Host "Cleaned up existing Ollama container." -ForegroundColor Green
}
catch {
    # Ignore errors if container doesn't exist
}

# Run Ollama container with GPU support if available
Write-Host "" -ForegroundColor Green
Write-Host "Starting Ollama container..." -ForegroundColor Yellow

$runArgs = "-d --name ollama -p 11434:11434 -v ollama:/root/.ollama --restart unless-stopped"

if ($nvidiaSupport) {
    $runArgs += " --gpus all"
    Write-Host "Starting with GPU support (RTX 5070)..." -ForegroundColor Cyan
}
else {
    Write-Host "Starting without GPU support (CPU only)..." -ForegroundColor Yellow
}

try {
    docker run $runArgs ollama/ollama
    Write-Host "Ollama container started successfully." -ForegroundColor Green
    
    # Give container time to start
    Write-Host "Waiting for Ollama service to start..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
}
catch {
    Write-Error "Failed to start Ollama container: $_"
    exit 1
}

# Verify Ollama is running in container
Write-Host "Verifying Ollama service in container..." -ForegroundColor Cyan
try {
    # Try to connect to Ollama API
    $maxAttempts = 15
    $attempt = 0
    $ollamaReady = $false
    
    while ($attempt -lt $maxAttempts -and -not $ollamaReady) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 5
            $ollamaReady = $true
            Write-Host "Ollama service is ready!" -ForegroundColor Green
        }
        catch {
            $attempt++
            if ($attempt -lt $maxAttempts) {
                Write-Host "Waiting for Ollama to start... (attempt $attempt/$maxAttempts)" -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
        }
    }
    
    if (-not $ollamaReady) {
        Write-Warning "Could not verify Ollama API is responding. The container might still be starting."
        Write-Host "You can check manually with: docker logs -f ollama" -ForegroundColor Yellow
    }
}
catch {
    Write-Warning "Could not verify Ollama API."
}

# Pull the Nemotron Super 8B Q4_K_M model
Write-Host "" -ForegroundColor Green
Write-Host "Pulling Nemotron Super 8B Q4_K_M model (this is the model specified in your system prompt)..." -ForegroundColor Yellow
Write-Host "This may take a while depending on your internet connection (model size ~4.9GB)..." -ForegroundColor Yellow

try {
    # Using the exact model name format from the specification
    docker exec ollama ollama pull nemotron-super:8b-q4_K_M
    
    Write-Host "Model nemotron-super:8b-q4_K_M pulled successfully!" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to pull nemotron-super:8b-q4_K_M with exact name. Trying alternative formats..."
    
    # Try alternative naming conventions that might exist in Ollama library
    $modelNames = @(
        "nemotron-super:8b",
        "nemotron-super:latest",
        "nemotron:8b",
        "nemotron-super-8b",
        "hf.co/nemotron-super-8b-v2:q4_k_m"
    )
    
    $success = $false
    foreach ($modelName in $modelNames) {
        try {
            Write-Host "Trying to pull $modelName..." -ForegroundColor Cyan
            docker exec ollama ollama pull $modelName
            Write-Host "Successfully pulled $modelName!" -ForegroundColor Green
            $success = $true
            break
        }
        catch {
            Write-Warning "Failed to pull $modelName"
        }
    }
    
    if (-not $success) {
        Write-Warning "Could not pull Nemotron Super model automatically."
        Write-Host "" -ForegroundColor Yellow
        Write-Host "Please pull the model manually once the container is running:" -ForegroundColor Yellow
        Write-Host "docker exec ollama ollama pull nemotron-super:8b-q4_K_M" -ForegroundColor Yellow
        Write-Host "Or check available models with: docker exec ollama ollama list" -ForegroundColor Yellow
    }
}

# Verify the model is available
Write-Host "" -ForegroundColor Green
Write-Host "Verifying model installation..." -ForegroundColor Cyan
try {
    $models = docker exec ollama ollama list
    Write-Host "Available models in container:" -ForegroundColor Cyan
    Write-Host $models
    
    if ($models -match "nemotron") {
        Write-Host "Nemotron Super model is ready for use!" -ForegroundColor Green
    }
    else {
        Write-Warning "Model may not be properly installed. Please check with 'docker exec ollama ollama list'"
        Write-Host "You can try pulling it manually: docker exec ollama ollama pull nemotron-super:8b-q4_K_M" -ForegroundColor Yellow
    }
}
catch {
    Write-Warning "Could not verify model list."
}

Write-Host "" -ForegroundColor Green
Write-Host "🎉 Installation complete! 🎉" -ForegroundColor Green
Write-Host "" -ForegroundColor Green
Write-Host "BENCHMARK.me vault created at: $vaultPath" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "To use the BENCHMARK.me health knowledge agent:" -ForegroundColor Yellow
Write-Host "1. Make sure the Ollama container is running:" -ForegroundColor Yellow
Write-Host "   docker start ollama (if stopped)" -ForegroundColor Yellow
Write-Host "2. The agent will connect to the local model via API at http://localhost:11434" -ForegroundColor Yellow
Write-Host "3. Start processing your health data in the Obsidian vault at: $vaultPath" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "Vault structure:" -ForegroundColor Yellow
Write-Host "  $vaultPath\" -ForegroundColor Yellow
Write-Host "  ├─ base-stats/       # Measurements (weight.md, hrv.md, etc.)" -ForegroundColor Yellow
Write-Host "  ├─ conditions/       # Diagnoses (adhd.md, asthma.md, etc.)" -ForegroundColor Yellow
Write-Host "  ├─ facts/            # Personal observations (caffeine-after-2pm-bad.md, etc.)" -ForegroundColor Yellow
Write-Host "  ├─ llm-clusters/     # LLM-generated correlations" -ForegroundColor Yellow
Write-Host "  ├─ templates/        # Frontmatter templates" -ForegroundColor Yellow
Write-Host "  └─ inbox/            # Raw unprocessed input" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "Management commands:" -ForegroundColor Yellow
Write-Host "  View logs: docker logs -f ollama" -ForegroundColor Yellow
Write-Host "  Stop container: docker stop ollama" -ForegroundColor Yellow
Write-Host "  Start container: docker start ollama" -ForegroundColor Yellow
Write-Host "  Remove container: docker stop ollama && docker rm ollama" -ForegroundColor Yellow
Write-Host "  Pull different model: docker exec ollama ollama pull <model-name>" -ForegroundColor Yellow
Write-Host "" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open your vault in Obsidian: $vaultPath" -ForegroundColor Yellow
Write-Host "2. Install the BENCHMARK.me Obsidian plugin (if available)" -ForegroundColor Yellow
Write-Host "3. Or use the CLI tools to process your inbox/" -ForegroundColor Yellow
Write-Host "4. Begin adding your health data!" -ForegroundColor Yellow