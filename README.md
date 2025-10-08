# 🧠 Smart Notes

Smart Notes is an intelligent, full-stack note-taking app that uses AI to **summarize your thoughts** and **protect your privacy**. It features **adaptive privacy modes** that automatically lock sensitive notes and **context-aware summaries** that generate weekly digests of your writing themes. The app is fully containerized with Docker, includes a CI/CD pipeline using GitHub Actions, and can be deployed easily on AWS, Google Cloud, or Azure.

---

## 🚀 Features
- 🧩 **Adaptive Privacy:** Detects sensitive data (like passwords or finances) and auto-locks those notes securely.  
- 🧠 **Smart Summaries:** Uses AI to summarize notes weekly, showing recurring themes and ideas.  
- 📝 **CRUD Operations:** Create, view, update, and delete notes with an intuitive UI.  
- ☁️ **Cloud Ready:** Dockerized for seamless deployment across cloud services.  
- 🔁 **CI/CD Pipeline:** GitHub Actions automatically tests and builds on every push to `main`.

---

## 🧭 Tech Stack
- **Frontend:** React + TypeScript  
- **Backend:** Node.js + Express  
- **Database:** MongoDB (Atlas)  
- **AI Layer:** OpenAI API  
- **Containerization:** Docker + Docker Compose  
- **CI/CD:** GitHub Actions  
- **Cloud Hosting:** AWS EC2 (Free Tier)  

---

## ⚙️ Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/your-username/smart-notes.git
cd smart-notes
