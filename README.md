# 🗄️ Database

This directory contains database initialization scripts and schemas for the TechTorque 2025 system.

### 📂 Contents

- **init-databases.sql:** SQL scripts to initialize all microservice databases with proper schemas and seed data.

### ⚙️ Tech Stack

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white) ![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

- **Relational Database:** PostgreSQL (for transactional data)
- **NoSQL Database:** MongoDB (for notifications and chat logs)

### 🚀 Usage

Database containers are automatically initialized when running the main `docker-compose` setup from the project root.

```bash
# From the root of the TechTorque-2025 project
docker-compose up --build
```
