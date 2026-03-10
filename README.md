# 🚀 Three-Tier Docker Application

A containerised three-tier web application built with Node.js, PostgreSQL, and Nginx — automatically deployed to an Azure Linux VM via GitHub Actions CI/CD.

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)

---

## Architecture

```
Internet → Port 80 → [Nginx Frontend] → [Node.js Backend] → [PostgreSQL DB]
                       (public)           (internal only)     (private network)
```

| Tier | Technology | Purpose |
|------|-----------|---------|
| Frontend | Nginx + HTML/JS | Serves UI, proxies API requests |
| Backend | Node.js + Express | REST API, business logic |
| Database | PostgreSQL 16 | Persistent data storage |

---

## Project Structure

```
three-tier-app/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── index.html
├── .github/workflows/
│   └── ci-cd.yml
├── docker-compose.yml
├── vm-setup.sh
└── .env.example
```

---

## Running Locally

```bash
# Clone the repo
git clone https://github.com/YOUR_USERNAME/three-tier-app.git
cd three-tier-app

# Generate package-lock.json
cd backend && npm install && cd ..

# Set up environment
cp .env.example .env        # then fill in your values

# Start all services
docker compose up --build

# Open in browser
http://localhost

# Stop
docker compose down
```

---

## Environment Variables

Copy `.env.example` to `.env` and fill in these values:

| Variable | Description |
|----------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `IMAGE_TAG` | Image tag to use (default: latest) |
| `DB_NAME` | PostgreSQL database name |
| `DB_USER` | PostgreSQL username |
| `DB_PASSWORD` | PostgreSQL password |

> Never commit your `.env` file — it is listed in `.gitignore`.

---

## CI/CD Pipeline

Every push to `main` automatically:
1. Builds backend and frontend Docker images
2. Pushes them to Docker Hub with a versioned tag
3. SSHs into the Azure VM and redeploys the containers

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub access token |
| `VM_HOST` | Azure VM public IP |
| `VM_USER` | VM SSH username |
| `VM_SSH_KEY` | Private SSH key (full PEM) |
| `VM_PORT` | SSH port (22) |
| `DB_NAME` | Database name |
| `DB_USER` | Database username |
| `DB_PASSWORD` | Database password |

---

## API Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/items` | Get all items |
| POST | `/api/items` | Create an item |
| DELETE | `/api/items/:id` | Delete an item |

---

## Deployment

**1. Provision the VM (once)**
```bash
scp vm-setup.sh azureuser@YOUR_VM_IP:~/
ssh azureuser@YOUR_VM_IP
chmod +x vm-setup.sh && ./vm-setup.sh
```

**2. Deploy by pushing to main**
```bash
git add .
git commit -m "your message"
git push origin main
```

GitHub Actions handles the rest automatically.

---

## Author

Built as a capstone project demonstrating Docker containerisation, CI/CD automation, and cloud deployment on Azure.
