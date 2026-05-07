# Zero Downtime - Setup & Launch Guide

## 🚀 Quick Start (5 Minutes)

### Option 1: Automated Startup Script

```bash
cd /Users/rahulsharma/symplr/hackathon/zero-downtime
./START.sh
```

Then open your browser to: **http://localhost:3000**

### Option 2: Manual Startup

```bash
cd /Users/rahulsharma/symplr/hackathon/zero-downtime
rails server
```

Then open your browser to: **http://localhost:3000**

---

## 📋 Prerequisites

✅ **Already Installed:**
- Ruby 3.0.6
- Rails 7.1.6
- SQLite3
- All gems (bundled)
- All assets (CSS, JS, images)

✅ **Database:**
- SQLite database already created
- No additional setup required

---

## 🎯 For Hackathon Demo

### Before Your Presentation:

1. **Test the application:**
   ```bash
   cd /Users/rahulsharma/symplr/hackathon/zero-downtime
   ./START.sh
   ```

2. **Open browser to http://localhost:3000**

3. **Verify all features work:**
   - ✅ Dashboard loads
   - ✅ "Start Live Demo" button works
   - ✅ Logs Explorer searches
   - ✅ Alert Rules creates new rules
   - ✅ Projects tab shows project cards
   - ✅ All tabs are clickable

4. **Keep server running during demo**

5. **Have backup:** Keep `/Users/rahulsharma/symplr/hackathon/index.html` open in another browser tab

---

## 🎬 Demo Checklist

**15 Minutes Before:**
- [ ] Start Rails server (`./START.sh`)
- [ ] Open http://localhost:3000 in Chrome
- [ ] Test "Start Live Demo" button
- [ ] Test Logs Explorer search
- [ ] Verify all tabs work

**During Demo:**
- [ ] Show Dashboard metrics
- [ ] Click "Start Live Demo" (30 seconds)
- [ ] Navigate to Logs Explorer
- [ ] Search CloudWatch logs
- [ ] Create an alert rule
- [ ] Show Projects tab
- [ ] Show Analytics page

**After Demo:**
- [ ] Answer questions
- [ ] Show "How It Works" guide if asked

---

## 🔧 Troubleshooting

### Server Won't Start

**Problem:** Port 3000 already in use

**Solution:**
```bash
# Kill existing Rails server
pkill -f "rails server"

# Or use different port
rails server -p 3001
```

### Assets Not Loading (CSS/JS broken)

**Problem:** Styles or JavaScript not working

**Solution:**
```bash
# Precompile assets
rails assets:precompile

# Restart server
./START.sh
```

### Database Error

**Problem:** Database not found

**Solution:**
```bash
# Recreate database
rails db:drop db:create db:migrate
```

### Page Not Found (404)

**Problem:** Wrong URL or route issue

**Solution:**
- Ensure you're at http://localhost:3000 (not /dashboard/index)
- Check `config/routes.rb` has `root 'dashboard#index'`

---

## 📁 Project Structure

```
zero-downtime/
├── START.sh                    # Quick start script
├── README_RAILS.md            # Full Rails documentation
├── SETUP_GUIDE.md             # This file
│
├── app/
│   ├── assets/
│   │   ├── images/
│   │   │   └── symplr-logo.svg
│   │   └── stylesheets/
│   │       ├── styles.css
│   │       └── styles-additions.css
│   │
│   ├── controllers/
│   │   └── dashboard_controller.rb
│   │
│   ├── javascript/
│   │   └── app.js              # All application logic
│   │
│   └── views/
│       └── dashboard/
│           └── index.html.erb  # Main UI
│
├── config/
│   ├── routes.rb               # Root route
│   └── database.yml            # SQLite config
│
└── storage/
    └── development.sqlite3     # Database
```

---

## 🎨 Customization

### Change Port

```bash
rails server -p 4000
```

### Enable Turbo (faster page loads)

Already enabled by default in Rails 7.

### Add Authentication (Future)

```ruby
# Gemfile
gem 'devise'

# Generate
rails generate devise:install
rails generate devise User
```

---

## 🐛 Common Issues & Fixes

### 1. "Bundler could not find compatible versions"

```bash
bundle update
```

### 2. "Yarn install --check-files" error

```bash
# Not needed - we're using plain JavaScript, not Webpacker
```

### 3. Assets not showing in production

```bash
RAILS_ENV=production rails assets:precompile
RAILS_ENV=production rails server
```

### 4. JavaScript not executing

Check browser console (F12) for errors. Most common:
- File path wrong in view
- Asset pipeline not compiled
- Turbo blocking execution

**Fix:**
```erb
<!-- In view file -->
<%= javascript_include_tag "app", "data-turbo-track": "reload" %>
```

---

## 🚀 Deployment (Future)

### Heroku

```bash
# Install Heroku CLI
brew install heroku/brew/heroku

# Login
heroku login

# Create app
heroku create zero-downtime-demo

# Deploy
git push heroku main

# Open
heroku open
```

### Docker

```bash
# Build
docker build -t zero-downtime .

# Run
docker run -p 3000:3000 zero-downtime
```

---

## 📖 Additional Resources

- `README.md` - Original demo documentation
- `README_RAILS.md` - Full Rails documentation
- `DEMO_SCRIPT.txt` - Presentation script
- `PROJECT_MANAGEMENT_GUIDE.md` - Feature documentation
- `QUICK_START.txt` - Visual reference

---

## 💡 Pro Tips for Demo

1. **Keep it running:** Start server 30 minutes before demo
2. **Test beforehand:** Click through every feature
3. **Have backup:** Keep static HTML open in another tab
4. **Know your shortcuts:**
   - `Cmd/Ctrl + H` - Opens "How It Works" guide
   - `Cmd/Ctrl + R` - Refresh page
5. **Practice transitions:** Smooth navigation between tabs
6. **Prepare for questions:** Know what each feature does

---

## 🎯 Success Checklist

Before hackathon:
- [x] Rails app created
- [x] All assets migrated
- [x] Database configured
- [x] Server tested
- [x] All features working
- [ ] Rehearse demo 3+ times
- [ ] Prepare answers for common questions
- [ ] Test on presentation laptop
- [ ] Have video backup ready

---

## 🏆 Good Luck!

**You're ready to present!**

Questions? Check the documentation or review the code in `app/`.

**Launch command:**
```bash
cd /Users/rahulsharma/symplr/hackathon/zero-downtime && ./START.sh
```

**Demo URL:**
```
http://localhost:3000
```

---

**Built for symplr Hackathon 2024** 🚀
