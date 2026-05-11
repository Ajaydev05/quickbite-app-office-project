# QuickBite 🍔

A full-stack food ordering platform (React + Node.js + MongoDB)
deployed on **AWS ECS (Fargate)** via **AWS Copilot**, with
CI/CD powered by **Jenkins + ECR**.

## Architecture

```
Developer → GitHub → Webhook → Jenkins EC2
                                    │
                          ┌─────────▼─────────┐
                          │  Build Docker imgs  │
                          │  Push to AWS ECR    │
                          └─────────┬─────────┘
                                    │  copilot svc deploy
                          ┌─────────▼─────────┐
                          │  AWS ECS Fargate    │
                          │  ├─ frontend svc    │
                          │  └─ backend svc     │
                          └───────────────────┘
```

## Stack

| Layer     | Technology                          |
|-----------|-------------------------------------|
| Frontend  | React 18, Tailwind CSS, Nginx       |
| Backend   | Node.js 20, Express, MongoDB        |
| Container | Docker (multi-stage builds)         |
| Registry  | AWS ECR                             |
| Hosting   | AWS ECS Fargate (via AWS Copilot)   |
| CI/CD     | Jenkins + GitHub Webhook            |
| Secrets   | AWS SSM Parameter Store             |

## Project Structure

```
QuickBite/
├── backend/                  # Node.js / Express API
│   ├── src/
│   └── Dockerfile
├── frontend/                 # React app served by Nginx
│   ├── src/
│   └── Dockerfile
├── copilot/                  # AWS Copilot manifests
│   ├── backend/manifest.yml
│   └── frontend/manifest.yml
├── jenkins/
│   └── Jenkinsfile           # CI/CD pipeline (ECR + ECS)
├── scripts/                  # Utility scripts
├── docker-compose.yml        # Local development only
└── copilot-commands.md       # Step-by-step AWS Copilot setup guide
```

## Quick Start (Local Dev)

```bash
docker-compose up --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:5000
```

## AWS Deployment

See **`copilot-commands.md`** for the full step-by-step guide.

```bash
# One-time setup
copilot app init quickbite
copilot svc init --name backend  --svc-type "Backend Service"          --dockerfile backend/Dockerfile
copilot svc init --name frontend --svc-type "Load Balanced Web Service" --dockerfile frontend/Dockerfile
copilot secret init
copilot env init   --name prod --default-config
copilot env deploy --name prod

# First deploy
copilot svc deploy --name backend  --env prod
copilot svc deploy --name frontend --env prod
```

After the one-time setup, every `git push` to GitHub automatically
triggers Jenkins to build, push to ECR, and deploy to ECS.
