# 📁 Project Management Feature - User Guide

## Overview

The AI DevOps Automation Platform now includes a comprehensive **Project Management** system that allows you to:

- ✅ Create and manage multiple projects
- ✅ Configure Azure DevOps boards per project
- ✅ Attach multiple GitHub repositories to each project
- ✅ Connect observability platforms (Datadog, Rollbar, New Relic, Sentry)
- ✅ Setup Microsoft Teams notifications
- ✅ Switch between projects to filter incidents and activity

---

## 🎯 Key Features

### 1. **Project Selector (Header)**
Located in the top-right header, next to the action buttons:

```
[Project: GRC Spend Management ▼] [⚙️]
```

- **Dropdown** - Switch between projects or view "All Projects"
- **⚙️ Button** - Quick access to project configuration

**Available Projects:**
- GRC Spend Management (default)
- Workforce Solutions
- Provider Platform
- Custom projects you create

### 2. **Projects Tab** 📁
New navigation tab showing all your projects in a grid layout.

Each project card displays:
- **Project name and description**
- **Number of ADO boards**
- **List of GitHub repositories**
- **Connected observability platforms**
- **Project statistics** (incidents, PRs, tickets)

**Actions:**
- Click card to view full configuration
- Click "Create New Project" to add projects

### 3. **Project Configuration Modal**
Click any project card or the ⚙️ button to view:

**Sections:**
- 📋 **Azure DevOps Boards** - All configured boards
- 📦 **GitHub Repositories** - All connected repos
- 📊 **Observability Platforms** - Active integrations
- 💬 **Microsoft Teams** - Webhook status
- 📊 **Project Statistics** - Usage metrics

**Actions:**
- Edit Configuration
- View connection status
- See real-time stats

### 4. **Create/Edit Project Form**
Comprehensive form to configure every aspect:

---

## 📋 How to Create a New Project

### Step 1: Open Create Project Modal

**Three ways to access:**
1. Click "Projects" tab → "Create New Project" button
2. Click ⚙️ in project selector → "Create New Project"
3. Edit existing project from configuration modal

### Step 2: Fill in Project Information

```
Project Name: GRC Spend Management
Description: Healthcare procurement and medical device value analysis platform
```

### Step 3: Configure Azure DevOps Boards

**For Each Board:**
```
Organization URL: https://dev.azure.com/symplr
Project Name: GRC-Spend
Board Name: Sprint Board
```

**Add Multiple Boards:**
- Click "➕ Add Another ADO Board"
- Configure each board separately
- One project can have multiple ADO boards

**Example Multi-Board Setup:**
```
Board 1:
  Organization: https://dev.azure.com/symplr
  Project: GRC-Spend
  Board: Sprint Board

Board 2:
  Organization: https://dev.azure.com/symplr
  Project: GRC-Spend
  Board: Bug Tracking
```

### Step 4: Add GitHub Repositories

**For Each Repository:**
```
Repository Owner: symplr
Repository Name: grc-spend-greenlight
Branch to Monitor: main
```

**Add Multiple Repos:**
- Click "➕ Add Another Repository"
- Each repo can monitor different branches
- One project can have unlimited repos

**Example Multi-Repo Setup:**
```
Repo 1:
  Owner: symplr
  Name: grc-spend-greenlight
  Branch: main

Repo 2:
  Owner: symplr
  Name: grc-spend-api
  Branch: master

Repo 3:
  Owner: symplr
  Name: grc-spend-mobile
  Branch: develop
```

### Step 5: Configure Observability Platforms

**Available Platforms:**

#### ✅ Datadog
```
☑ Enable Datadog
  API Key: xxxxxxxxxxxxxxxx
  App Key: xxxxxxxxxxxxxxxx
  Site: datadoghq.com
```

#### ✅ Rollbar
```
☑ Enable Rollbar
  Access Token: xxxxxxxxxxxxxxxx
  Project Name: grc-spend-prod
```

#### ✅ New Relic
```
☑ Enable New Relic
  API Key: xxxxxxxxxxxxxxxx
  Account ID: 123456
```

#### ✅ Sentry
```
☑ Enable Sentry
  DSN: https://xxxxx@sentry.io/xxxxx
  Organization Slug: symplr
```

**How It Works:**
- Check the platform you want to enable
- Configuration fields appear below
- Fill in authentication credentials
- Multiple platforms can be active simultaneously

### Step 6: Setup Microsoft Teams Notifications

```
Webhook URL: https://outlook.office.com/webhook/...
Notification Channel: #devops-alerts
```

**What Gets Notified:**
- New incidents detected
- PRs created automatically
- Assigned developers
- Ticket updates

### Step 7: Save Project

Click **"Save Project"** button at bottom.

**Success Confirmation:**
```
✅ Project "GRC Spend Management" has been created!

You can now:
• View it in the Projects tab
• Select it from the dropdown
• Monitor incidents for this project
```

---

## 🔄 How the System Uses Projects

### Incident Detection
When an issue is detected, the system:

1. **Identifies the source**
   - Which GitHub repo had the error?
   - Which observability platform reported it?

2. **Maps to project**
   - Finds project containing that repo
   - Links to correct ADO board

3. **Creates ADO ticket**
   - Uses configured ADO organization
   - Posts to correct project and board
   - Tags with project name

4. **Generates PR**
   - Creates PR in correct GitHub repo
   - Uses monitored branch
   - Links back to ADO ticket

5. **Assigns developer**
   - Checks team members for that project
   - Finds available developer
   - Sends Teams notification to correct channel

### Project Filtering
Use the project dropdown to:

