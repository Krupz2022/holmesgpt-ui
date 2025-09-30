# HolmesGPT UI

This project provides a simple UI and backend server setup for HolmesGPT.  

# Note
For now only tested with Azure

## Set ENV in OS
```
bash
AZURE_API_VERSION="<Your azure open ai api version>"
AZURE_API_BASE="<Your azure open ai api url>"
AZURE_API_KEY="<Your azure open ai api key>"
```

## Getting Started

Follow the steps below to set up and run the project.

---

### Step 1: Clone the Repository
```bash
git clone <repository-url>
```
### Step 2: place web folder content in /var/www/html [Assuming using Apache2 or Nginx]

### Step 3: Initialize Go 
```bash
cd holmesgpt-ui
go mod init holmesgpt-ui
go mod tidy
```
### Step 4: Run the server
```bash
cd api/cmd/server
go run .
```
### To Run via Docker
```bash
docker pull krupz/holmesgpt-ui:latest

docker run -p 80:80 -d \
  -e AZ_CLIENT_ID="" \
  -e AZ_CLIENT_SECRET=""  \
  -e AZ_TENANT_ID="" \
  -e AZ_SUBSCRIPTION_ID="" \
  -e CLUSTER_NAME="" \
  -e CLUSTER_RG="" \
  -e RMQ_USER=""
  -e RMQ_PASSWORD="" \
  -e RMQ_URI="" \
  -e AZURE_API_VERSION="" \
  -e AZURE_API_BASE="" \
  -e AZURE_API_KEY="" \
  --name holmesgpt-ui krupz/holmesgpt-ui
```
