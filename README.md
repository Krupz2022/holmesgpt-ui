# HolmesGPT UI

This project provides a simple UI and backend server setup for HolmesGPT.  

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