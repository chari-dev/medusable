#!/bin/bash
set -e

# Print with colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Medusable deployment...${NC}"

# Check if Docker and Docker Compose are installed
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker and Docker Compose are required but not installed.${NC}"
    exit 1
fi

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}PNPM is not installed. Installing PNPM...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    apt install -y nodejs
    node -v
    npm -v
    npm install -g pnpm@9.11.0
fi

# Copy environment template
echo -e "${GREEN}Setting up environment...${NC}"
cp .env.template .env

# Build the Docker images before starting services
echo -e "${GREEN}Building Docker images...${NC}"
docker compose build

# Start only postgres and redis services
echo -e "${GREEN}Starting database services...${NC}"
docker compose up -d postgres redis

# Wait for services to initialize
echo -e "${YELLOW}Waiting for services to initialize...${NC}"
sleep 5

# Check if services are running
if ! docker compose ps postgres | grep -q "Up" || ! docker compose ps redis | grep -q "Up"; then
    echo -e "${RED}Error: Database services failed to start properly.${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs postgres redis
    exit 1
fi

# Setup the project
echo -e "${GREEN}Setting up the project...${NC}"
pnpm install

# Setup the database
echo -e "${GREEN}Setting up the database...${NC}"
pnpm db:setup

# Seed the database
echo -e "${GREEN}Seeding the database...${NC}"
pnpm db:seed

# Create user
echo -e "${GREEN}Creating admin user...${NC}"
pnpm create-user

# Start all services
echo -e "${GREEN}Starting all services...${NC}"
docker compose up -d

# Check if all services are running
if ! docker compose ps | grep -q "medusable.*Up"; then
    echo -e "${RED}Error: Medusable service failed to start properly.${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    docker compose logs medusable
    exit 1
fi

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}Medusa Admin: http://localhost:9000/app${NC}"
echo -e "${GREEN}Admin API:    http://localhost:9000/admin${NC}"
echo -e "${GREEN}Store API:    http://localhost:9000/store${NC}"
echo -e "${GREEN}======================================================${NC}" 