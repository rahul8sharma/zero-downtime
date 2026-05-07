# Zero Downtime - AI DevOps Automation Platform

> **Hackathon Project**: AI-Powered DevOps platform that automates incident response from error detection to PR creation in 30 seconds.

## 🎯 Quick Start

### Prerequisites
- Ruby 3.0.6 or higher
- Rails 7.1.6
- PostgreSQL (or change database.yml to use SQLite)

### Installation

```bash
# Navigate to project directory
cd /Users/rahulsharma/symplr/hackathon/zero-downtime

# Install dependencies
bundle install

# Setup database (if using PostgreSQL)
rails db:create

# Start the server
rails server
```

### Access the Application

Open your browser and navigate to:
```
http://localhost:3000
```

## 📁 Project Structure

```
zero-downtime/
├── app/
│   ├── assets/
│   │   ├── images/
│   │   │   └── symplr-logo.svg          # Company logo
│   │   └── stylesheets/
│   │       ├── application.css          # Rails default styles
│   │       ├── styles.css               # Main UI styles (symplr theme)
│   │       └── styles-additions.css     # Additional component styles
│   ├── controllers/
│   │   └── dashboard_controller.rb      # Main dashboard controller
│   ├── javascript/
│   │   └── app.js                       # All application JavaScript
│   └── views/
│       ├── dashboard/
│       │   └── index.html.erb           # Main dashboard view
│       └── layouts/
│           └── application.html.erb     # Application layout
├── config/
│   └── routes.rb                        # Routes configuration
└── README_RAILS.md                      # This file
```

## 🚀 Features

### 1. **Dashboard**
- Real-time incident monitoring
- Key metrics (MTTR, Auto-Fix Rate, Cost Savings)
- Live incident feed with status tracking

### 2. **Logs Explorer** 🔍
- Unified log search across multiple platforms:
  - Datadog
  - AWS CloudWatch
  - Rollbar
  - New Relic
  - Sentry
- Filter by time range, severity, service
- Bulk operations on logs
- One-click actions: View, Create Ticket, AI Fix

### 3. **Alert Rules Management** 📋
- Create alert rules once, deploy to all platforms
- Support for multiple metric types
- Project-specific or global rules
- Notification configuration (Teams, Email, ADO)

### 4. **Projects Management** 📁
- Multi-project configuration
- Link multiple ADO boards per project
- Connect multiple GitHub repositories
- Configure observability platforms per project

### 5. **Analytics** 📈
- Incident trends visualization
- Auto-fix success rate tracking
- Top issue categories
- Team performance metrics

### 6. **Integrations** 🔗
- GitHub (PR creation, repository monitoring)
- Azure DevOps (ticket creation, board management)
- Observability platforms (unified monitoring)
- Microsoft Teams (notifications)

### 7. **Team Management** 👥
- Developer availability tracking
- Workload balancing
- Smart assignment based on expertise

### 8. **Activity Log** 📝
- Real-time activity feed
- Audit trail of all actions
- System events tracking

### 9. **Alerts** 🔔
- Real-time alert dashboard
- Severity-based filtering
- Quick actions (Investigate, Acknowledge, Snooze)

### 10. **Reports** 📄
- Monthly summary reports
- Cost savings reports
- Performance metrics
- Trend analysis

### 11. **Settings** ⚙️
- Notification preferences
- AI configuration (confidence threshold)
- Security & access management

## 🎨 UI Components

- **Sidebar Navigation** - Organized by sections (Main, Management, Monitoring, Settings)
- **Project Selector** - Quick project switching in header
- **Interactive Modals** - Create projects, alert rules, view log details
- **Live Demo** - Step-by-step automation demonstration
- **How It Works Guide** - Comprehensive workflow documentation

## 🔑 Key Technologies

- **Frontend**: HTML5, CSS3 (symplr branded), Vanilla JavaScript
- **Backend**: Ruby on Rails 7.1.6
- **Asset Pipeline**: Sprockets
- **Database**: PostgreSQL (configurable)
- **Styling**: Custom CSS with CSS Variables for theming

## 📊 Sample Data

The application includes realistic sample data:
- 6 sample incidents with varying severities
- 11 sample log entries from different platforms
- 4 pre-configured alert rules
- 3 sample projects (GRC Spend, Workforce, Provider)
- 3 team members with availability status

## 🎬 Demo Flow

1. **Open Application** → Dashboard loads with metrics
2. **Click "Start Live Demo"** → Watch 30-second automation
3. **Explore Logs** → Search CloudWatch/Datadog logs
4. **Create Alert Rule** → Deploy to all platforms
5. **View Projects** → See multi-repo configuration

## 🔧 Configuration

### Database Setup

By default, the app is configured for PostgreSQL. To use SQLite for demo:

Edit `config/database.yml`:
```yaml
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: storage/development.sqlite3
```

### Asset Compilation (Production)

```bash
# Precompile assets
rails assets:precompile

# Start production server
RAILS_ENV=production rails server
```

## 🎯 Hackathon Presentation Tips

### Demo Script
1. **Show Dashboard** (30 sec) - Highlight metrics
2. **Run Live Demo** (30 sec) - Show automation
3. **Explore Logs** (45 sec) - Query and fix
4. **Create Alert Rule** (30 sec) - Show unified deployment
5. **View Analytics** (30 sec) - Show impact metrics

**Total: 3 minutes**

### Key Talking Points
- ✅ "Reduces incident response time by 90%"
- ✅ "Unifies 5 observability platforms in one view"
- ✅ "AI generates code fixes, not just infrastructure fixes"
- ✅ "Creates PRs automatically with confidence scoring"
- ✅ "Saves $117K annually per team"

## 📝 Additional Documentation

- `README.md` - Original project overview
- `DEMO_SCRIPT.txt` - Detailed presentation script
- `QUICK_START.txt` - Visual quick reference
- `PROJECT_MANAGEMENT_GUIDE.md` - Project feature documentation
- `WHATS_NEW.txt` - Recent feature additions
- `FINDING_PROJECT_FEATURES.txt` - Feature navigation guide

## 🚀 Deployment (Future)

For production deployment:

```bash
# Setup environment variables
export RAILS_ENV=production
export SECRET_KEY_BASE=$(rails secret)

# Setup database
rails db:create RAILS_ENV=production
rails db:migrate RAILS_ENV=production

# Precompile assets
rails assets:precompile

# Start server (use Puma in production)
bundle exec puma -C config/puma.rb
```

## 🤝 Contributing

This is a hackathon project. For questions or improvements:
- Contact: Rahul Sharma
- Repository: symplr/hackathon/zero-downtime

## 📄 License

Internal symplr hackathon project - All rights reserved.

---

**Built with ❤️ for symplr Hackathon 2024**

*Transforming DevOps from reactive firefighting to proactive automation*