- **View specific project** - See only incidents from GRC Spend
- **View all projects** - See incidents across all projects
- **Compare projects** - Switch between to compare activity

---

## 📊 Example: Multi-Repo Project Setup

### Real-World Scenario

**Project:** GRC Spend Management

**Requirements:**
- 1 ADO Board for tracking work
- 3 GitHub repos (backend, frontend, mobile)
- Datadog for metrics
- Rollbar for errors
- Teams notifications

**Configuration:**

#### Azure DevOps
```
Organization: https://dev.azure.com/symplr
Project: GRC-Spend
Board: Sprint Board
```

#### GitHub Repositories
```
Repo 1: symplr/grc-spend-greenlight (main)
Repo 2: symplr/grc-spend-api (master)
Repo 3: symplr/grc-spend-mobile (develop)
```

#### Observability
```
✓ Datadog - All environments
✓ Rollbar - Production errors
✗ New Relic - Not used
✗ Sentry - Not used
```

#### Notifications
```
Teams Channel: #grc-devops-alerts
```

**Result:**
- Errors from any of the 3 repos get detected
- ADO ticket created in GRC-Spend project
- PR generated in the correct repo
- Team notified in #grc-devops-alerts
- All visible when "GRC Spend" project selected

---

## 🎯 Use Cases

### Use Case 1: Microservices Architecture
**Scenario:** One product with multiple services

```
Project: E-Commerce Platform
ADO Boards: 1 (Main Board)
GitHub Repos:
  - ecommerce-api
  - ecommerce-frontend
  - ecommerce-mobile
  - ecommerce-payment-service
  - ecommerce-notification-service
Observability: Datadog + Sentry
```

**Benefit:** All services monitored under one project, tickets in one board

### Use Case 2: Multi-Team Platform
**Scenario:** Large platform with team-specific boards

```
Project: Healthcare Platform
ADO Boards:
  - Board 1: Backend Team
  - Board 2: Frontend Team
  - Board 3: Mobile Team
GitHub Repos: 15+ repos
Observability: Datadog + Rollbar + New Relic
```

**Benefit:** Issues routed to correct team board automatically

### Use Case 3: Monorepo
**Scenario:** Single repo with multiple components

```
Project: Monolith Application
ADO Boards: 1 (Main Board)
GitHub Repos: 1 (monorepo)
Observability: All platforms enabled
```

**Benefit:** Comprehensive monitoring of single large codebase

---

## 🛠️ Advanced Configuration

### Dynamic Routing Rules

**Future Feature:** Route incidents based on:
- File path patterns
- Error types
- Service names
- Severity levels

**Example:**
```
IF error in "/api/payments/*" 
THEN assign to Payments Team Board
ELSE assign to Main Board
```

### Per-Repo Configuration

**Future Feature:** Different settings per repo:
```
Repo: grc-spend-greenlight
  Branch: main
  Auto-Fix: Enabled
  Confidence Threshold: 85%
  
Repo: grc-spend-mobile
  Branch: develop
  Auto-Fix: Disabled
  Require Manual Review: Yes
```

### Environment-Specific Projects

**Future Feature:** Separate projects per environment:
```
Project: GRC Spend (Production)
Project: GRC Spend (Staging)
Project: GRC Spend (Development)
```

---

## 📖 Best Practices

### ✅ DO:
- Use descriptive project names
- Configure all relevant observability platforms
- Add all related repos to one project
- Test webhook URLs before saving
- Document your project structure

### ❌ DON'T:
- Create projects for every single repo (group related ones)
- Leave observability platforms unconfigured
- Use production keys in demo/test projects
- Forget to configure Teams webhooks

---

## 🎬 Demo Flow

### For Hackathon Presentation:

**Step 1: Show Project Selector**
"Notice we can monitor multiple projects. Let me switch to GRC Spend..."

**Step 2: Open Projects Tab**
"Here are all our configured projects. Each one has multiple repos and ADO boards..."

**Step 3: Click a Project Card**
"Let me show you the GRC Spend configuration. We have:
- 1 ADO board for the team
- 2 GitHub repos (backend and API)
- Datadog and Rollbar monitoring
- Teams notifications configured"

**Step 4: Show Create Project**
"Adding a new project is simple. You configure:
- ADO boards - one or many
- GitHub repos - unlimited
- Observability - pick your tools
- Teams - automatic notifications"

**Step 5: Explain the Flow**
"When an error happens in any repo, the system:
1. Detects it via observability platform
2. Maps to correct project
3. Creates ticket in correct ADO board
4. Generates PR in correct repo
5. Notifies the right team channel"

---

## 🔗 Integration Architecture

```
┌─────────────┐
│   Project   │
└─────┬───────┘
      │
      ├──► 📋 ADO Board 1
      │    📋 ADO Board 2
      │
      ├──► 📦 GitHub Repo 1
      │    📦 GitHub Repo 2
      │    📦 GitHub Repo 3
      │
      ├──► 📊 Datadog
      │    🐛 Rollbar
      │    📈 New Relic
      │
      └──► 💬 Teams Channel
```

**Data Flow:**
1. Error detected in Repo 2
2. Mapped to Project
3. Ticket created in ADO Board 1
4. PR generated in Repo 2
5. Teams notification sent
6. Project stats updated

---

## 📝 Summary

The Project Management feature allows you to:

✅ **Organize** - Group related repos and boards  
✅ **Configure** - Connect all your tools in one place  
✅ **Monitor** - Track incidents per project  
✅ **Route** - Automatic ticket and PR creation  
✅ **Scale** - Support unlimited projects and repos  

**Result:** One platform managing your entire DevOps workflow across all projects!

---

**Ready to use? Click the Projects tab and explore! 🚀**
