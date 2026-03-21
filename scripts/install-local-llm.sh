#!/bin/bash
# BENCHMARK.me Local LLM Installation Script (Unix/Linux/macOS - Docker-based)
# Installs Ollama via Docker with NVIDIA GPU support and Nemotron Super 8B Q4_K_M model
# Also helps set up the BENCHMARK.me vault structure for health data

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}BENCHMARK.me Local LLM Installation Script (Docker-based - Unix)${NC}"
echo -e "${GREEN}=========================================================${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH.${NC}"
    echo "Please install Docker Desktop from https://www.docker.com/products/docker-desktop"
    echo "On Linux, you can also install docker-engine and add your user to the docker group."
    exit 1
fi

# Check Docker version and status
echo -e "${YELLOW}Checking Docker installation...${NC}"
if ! docker version &> /dev/null; then
    echo -e "${RED}Error: Docker is installed but not responding. Please ensure Docker Desktop is running.${NC}"
    exit 1
fi
echo -e "${GREEN}Docker is installed and accessible.${NC}"

# Check if NVIDIA Container Toolkit is available (for GPU support)
echo -e "${YELLOW}Checking for NVIDIA GPU support...${NC}"
NVIDIA_SUPPORT=false
if docker info 2>/dev/null | grep -i nvidia &> /dev/null; then
    NVIDIA_SUPPORT=true
    echo -e "${GREEN}NVIDIA Container Toolkit detected - GPU support available!${NC}"
else
    echo -e "${YELLOW}Warning: NVIDIA Container Toolkit not detected in Docker info.${NC}"
    echo "For GPU acceleration with your RTX 5070, you need to install NVIDIA Container Toolkit:"
    echo "On Ubuntu/Debian:"
    echo "  curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -"
    echo "  distribution=\$(. /etc/os-release;echo \$ID\$VERSION_ID)"
    echo "  curl -s -L https://nvidia.github.io/nvidia-docker/\$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y nvidia-docker2"
    echo "  sudo systemctl restart docker"
    echo ""
    echo -e "${YELLOW}Continuing without GPU support (will use CPU only)...${NC}"
fi

# Ask user for vault location
echo -e "${GREEN}BENCHMARK.me Vault Setup${NC}"
echo -e "${YELLOW}=======================${NC}"
read -p "Enter the path where you want to create your BENCHMARK.me vault (e.g., /home/yourname/vaults/health or ./my-health-vault): " vaultPath
if [ -z "$vaultPath" ]; then
    vaultPath="./vault"
    echo -e "Using default path: ${vaultPath}"
fi

# Resolve the path (expand ~ and relative paths)
vaultPath=$(realpath -m "$vaultPath" 2>/dev/null || echo "$vaultPath")

echo -e "Vault will be created at: ${vaultPath}"

# Create vault directory structure
echo -e "${GREEN}Creating BENCHMARK.me vault structure...${NC}"

directories=(
    "base-stats"
    "conditions" 
    "facts"
    "llm-clusters"
    "templates"
    "inbox"
)

for dir in "${directories[@]}"; do
    fullPath="${vaultPath}/${dir}"
    if [ ! -d "$fullPath" ]; then
        mkdir -p "$fullPath"
        echo -e "Created: $fullPath"
    else
        echo -e "Already exists: $fullPath"
    fi
done

# Copy template files to vault/templates if they don't exist
echo -e "${GREEN}Setting up template files...${NC}"
templateSource="$(dirname "$(realpath "$0")")/../templates"
templateDest="${vaultPath}/templates"

