#!/bin/bash
set -e

# Print with colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration - you can modify these variables
# ================================================
# Production URL - change to your actual domain
PRODUCTION_URL="https://yourmedusastore.com"
# Admin email to create if needed
ADMIN_EMAIL="admin@yourmedusastore.com"
# Admin password 
ADMIN_PASSWORD="secure-password-change-me"
# Backup directory
BACKUP_DIR="./backups"
# Timeout for service health checks (in seconds)
HEALTH_CHECK_TIMEOUT=60
# ================================================

echo -e "${YELLOW}Starting Medusable production deployment...${NC}"
timestamp=$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to check if a service is healthy
check_service_health() {
  local service=$1
  local timeout=$2
  local counter=0
  
  echo -e "${YELLOW}Waiting for $service to become healthy (timeout: ${timeout}s)...${NC}"
  
  while [ $counter -lt $timeout ]; do
    if docker compose ps $service | grep -q "Up"; then
      echo -e "${GREEN}$service is healthy!${NC}"
      return 0
    fi
    sleep 1
    counter=$((counter+1))
  done
  
  echo -e "${RED}$service failed to become healthy within ${timeout}s.${NC}"
  return 1
}

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker and Docker Compose are required but not installed.${NC}"
    exit 1
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}PNPM is not installed. Installing PNPM...${NC}"
    npm install -g pnpm@9.11.0
fi

# Backup current database if it exists
if docker compose ps -q postgres &>/dev/null; then
    echo -e "${YELLOW}Creating database backup before deployment...${NC}"
    docker compose exec -T postgres pg_dump -U postgres medusable > "$BACKUP_DIR/medusable_backup_$timestamp.sql" || {
        echo -e "${YELLOW}Warning: Could not create database backup. Continuing deployment...${NC}"
    }
fi

# Check for .env file and create from template if needed
if [ ! -f .env ]; then
    echo -e "${GREEN}Setting up environment file...${NC}"
    cp .env.template .env
    
    # Update .env file with production settings
    sed -i'.bak' "s|BACKEND_URL=http://localhost:9000|BACKEND_URL=$PRODUCTION_URL|g" .env
    sed -i'.bak' "s|JWT_SECRET=supersecret|JWT_SECRET=$(openssl rand -hex 32)|g" .env
    sed -i'.bak' "s|COOKIE_SECRET=supersecret|COOKIE_SECRET=$(openssl rand -hex 32)|g" .env
fi

# Build the Docker images
echo -e "${GREEN}Building Docker images...${NC}"
docker compose build

# Start only database services
echo -e "${GREEN}Starting database services...${NC}"
docker compose up -d postgres redis

# Wait for services to initialize
echo -e "${YELLOW}Waiting for database services to initialize...${NC}"
if ! check_service_health postgres $HEALTH_CHECK_TIMEOUT || ! check_service_health redis $HEALTH_CHECK_TIMEOUT; then
    echo -e "${RED}Database services failed to start properly.${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs postgres redis
    exit 1
fi

# Setup the project
echo -e "${GREEN}Setting up the project...${NC}"
pnpm install

# Check if database exists already
if docker compose exec -T postgres psql -U postgres -lqt | grep -q medusable; then
    echo -e "${YELLOW}Database already exists. Running migrations...${NC}"
    pnpm db:migrate
else
    echo -e "${GREEN}Setting up the database...${NC}"
    pnpm db:setup
    
    # Seed the database
    echo -e "${GREEN}Seeding the database...${NC}"
    pnpm db:seed
    
    # Create admin user
    echo -e "${GREEN}Creating admin user...${NC}"
    pnpm medusa user -e "$ADMIN_EMAIL" -p "$ADMIN_PASSWORD"
fi

# Start all services
echo -e "${GREEN}Starting all services...${NC}"
docker compose up -d

# Check if all services are running
if ! check_service_health medusable $HEALTH_CHECK_TIMEOUT; then
    echo -e "${RED}Error: Medusable service failed to start properly.${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs medusable
    exit 1
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}Medusa Store: $PRODUCTION_URL${NC}"
echo -e "${GREEN}Medusa Admin: $PRODUCTION_URL/app${NC}"
echo -e "${GREEN}Admin API:    $PRODUCTION_URL/admin${NC}"
echo -e "${GREEN}Store API:    $PRODUCTION_URL/store${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${YELLOW}IMPORTANT: Please secure your admin password and update URLs as needed.${NC}" 