if [ -d "$templateSource" ]; then
    # Copy all .md files from source templates to vault templates
    for srcFile in "$templateSource"/*.md; do
        if [ -f "$srcFile" ]; then
            fileName=$(basename "$srcFile")
            destFile="${templateDest}/${fileName}"
            if [ ! -f "$destFile" ]; then
                cp "$srcFile" "$destFile"
                echo -e "Copied template: $fileName"
            else
                echo -e "Template already exists: $fileName"
            fi
        fi
    done
else
    echo -e "${YELLOW}Warning: Source templates not found at $templateSource${NC}"
fi

# Create example files in each directory
echo -e "${GREEN}Creating example files...${NC}"

# Example measurement
weightFile="${vaultPath}/base-stats/weight.md"
if [ ! -f "$weightFile" ]; then
    weightContent="---
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
"
    echo "$weightContent" > "$weightFile"
    echo -e "Created example: base-stats/weight.md"
fi

# Example condition
adhdFile="${vaultPath}/conditions/adhd.md"
if [ ! -f "$adhdFile" ]; then
    adhdContent="---
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
"
    echo "$adhdContent" > "$adhdFile"
    echo -e "Created example: conditions/adhd.md"
fi

# Example fact
caffeineFile="${vaultPath}/facts/caffeine-after-2pm-bad.md"
if [ ! -f "$caffeineFile" ]; then
    caffeineContent="---
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
"
    echo "$caffeineContent" > "$caffeineFile"
    echo -e "Created example: facts/caffeine-after-2pm-bad.md"
fi

# Example LLM cluster
clusterFile="${vaultPath}/llm-clusters/sleep-caffeine-correlation.md"
if [ ! -f "$clusterFile" ]; then
    clusterContent="---
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
"
    echo "$clusterContent" > "$clusterFile"
    echo -e "Created example: llm-clusters/sleep-caffeine-correlation.md"
fi

# Create sample input
inboxFile="${vaultPath}/inbox/sample-input.txt"
if [ ! -f "$inboxFile" ]; then
    inboxContent="March 20, 2026
- Weight: 75.5 kg (morning measurement)
- Resting HR: 62 bpm (from Apple Health)
- Had coffee at 3 PM today, noticed trouble falling asleep
- Exercise: 30-minute walk in the evening
- Mood: felt good after walk, slightly anxious about work deadline
"
    echo "$inboxContent" > "$inboxFile"
    echo -e "Created sample input: inbox/sample-input.txt"
fi

# Pull Ollama Docker image
echo -e "${GREEN}Pulling Ollama Docker image...${NC}"
if ! docker pull ollama/ollama; then
    echo -e "${RED}Error: Failed to pull Ollama Docker image.${NC}"
    exit 1
fi
echo -e "${GREEN}Ollama Docker image pulled successfully.${NC}"

# Create Ollama volume for persistent storage
echo -e "${YELLOW}Creating Ollama volume for persistent storage...${NC}"
if ! docker volume create ollama 2>/dev/null; then
    if docker volume inspect ollama &> /dev/null; then
        echo -e "${GREEN}Ollama volume already exists.${NC}"
    else
        echo -e "${RED}Error: Failed to create Ollama volume.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Ollama volume created.${NC}"
fi

# Stop and remove existing Ollama container if present
echo -e "${YELLOW}Checking for existing Ollama container...${NC}"
if docker ps -a --format '{{.Names}}' | grep -q "^ollama$"; then
    echo "Stopping and removing existing Ollama container..."
    docker stop ollama >/dev/null 2>&1
    docker rm ollama >/dev/null 2>&1
    echo -e "${GREEN}Cleaned up existing Ollama container.${NC}"
fi

# Run Ollama container with GPU support if available
echo -e "${GREEN}Starting Ollama container...${NC}"
RUN_ARGS="-d --name ollama -p 11434:11434 -v ollama:/root/.ollama --restart unless-stopped"

if $NVIDIA_SUPPORT; then
    RUN_ARGS+=" --gpus all"
    echo -e "${GREEN}Starting with GPU support (RTX 5070)...${NC}"
else
    echo -e "${YELLOW}Starting without GPU support (CPU only)...${NC}"
fi

# Fixed: Properly quote the docker run command to avoid parsing issues
if ! docker run $RUN_ARGS ollama/ollama; then
    echo -e "${RED}Error: Failed to start Ollama container.${NC}"
    exit 1
fi
echo -e "${GREEN}Ollama container started successfully.${NC}"

# Give container time to start
echo -e "${YELLOW}Waiting for Ollama service to start...${NC}"
sleep 10

# Verify Ollama is running in container
echo -e "${YELLOW}Verifying Ollama service in container...${NC}"
OLLAMA_READY=false
MAX_ATTEMPTS=15
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ] && [ "$OLLAMA_READY" = false ]; do
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        OLLAMA_READY=true
        echo -e "${GREEN}Ollama service is ready!${NC}"
    else
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            echo -e "${YELLOW}Waiting for Ollama to start... (attempt $ATTEMPT/$MAX_ATTEMPTS)${NC}"
            sleep 5
        fi
    fi
done

if [ "$OLLAMA_READY" = false ]; then
    echo -e "${YELLOW}Warning: Could not verify Ollama API is responding. The container might still be starting.${NC}"
    echo "You can check manually with: docker logs -f ollama"
fi

# Pull the Nemotron Super 8B Q4_K_M model
echo -e "${GREEN}Pulling Nemotron Super 8B Q4_K_M model (this is the model specified in your system prompt)...${NC}"
echo -e "${YELLOW}This may take a while depending on your internet connection (model size ~4.9GB)...${NC}"

if ! docker exec ollama ollama pull nemotron-super:8b-q4_K_M; then
    echo -e "${YELLOW}Warning: Failed to pull nemotron-super:8b-q4_K_M with exact name. Trying alternative formats...${NC}"
    
    # Try alternative naming conventions that might exist in Ollama library
    MODEL_NAMES=("nemotron-super:8b" "nemotron-super:latest" "nemotron:8b" "nemotron-super-8b" "hf.co/nemotron-super-8b-v2:q4_k_m")
    SUCCESS=false
    
    for MODEL_NAME in "${MODEL_NAMES[@]}"; do
        echo -e "${YELLOW}Trying to pull $MODEL_NAME...${NC}"
        if docker exec ollama ollama pull "$MODEL_NAME"; then
            echo -e "${GREEN}Successfully pulled $MODEL_NAME!${NC}"
            SUCCESS=true
            break
        else
            echo -e "${YELLOW}Failed to pull $MODEL_NAME${NC}"
        fi
    done
    
    if [ "$SUCCESS" = false ]; then
        echo -e "${YELLOW}Could not pull Nemotron Super model automatically.${NC}"
        echo ""
        echo "Please pull the model manually once the container is running:"
        echo "docker exec ollama ollama pull nemotron-super:8b-q4_K_M"
        echo "Or check available models with: docker exec ollama ollama list"
    fi
else
    echo -e "${GREEN}Model nemotron-super:8b-q4_K_M pulled successfully!${NC}"
fi

# Verify the model is available
echo -e "${GREEN}Verifying model installation...${NC}"
if MODELS=$(docker exec ollama ollama list 2>/dev/null); then
    echo -e "${GREEN}Available models in container:${NC}"
    echo "$MODELS"
    
    if echo "$MODELS" | grep -i nemotron &> /dev/null; then
        echo -e "${GREEN}Nemotron Super model is ready for use!${NC}"
    else
        echo -e "${YELLOW}Warning: Model may not be properly installed. Please check with 'docker exec ollama ollama list'${NC}"
        echo "You can try pulling it manually: docker exec ollama ollama pull nemotron-super:8b-q4_K_M"
    fi
else
    echo -e "${YELLOW}Warning: Could not verify model list.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Installation complete! 🎉${NC}"
echo ""
echo -e "${GREEN}BENCHMARK.me vault created at: ${vaultPath}${NC}"
echo ""
echo -e "${GREEN}To use the BENCHMARK.me health knowledge agent:${NC}"
echo -e "${YELLOW}1. Make sure the Ollama container is running:${NC}"
echo "   docker start ollama (if stopped)"
echo -e "${YELLOW}2. The agent will connect to the local model via API at http://localhost:11434${NC}"
echo -e "${YELLOW}3. Start processing your health data in the Obsidian vault at: ${vaultPath}${NC}"
echo ""
echo -e "${GREEN}Vault structure:${NC}"
echo -e "${YELLOW}  ${vaultPath}/${NC}"
echo -e "${YELLOW}  ├─ base-stats/       # Measurements (weight.md, hrv.md, etc.)${NC}"
echo -e "${YELLOW}  ├─ conditions/       # Diagnoses (adhd.md, asthma.md, etc.)${NC}"
echo -e "${YELLOW}  ├─ facts/            # Personal observations (caffeine-after-2pm-bad.md, etc.)${NC}"
echo -e "${YELLOW}  ├─ llm-clusters/     # LLM-generated correlations${NC}"
echo -e "${YELLOW}  ├─ templates/        # Frontmatter templates${NC}"
echo -e "${YELLOW}  └─ inbox/            # Raw unprocessed input${NC}"
echo ""
echo -e "${GREEN}Management commands:${NC}"
echo -e "${YELLOW}  View logs: docker logs -f ollama${NC}"
echo -e "${YELLOW}  Stop container: docker stop ollama${NC}"
echo -e "${YELLOW}  Start container: docker start ollama${NC}"
echo -e "${YELLOW}  Remove container: docker stop ollama && docker rm ollama${NC}"
echo -e "${YELLOW}  Pull different model: docker exec ollama ollama pull <model-name>${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "${YELLOW}1. Open your vault in Obsidian: ${vaultPath}${NC}"
echo -e "${YELLOW}2. Install the BENCHMARK.me Obsidian plugin (if available)${NC}"
echo -e "${YELLOW}3. Or use the CLI tools to process your inbox/${NC}"
echo -e "${YELLOW}4. Begin adding your health data!${NC}"