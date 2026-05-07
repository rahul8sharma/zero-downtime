// Sample Data
const incidents = [
    {
        id: 'INC-001',
        title: 'Batch Job Stuck in Pending',
        severity: 'critical',
        status: 'analyzing',
        type: 'batch_job_stuck',
        created: '2 min ago',
        repo: 'grc-spend-greenlight',
        ticket: 'AB#1618776',
        confidence: 0.87,
        diagnosis: {
            rootCause: 'Redis connection pool exhaustion causing Sidekiq timeout',
            analysis: 'The BatchJobs::CreateModelsData service attempts to process 10,000+ device model records in a single batch without pagination. This causes the Redis connection to time out at line 42 of create_models_data.rb.',
            affectedFiles: ['app/services/batch_jobs/create_models_data.rb:42'],
            suggestedFix: 'Replace Model.all.each with Model.find_each(batch_size: 500) to process records in smaller batches.',
            prLink: 'https://github.com/symplr/grc-spend/pull/1234',
            assignedTo: 'Rahul Sharma'
        }
    },
    {
        id: 'INC-002',
        title: 'CI Pipeline Failed - Test Timeout',
        severity: 'high',
        status: 'fixed',
        type: 'pipeline_failure',
        created: '15 min ago',
        repo: 'workforce-backend',
        ticket: 'AB#1618780',
        confidence: 0.92,
        diagnosis: {
            rootCause: 'RSpec test timeout due to database connection leak',
            analysis: 'Integration tests in spec/requests/api/v3/submissions_spec.rb are not properly cleaning up database connections.',
            affectedFiles: ['spec/requests/api/v3/submissions_spec.rb:125'],
            suggestedFix: 'Add database_cleaner gem and configure transaction strategy for tests.',
            prLink: 'https://github.com/symplr/workforce/pull/567',
            assignedTo: 'Michael Patel'
        }
    },
    {
        id: 'INC-003',
        title: 'API Rate Limit Exceeded',
        severity: 'high',
        status: 'analyzing',
        type: 'api_error',
        created: '22 min ago',
        repo: 'api-gateway',
        ticket: 'AB#1618782',
        confidence: 0.78,
        diagnosis: {
            rootCause: 'Missing rate limit handling in external API integration',
            analysis: 'OpenFDA API calls are not implementing exponential backoff retry logic.',
            affectedFiles: ['app/services/open_fda/base/client.rb:89'],
            suggestedFix: 'Implement Faraday retry middleware with exponential backoff.',
            prLink: null,
            assignedTo: null
        }
    },
    {
        id: 'INC-004',
        title: 'Memory Leak in Background Worker',
        severity: 'medium',
        status: 'fixed',
        type: 'performance',
        created: '1 hour ago',
        repo: 'data-pipeline',
        ticket: 'AB#1618765',
        confidence: 0.95,
        diagnosis: {
            rootCause: 'ActiveRecord objects not being garbage collected',
            analysis: 'Large dataset processing in workers is loading all records into memory.',
            affectedFiles: ['app/workers/data_export_worker.rb:34'],
            suggestedFix: 'Use find_each with batch_size to process records in chunks.',
            prLink: 'https://github.com/symplr/data-pipeline/pull/89',
            assignedTo: 'James Chen'
        }
    },
    {
        id: 'INC-005',
        title: 'Database Connection Pool Exhausted',
        severity: 'critical',
        status: 'analyzing',
        type: 'database',
        created: '5 min ago',
        repo: 'mobile-app-backend',
        ticket: 'AB#1618790',
        confidence: 0.82,
        diagnosis: {
            rootCause: 'Connection leaks in long-running transactions',
            analysis: 'Multiple endpoints not properly releasing database connections after queries.',
            affectedFiles: ['app/controllers/api/v3/products_controller.rb:156'],
            suggestedFix: 'Wrap operations in ActiveRecord::Base.connection_pool.with_connection blocks.',
            prLink: null,
            assignedTo: null
        }
    },
    {
        id: 'INC-006',
        title: 'N+1 Query Detected',
        severity: 'medium',
        status: 'fixed',
        type: 'performance',
        created: '2 hours ago',
        repo: 'grc-spend-greenlight',
        ticket: 'AB#1618755',
        confidence: 0.89,
        diagnosis: {
            rootCause: 'Missing eager loading in associations',
            analysis: 'Submissions index page loading users in a loop causing 500+ queries.',
            affectedFiles: ['app/controllers/api/submissions_controller.rb:45'],
            suggestedFix: 'Add .includes(:user, :hospital, :team) to the query.',
            prLink: 'https://github.com/symplr/grc-spend/pull/1230',
            assignedTo: 'Sarah Kim'
        }
    }
];

let currentFilter = 'all';

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    renderDashboardIncidents();
    renderIncidentsList();
    startActivityFeed();
});

// Tab Switching
function switchTab(tabName) {
    // Remove active class from all tabs and content
    document.querySelectorAll('.nav-tab').forEach(tab => tab.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

    // Add active class to clicked tab
    event.target.classList.add('active');

    // Show corresponding content
    document.getElementById(`${tabName}-tab`).classList.add('active');
}

// Render Dashboard Incidents
function renderDashboardIncidents() {
    const container = document.getElementById('dashboard-incidents');
    if (!container) return; // Guard clause - element doesn't exist on this page

    const criticalIncidents = incidents.filter(inc => inc.severity === 'critical' || inc.severity === 'high').slice(0, 5);

    if (criticalIncidents.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">✅</div><p>No active incidents</p></div>';
        return;
    }

    container.innerHTML = criticalIncidents.map(incident => `
        <div class="incident-card" onclick="showIncidentDetail('${incident.id}')">
            <div class="incident-card-header">
                <div>
                    <div class="incident-title">${incident.title}</div>
                    <div class="incident-id">${incident.ticket} • ${incident.repo}</div>
                </div>
                <span class="status-badge ${incident.status}">${incident.status}</span>
            </div>
            <div class="incident-meta">
                <span>🔥 ${incident.severity}</span>
                <span>⏰ ${incident.created}</span>
                <span>🎯 ${Math.round(incident.confidence * 100)}% confident</span>
            </div>
        </div>
    `).join('');
}

// Render Incidents List
function renderIncidentsList() {
    const container = document.getElementById('incidents-list');
    if (!container) return; // Guard clause - element doesn't exist on this page

    const filteredIncidents = filterIncidentsByType(currentFilter);

    if (filteredIncidents.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">🔍</div><p>No incidents found</p></div>';
        return;
    }

    container.innerHTML = filteredIncidents.map(incident => `
        <div class="incident-card" onclick="showIncidentDetail('${incident.id}')">
            <div class="incident-card-header">
                <div>
                    <div class="incident-title">${incident.title}</div>
                    <div class="incident-id">${incident.ticket} • ${incident.repo}</div>
                </div>
                <span class="status-badge ${incident.status}">${incident.status}</span>
            </div>
            <div class="incident-meta">
                <span>🔥 ${incident.severity}</span>
                <span>⏰ ${incident.created}</span>
                ${incident.diagnosis.assignedTo ? `<span>👤 ${incident.diagnosis.assignedTo}</span>` : ''}
                <span>🎯 ${Math.round(incident.confidence * 100)}% confidence</span>
            </div>
        </div>
    `).join('');
}

// Filter Incidents
function filterIncidentsByType(type) {
    if (type === 'all') return incidents;
    if (type === 'critical') return incidents.filter(inc => inc.severity === 'critical');
    if (type === 'analyzing') return incidents.filter(inc => inc.status === 'analyzing');
    if (type === 'fixed') return incidents.filter(inc => inc.status === 'fixed');
    return incidents;
}

function filterIncidents(type) {
    currentFilter = type;

    // Update button states
    document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
    event.target.classList.add('active');

    renderIncidentsList();
}

// Search Incidents
function searchIncidents(query) {
    const container = document.getElementById('incidents-list');
    const filtered = incidents.filter(inc =>
        inc.title.toLowerCase().includes(query.toLowerCase()) ||
        inc.ticket.toLowerCase().includes(query.toLowerCase()) ||
        inc.repo.toLowerCase().includes(query.toLowerCase())
    );

    if (filtered.length === 0) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">🔍</div><p>No incidents match your search</p></div>';
        return;
    }

    container.innerHTML = filtered.map(incident => `
        <div class="incident-card" onclick="showIncidentDetail('${incident.id}')">
            <div class="incident-card-header">
                <div>
                    <div class="incident-title">${incident.title}</div>
                    <div class="incident-id">${incident.ticket} • ${incident.repo}</div>
                </div>
                <span class="status-badge ${incident.status}">${incident.status}</span>
            </div>
            <div class="incident-meta">
                <span>🔥 ${incident.severity}</span>
                <span>⏰ ${incident.created}</span>
                ${incident.diagnosis.assignedTo ? `<span>👤 ${incident.diagnosis.assignedTo}</span>` : ''}
                <span>🎯 ${Math.round(incident.confidence * 100)}% confidence</span>
            </div>
        </div>
    `).join('');
}

// Show Incident Detail Modal
function showIncidentDetail(incidentId) {
    const incident = incidents.find(inc => inc.id === incidentId);
    if (!incident) return;

    const modal = document.getElementById('incident-modal');
    const content = document.getElementById('incident-detail-content');

    content.innerHTML = `
        <div class="incident-detail-section">
            <h3>📋 Overview</h3>
            <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 1rem; margin-top: 1rem;">
                <div>
                    <strong>Incident ID:</strong> ${incident.id}<br>
                    <strong>Ticket:</strong> ${incident.ticket}<br>
                    <strong>Repository:</strong> ${incident.repo}
                </div>
                <div>
                    <strong>Severity:</strong> <span class="status-badge ${incident.severity}">${incident.severity}</span><br>
                    <strong>Status:</strong> <span class="status-badge ${incident.status}">${incident.status}</span><br>
                    <strong>Created:</strong> ${incident.created}
                </div>
            </div>
        </div>

        <div class="incident-detail-section">
            <h3>🧠 AI Analysis (Confidence: ${Math.round(incident.confidence * 100)}%)</h3>
            <div style="background: var(--bg-tertiary); padding: 1rem; border-radius: 0.5rem; margin-top: 0.75rem;">
                <strong>Root Cause:</strong><br>
                <p style="margin: 0.5rem 0; color: var(--text-muted);">${incident.diagnosis.rootCause}</p>

                <strong style="margin-top: 1rem; display: block;">Detailed Analysis:</strong><br>
                <p style="margin: 0.5rem 0; color: var(--text-muted);">${incident.diagnosis.analysis}</p>
            </div>
        </div>

        <div class="incident-detail-section">
            <h3>📝 Affected Files</h3>
            <div class="code-block">
${incident.diagnosis.affectedFiles.map(file => `📄 ${file}`).join('<br>')}
            </div>
        </div>

        <div class="incident-detail-section">
            <h3>🔧 Suggested Fix</h3>
            <div class="code-block">
${incident.diagnosis.suggestedFix}
            </div>
        </div>

        ${incident.diagnosis.prLink ? `
        <div class="incident-detail-section">
            <h3>🔗 Pull Request</h3>
            <a href="${incident.diagnosis.prLink}" target="_blank" style="color: var(--primary); text-decoration: none;">
                ${incident.diagnosis.prLink}
            </a>
        </div>
        ` : ''}

        ${incident.diagnosis.assignedTo ? `
        <div class="incident-detail-section">
            <h3>👤 Assigned Developer</h3>
            <p>${incident.diagnosis.assignedTo}</p>
            <p style="font-size: 0.875rem; color: var(--text-muted);">
                ✅ PR review request sent via Microsoft Teams
            </p>
        </div>
        ` : `
        <div class="incident-detail-section">
            <h3>⏳ Next Steps</h3>
            <p style="color: var(--text-muted);">
                AI is currently analyzing and generating a fix. Once complete, the system will:
                <ul style="margin: 0.5rem 0 0 1.5rem; color: var(--text-muted);">
                    <li>Create a pull request with the fix</li>
                    <li>Link the PR to ADO ticket ${incident.ticket}</li>
                    <li>Find an available developer</li>
                    <li>Send review request via Microsoft Teams</li>
                </ul>
            </p>
        </div>
        `}
    `;

    modal.classList.add('active');
}

function closeIncidentModal() {
    document.getElementById('incident-modal').classList.remove('active');
}

// Activity Feed
let activityCount = 1;

function startActivityFeed() {
    // Add initial activities
    addActivity('🟢', 'System initialized and monitoring active');

    setTimeout(() => addActivity('🔍', 'Scanning GitHub repositories...'), 2000);
    setTimeout(() => addActivity('📊', 'Connected to Datadog for metrics'), 4000);
    setTimeout(() => addActivity('🐛', 'Connected to Rollbar for error tracking'), 6000);
    setTimeout(() => addActivity('✅', 'All integrations healthy'), 8000);
}

function addActivity(icon, text) {
    const feed = document.getElementById('activity-feed');
    if (!feed) return; // Guard clause - element doesn't exist on this page

    const item = document.createElement('div');
    item.className = 'activity-item';
    item.innerHTML = `
        <span class="activity-time">Just now</span>
        <span class="activity-icon">${icon}</span>
        <span class="activity-text">${text}</span>
    `;
    feed.insertBefore(item, feed.firstChild);
    activityCount++;
}

function clearActivity() {
    const feed = document.getElementById('activity-feed');
    if (!feed) return; // Guard clause - element doesn't exist on this page
    feed.innerHTML = '<div class="activity-item"><span class="activity-time">Just now</span><span class="activity-icon">🟢</span><span class="activity-text">Activity feed cleared</span></div>';
    activityCount = 1;
}

// Trigger Manual Scan
function triggerScan() {
    addActivity('🔍', 'Manual scan triggered by user');

    setTimeout(() => {
        addActivity('📊', 'Analyzing 5 repositories...');
    }, 1000);

    setTimeout(() => {
        addActivity('✅', 'Scan complete - No new issues detected');
    }, 3000);
}

// Demo Flow
let demoStep = 0;
const demoSteps = [
    {
        step: 1,
        title: 'Detecting Issue',
        desc: 'Scanning logs from Datadog...',
        activity: '🔍 Detected batch job stuck for 2+ hours',
        progress: 15
    },
    {
        step: 2,
        title: 'Creating ADO Ticket',
        desc: 'Ticket #AB1618776 created',
        activity: '📋 ADO ticket created: "Batch Job Stuck in Pending"',
        progress: 30
    },
    {
        step: 3,
        title: 'AI Analysis',
        desc: 'Analyzing code with AI engine...',
        activity: '🧠 AI analyzing error context and code',
        progress: 50
    },
    {
        step: 4,
        title: 'Generating Fix',
        desc: 'Creating PR #1234 with fix...',
        activity: '🔧 Generated fix: Add pagination to batch processing',
        progress: 70
    },
    {
        step: 5,
        title: 'Finding Reviewer',
        desc: 'Checking developer availability...',
        activity: '👥 Found 3 available developers',
        progress: 85
    },
    {
        step: 6,
        title: 'Assigning PR',
        desc: 'Notification sent to Rahul Sharma',
        activity: '💬 Teams message sent to Rahul Sharma',
        progress: 100
    }
];

function startDemo() {
    demoStep = 0;
    document.getElementById('demo-modal').classList.add('active');
    document.getElementById('demo-progress').style.width = '0%';
    document.getElementById('demo-status').textContent = 'Initializing demo...';

    // Reset all steps
    document.querySelectorAll('.demo-step').forEach(step => {
        step.classList.remove('active', 'completed');
        step.querySelector('.step-status').textContent = '⏸️';
    });

    setTimeout(runDemoStep, 1000);
}

function runDemoStep() {
    if (demoStep >= demoSteps.length) {
        document.getElementById('demo-status').textContent = '✅ Demo complete! Issue detected, analyzed, fixed, and assigned in 30 seconds.';
        return;
    }

    const current = demoSteps[demoStep];
    const stepElement = document.querySelector(`.demo-step[data-step="${current.step}"]`);

    // Update step UI
    stepElement.classList.add('active');
    stepElement.querySelector('.step-status').textContent = '⏳';

    // Update progress
    document.getElementById('demo-progress').style.width = current.progress + '%';
    document.getElementById('demo-status').textContent = current.title + '...';

    // Add activity
    addActivity(current.activity.charAt(0), current.activity.substring(2));

    // Complete after 2 seconds
    setTimeout(() => {
        stepElement.classList.remove('active');
        stepElement.classList.add('completed');
        stepElement.querySelector('.step-status').textContent = '✅';

        demoStep++;
        runDemoStep();
    }, 2000);
}

function closeModal() {
    document.getElementById('demo-modal').classList.remove('active');
}

// Guide Modal Functions
function openGuide() {
    document.getElementById('guide-modal').classList.add('active');
    addActivity('📖', 'User opened "How It Works" guide');
}

function closeGuide() {
    document.getElementById('guide-modal').classList.remove('active');
}

// Update metrics periodically
setInterval(() => {
    // Simulate real-time updates
    const mttr = document.getElementById('mttr-value');
    const autoResolved = document.getElementById('auto-resolved');

    if (mttr && Math.random() > 0.7) {
        const values = ['14 min', '15 min', '16 min', '13 min'];
        mttr.textContent = values[Math.floor(Math.random() * values.length)];
    }

    if (autoResolved && Math.random() > 0.8) {
        const values = ['65%', '67%', '68%', '66%'];
        autoResolved.textContent = values[Math.floor(Math.random() * values.length)];
    }
}, 5000);

// Pipeline stage animation
setInterval(() => {
    const stages = document.querySelectorAll('.stage-indicator');
    if (stages.length > 0 && Math.random() > 0.5) {
        const randomStage = Math.floor(Math.random() * stages.length);
        stages[randomStage].classList.toggle('active');
    }
}, 3000);

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    // Escape to close modals
    if (e.key === 'Escape') {
        closeModal();
        closeIncidentModal();
        closeGuide();
    }

    // Ctrl/Cmd + K to trigger scan
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        triggerScan();
    }

    // Ctrl/Cmd + D to start demo
    if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
        e.preventDefault();
        startDemo();
    }

    // Ctrl/Cmd + H to open guide
    if ((e.ctrlKey || e.metaKey) && e.key === 'h') {
        e.preventDefault();
        openGuide();
    }
});

// Click outside modal to close
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('modal-overlay')) {
        closeModal();
        closeIncidentModal();
        closeGuide();
        closeProjectManager();
        closeCreateProject();
    }
});

// ============================================
// PROJECT MANAGEMENT
// ============================================

const projects = [
    {
        id: 'grc-spend',
        name: 'GRC Spend Management',
        description: 'Healthcare procurement and medical device value analysis platform',
        adoBoards: [
            { org: 'https://dev.azure.com/symplr', project: 'GRC-Spend', board: 'Sprint Board' }
        ],
        githubRepos: [
            { owner: 'symplr', name: 'grc-spend-greenlight', branch: 'main' },
            { owner: 'symplr', name: 'grc-spend-api', branch: 'master' }
        ],
        observability: {
            datadog: { enabled: true },
            cloudwatch: { enabled: true },
            rollbar: { enabled: true },
            newrelic: { enabled: false },
            sentry: { enabled: false }
        },
        teamsWebhook: 'https://outlook.office.com/webhook/...',
        stats: {
            incidents: 12,
            prs: 47,
            tickets: 58
        }
    },
    {
        id: 'workforce',
        name: 'Workforce Solutions',
        description: 'Time & attendance, scheduling, and workforce management',
        adoBoards: [
            { org: 'https://dev.azure.com/symplr', project: 'Workforce', board: 'Backlog' }
        ],
        githubRepos: [
            { owner: 'symplr', name: 'workforce-backend', branch: 'main' },
            { owner: 'symplr', name: 'workforce-mobile', branch: 'develop' }
        ],
        observability: {
            datadog: { enabled: true },
            cloudwatch: { enabled: true },
            rollbar: { enabled: true },
            newrelic: { enabled: true },
            sentry: { enabled: false }
        },
        teamsWebhook: 'https://outlook.office.com/webhook/...',
        stats: {
            incidents: 8,
            prs: 32,
            tickets: 41
        }
    },
    {
        id: 'provider',
        name: 'Provider Platform',
        description: 'Credentialing and provider data management',
        adoBoards: [
            { org: 'https://dev.azure.com/symplr', project: 'Provider', board: 'Sprint Board' }
        ],
        githubRepos: [
            { owner: 'symplr', name: 'provider-platform', branch: 'main' }
        ],
        observability: {
            datadog: { enabled: true },
            cloudwatch: { enabled: false },
            rollbar: { enabled: false },
            newrelic: { enabled: false },
            sentry: { enabled: true }
        },
        teamsWebhook: 'https://outlook.office.com/webhook/...',
        stats: {
            incidents: 5,
            prs: 18,
            tickets: 29
        }
    }
];

let currentProject = 'grc-spend';

// Render Projects List
function renderProjectsList() {
    const container = document.getElementById('projects-list');
    if (!container) return;

    container.innerHTML = projects.map(project => `
        <div class="project-card" onclick="openProjectManager('${project.id}')">
            <div class="project-card-header">
                <div>
                    <div class="project-card-title">${project.name}</div>
                    <div class="project-card-description">${project.description}</div>
                </div>
                <span class="status-badge success">Active</span>
            </div>

            <div class="project-card-body">
                <div class="project-section">
                    <div class="project-section-title">📋 ADO Boards (${project.adoBoards.length})</div>
                    <div class="project-items-list">
                        ${project.adoBoards.map(board => `
                            <div class="project-item">${board.project} - ${board.board}</div>
                        `).join('')}
                    </div>
                </div>

                <div class="project-section">
                    <div class="project-section-title">📦 GitHub Repos (${project.githubRepos.length})</div>
                    <div class="project-items-list">
                        ${project.githubRepos.map(repo => `
                            <div class="project-item">${repo.owner}/${repo.name}</div>
                        `).join('')}
                    </div>
                </div>

                <div class="project-section">
                    <div class="project-section-title">📊 Observability</div>
                    <div class="project-items-list">
                        ${project.observability.datadog.enabled ? '<div class="project-item">Datadog</div>' : ''}
                        ${project.observability.cloudwatch?.enabled ? '<div class="project-item">AWS CloudWatch</div>' : ''}
                        ${project.observability.rollbar.enabled ? '<div class="project-item">Rollbar</div>' : ''}
                        ${project.observability.newrelic.enabled ? '<div class="project-item">New Relic</div>' : ''}
                        ${project.observability.sentry?.enabled ? '<div class="project-item">Sentry</div>' : ''}
                    </div>
                </div>
            </div>

            <div class="project-card-footer">
                <div class="project-stats">
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.incidents}</div>
                        <div class="project-stat-label">Incidents</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.prs}</div>
                        <div class="project-stat-label">PRs</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.tickets}</div>
                        <div class="project-stat-label">Tickets</div>
                    </div>
                </div>
            </div>
        </div>
    `).join('');
}

// Switch Project
function switchProject(projectId) {
    currentProject = projectId;
    addActivity('🔄', `Switched to project: ${projectId === 'all' ? 'All Projects' : projects.find(p => p.id === projectId)?.name}`);
    // In real implementation, filter incidents and data by project
}

// Open Project Manager
function openProjectManager(projectId) {
    const modal = document.getElementById('project-manager-modal');
    const content = document.getElementById('project-config-content');

    const project = projects.find(p => p.id === projectId);
    if (!project) return;

    content.innerHTML = `
        <div class="project-detail">
            <div class="project-detail-header">
                <h2>${project.name}</h2>
                <p>${project.description}</p>
            </div>

            <div class="form-section">
                <h3>📋 Azure DevOps Boards</h3>
                ${project.adoBoards.map((board, idx) => `
                    <div class="config-item">
                        <strong>Board ${idx + 1}:</strong>
                        <div class="config-details">
                            <span>Organization: ${board.org}</span>
                            <span>Project: ${board.project}</span>
                            <span>Board: ${board.board}</span>
                        </div>
                    </div>
                `).join('')}
                <button class="btn btn-secondary btn-sm" onclick="editProject('${project.id}')">
                    Edit Configuration
                </button>
            </div>

            <div class="form-section">
                <h3>📦 GitHub Repositories</h3>
                ${project.githubRepos.map((repo, idx) => `
                    <div class="config-item">
                        <strong>Repository ${idx + 1}:</strong>
                        <div class="config-details">
                            <span>📦 ${repo.owner}/${repo.name}</span>
                            <span>🌿 Branch: ${repo.branch}</span>
                        </div>
                    </div>
                `).join('')}
            </div>

            <div class="form-section">
                <h3>📊 Observability Platforms</h3>
                <div class="observability-status">
                    ${project.observability.datadog.enabled ? '<span class="status-badge success">✓ Datadog</span>' : '<span class="status-badge">✗ Datadog</span>'}
                    ${project.observability.rollbar.enabled ? '<span class="status-badge success">✓ Rollbar</span>' : '<span class="status-badge">✗ Rollbar</span>'}
                    ${project.observability.newrelic.enabled ? '<span class="status-badge success">✓ New Relic</span>' : '<span class="status-badge">✗ New Relic</span>'}
                </div>
            </div>

            <div class="form-section">
                <h3>💬 Microsoft Teams</h3>
                <div class="config-item">
                    <strong>Webhook Configured:</strong>
                    <span class="status-badge success">✓ Active</span>
                </div>
            </div>

            <div class="form-section">
                <h3>📊 Project Statistics</h3>
                <div class="project-stats">
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.incidents}</div>
                        <div class="project-stat-label">Total Incidents</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.prs}</div>
                        <div class="project-stat-label">PRs Created</div>
                    </div>
                    <div class="project-stat">
                        <div class="project-stat-value">${project.stats.tickets}</div>
                        <div class="project-stat-label">ADO Tickets</div>
                    </div>
                </div>
            </div>
        </div>
    `;

    modal.classList.add('active');
}

function closeProjectManager() {
    document.getElementById('project-manager-modal').classList.remove('active');
}

// Open Create/Edit Project Modal
function openCreateProject(projectId) {
    const modal = document.getElementById('create-project-modal');
    modal.classList.add('active');

    // Setup observability toggles
    setTimeout(() => {
        ['datadog', 'rollbar', 'newrelic', 'sentry'].forEach(platform => {
            const checkbox = document.getElementById(`${platform}-enabled`);
            const config = document.getElementById(`${platform}-config`);
            if (checkbox && config) {
                checkbox.addEventListener('change', function() {
                    config.style.display = this.checked ? 'block' : 'none';
                });
            }
        });
    }, 100);
}

function closeCreateProject() {
    document.getElementById('create-project-modal').classList.remove('active');
    document.getElementById('project-form').reset();
}

function editProject(projectId) {
    closeProjectManager();
    openCreateProject(projectId);
    document.getElementById('project-modal-title').textContent = '✏️ Edit Project';
    // In real implementation, populate form with project data
}

// Add ADO Board
function addAdoBoard() {
    const container = document.getElementById('ado-boards-container');
    const newBoard = document.createElement('div');
    newBoard.className = 'ado-board-item';
    newBoard.innerHTML = `
        <div class="form-group">
            <label>Organization URL</label>
            <input type="text" class="ado-org" placeholder="https://dev.azure.com/your-org">
        </div>
        <div class="form-group">
            <label>Project Name</label>
            <input type="text" class="ado-project" placeholder="e.g., GRC-Spend">
        </div>
        <div class="form-group">
            <label>Board Name</label>
            <input type="text" class="ado-board" placeholder="e.g., Sprint Board">
        </div>
        <button type="button" class="btn btn-danger btn-sm" onclick="this.parentElement.remove()">Remove</button>
    `;
    container.appendChild(newBoard);
}

// Add GitHub Repo
function addGithubRepo() {
    const container = document.getElementById('github-repos-container');
    const newRepo = document.createElement('div');
    newRepo.className = 'github-repo-item';
    newRepo.innerHTML = `
        <div class="form-group">
            <label>Repository Owner</label>
            <input type="text" class="repo-owner" placeholder="e.g., symplr">
        </div>
        <div class="form-group">
            <label>Repository Name</label>
            <input type="text" class="repo-name" placeholder="e.g., grc-spend-greenlight">
        </div>
        <div class="form-group">
            <label>Branch to Monitor</label>
            <input type="text" class="repo-branch" placeholder="e.g., main" value="main">
        </div>
        <button type="button" class="btn btn-danger btn-sm" onclick="this.parentElement.remove()">Remove</button>
    `;
    container.appendChild(newRepo);
}

// Save Project
function saveProject(event) {
    event.preventDefault();

    const projectName = document.getElementById('project-name').value;

    addActivity('✅', `Project "${projectName}" saved successfully`);
    closeCreateProject();

    // Show success message
    setTimeout(() => {
        alert(`Project "${projectName}" has been created!\n\n` +
              `You can now:\n` +
              `• View it in the Projects tab\n` +
              `• Select it from the dropdown\n` +
              `• Monitor incidents for this project`);
    }, 300);
}

// Sidebar Toggle
function toggleSidebar() {
    const sidebar = document.getElementById('sidebar');
    sidebar.classList.toggle('open');
}

// Update switchTab to handle sidebar items
function switchTab(tabName) {
    // Remove active class from all nav tabs and sidebar items
    document.querySelectorAll('.nav-tab, .sidebar-item').forEach(tab => {
        tab.classList.remove('active');
    });

    // Add active to current sidebar item
    document.querySelectorAll('.sidebar-item').forEach(item => {
        if (item.getAttribute('onclick')?.includes(tabName)) {
            item.classList.add('active');
        }
    });

    // Hide all tab contents
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });

    // Show selected tab
    const selectedTab = document.getElementById(`${tabName}-tab`);
    if (selectedTab) {
        selectedTab.classList.add('active');
    }
}

// Logs Explorer
const sampleLogs = [
    {
        id: 'log-001',
        timestamp: '2024-01-15 14:23:45',
        severity: 'critical',
        service: 'api-gateway',
        message: 'Connection timeout: Redis pool exhausted after 5000ms',
        source: 'app/services/batch_jobs/create_models_data.rb:42',
        platform: 'datadog',
        stackTrace: 'Redis::TimeoutError: Connection timeout\n  at Redis::Client.connect (redis-4.5.1/lib/redis/client.rb:389)\n  at BatchJobs::CreateModelsData.perform (app/services/batch_jobs/create_models_data.rb:42)',
        context: { user_id: 12345, request_id: 'req-abc123', environment: 'production' }
    },
    {
        id: 'log-002',
        timestamp: '2024-01-15 14:22:18',
        severity: 'error',
        service: 'submission-service',
        message: 'ActiveRecord::RecordNotFound: Could not find Submission with id=9876',
        source: 'app/controllers/api/v3/submissions_controller.rb:125',
        platform: 'rollbar',
        stackTrace: 'ActiveRecord::RecordNotFound\n  at SubmissionsController.show (app/controllers/api/v3/submissions_controller.rb:125)',
        context: { user_id: 54321, submission_id: 9876, environment: 'production' }
    },
    {
        id: 'log-003',
        timestamp: '2024-01-15 14:20:33',
        severity: 'warning',
        service: 'pricing-engine',
        message: 'Query execution time exceeded threshold: 847ms (limit: 500ms)',
        source: 'app/queries/pricing/calculate_discounts.rb:67',
        platform: 'newrelic',
        stackTrace: 'SlowQuery: SELECT * FROM products WHERE...',
        context: { query_time: 847, threshold: 500, environment: 'production' }
    },
    {
        id: 'log-004',
        timestamp: '2024-01-15 14:19:05',
        severity: 'error',
        service: 'auth-service',
        message: 'JWT token validation failed: Invalid signature',
        source: 'app/middleware/jwt_authenticator.rb:89',
        platform: 'sentry',
        stackTrace: 'JWT::VerificationError: Signature verification failed\n  at JWT.decode (jwt-2.3.0/lib/jwt.rb:89)',
        context: { token_expired: false, user_agent: 'Chrome/120.0', environment: 'production' }
    },
    {
        id: 'log-005',
        timestamp: '2024-01-15 14:18:22',
        severity: 'critical',
        service: 'notification-worker',
        message: 'Sidekiq job failed: Net::OpenTimeout after 30000ms',
        source: 'app/workers/notifications/send_email_worker.rb:34',
        platform: 'datadog',
        stackTrace: 'Net::OpenTimeout: execution expired\n  at SendEmailWorker.perform (app/workers/notifications/send_email_worker.rb:34)',
        context: { job_id: 'job-xyz789', retry_count: 3, environment: 'production' }
    },
    {
        id: 'log-006',
        timestamp: '2024-01-15 14:17:45',
        severity: 'warning',
        service: 'api-gateway',
        message: 'Rate limit approaching: 4800/5000 requests in current window',
        source: 'app/middleware/rate_limiter.rb:56',
        platform: 'datadog',
        stackTrace: 'N/A',
        context: { current_count: 4800, limit: 5000, window: '1 minute', environment: 'production' }
    },
    {
        id: 'log-007',
        timestamp: '2024-01-15 14:16:12',
        severity: 'error',
        service: 'data-import',
        message: 'CSV parsing error: Invalid UTF-8 encoding at line 2847',
        source: 'app/services/imports/csv_processor.rb:123',
        platform: 'rollbar',
        stackTrace: 'EncodingError: invalid byte sequence in UTF-8\n  at CSVProcessor.parse_row (app/services/imports/csv_processor.rb:123)',
        context: { file_name: 'products_import_2024.csv', line_number: 2847, environment: 'production' }
    },
    {
        id: 'log-008',
        timestamp: '2024-01-15 14:15:38',
        severity: 'info',
        service: 'deployment-service',
        message: 'Deployment completed successfully: v2.4.1 to production',
        source: 'deploy.sh',
        platform: 'datadog',
        stackTrace: 'N/A',
        context: { version: 'v2.4.1', environment: 'production', duration: '3m 42s' }
    },
    {
        id: 'log-009',
        timestamp: '2024-01-15 14:14:52',
        severity: 'critical',
        service: 'lambda-processor',
        message: 'Lambda function timeout: Function exceeded 30s execution limit',
        source: 'aws-lambda/process_batch.js:89',
        platform: 'cloudwatch',
        stackTrace: 'Task timed out after 30.00 seconds\n  at Runtime.handler (process_batch.js:89)\n  at Lambda.invoke (aws-sdk)',
        context: { function_name: 'ProcessBatchData', memory_used: '256MB', duration: '30000ms', environment: 'production' }
    },
    {
        id: 'log-010',
        timestamp: '2024-01-15 14:13:27',
        severity: 'warning',
        service: 'ecs-task',
        message: 'ECS task health check failed: Container unhealthy for 2 consecutive checks',
        source: 'ecs-task-definition',
        platform: 'cloudwatch',
        stackTrace: 'HealthCheck failed\n  Target: api-service:3000/health\n  Response: 503 Service Unavailable',
        context: { task_id: 'ecs-task-abc123', cluster: 'production-cluster', consecutive_failures: 2, environment: 'production' }
    },
    {
        id: 'log-011',
        timestamp: '2024-01-15 14:12:14',
        severity: 'error',
        service: 's3-sync',
        message: 'S3 PutObject failed: Access Denied for bucket grc-spend-uploads',
        source: 'app/services/storage/s3_uploader.rb:45',
        platform: 'cloudwatch',
        stackTrace: 'Aws::S3::Errors::AccessDenied: Access Denied\n  at S3Uploader.upload (app/services/storage/s3_uploader.rb:45)',
        context: { bucket: 'grc-spend-uploads', key: 'uploads/2024/file.pdf', size: '2.4MB', environment: 'production' }
    }
];

let currentLogs = [];
let selectedLogIds = new Set();

function searchLogs(event) {
    event.preventDefault();

    const platform = document.getElementById('log-platform').value;
    const project = document.getElementById('log-project').value;
    const severity = document.getElementById('log-severity').value;
    const startTime = document.getElementById('log-start-time').value;
    const endTime = document.getElementById('log-end-time').value;
    const searchQuery = document.getElementById('log-search').value;

    // Show loading state
    document.getElementById('logs-count-info').textContent = 'Searching...';
    addActivity('🔍', `Querying ${platform} API for logs...`);

    // Simulate API call delay
    setTimeout(() => {
        // Filter logs based on criteria
        currentLogs = sampleLogs.filter(log => {
            if (platform !== 'all' && log.platform !== platform) return false;
            if (severity !== 'all' && log.severity !== severity) return false;
            return true;
        });

        // Display results
        document.getElementById('logs-empty-state').style.display = 'none';
        document.getElementById('logs-results-container').style.display = 'block';
        document.getElementById('logs-count-info').textContent = `Found ${currentLogs.length} logs`;

        addActivity('✅', `Retrieved ${currentLogs.length} log entries from ${platform}`);

        renderLogsTable();
    }, 1500);
}

function renderLogsTable() {
    const tbody = document.getElementById('logs-table-body');
    if (!tbody) return; // Guard clause - element doesn't exist on this page

    tbody.innerHTML = '';

    currentLogs.forEach(log => {
        const row = document.createElement('tr');
        row.className = selectedLogIds.has(log.id) ? 'selected' : '';
        row.innerHTML = `
            <td><input type="checkbox" class="log-checkbox" data-log-id="${log.id}" ${selectedLogIds.has(log.id) ? 'checked' : ''} onchange="toggleLogSelection('${log.id}')"></td>
            <td><span class="log-timestamp">${log.timestamp}</span></td>
            <td><span class="log-severity ${log.severity}">${log.severity.toUpperCase()}</span></td>
            <td><span class="log-service">${log.service}</span></td>
            <td><span class="log-message">${log.message}</span></td>
            <td><span class="log-source">${log.source}</span></td>
            <td class="log-actions">
                <button class="log-action-btn" onclick="viewLogDetail('${log.id}')">👁️ View</button>
                <button class="log-action-btn" onclick="createTicketFromLog('${log.id}')">🎫 Ticket</button>
                <button class="log-action-btn" onclick="aiFixFromLog('${log.id}')">🤖 Fix</button>
            </td>
        `;
        tbody.appendChild(row);
    });
}

function resetLogsQuery() {
    document.getElementById('logs-query-form').reset();
    document.getElementById('logs-results-container').style.display = 'none';
    document.getElementById('logs-empty-state').style.display = 'block';
    document.getElementById('logs-count-info').textContent = 'Ready to search';
    currentLogs = [];
    selectedLogIds.clear();
}

function toggleLogSelection(logId) {
    if (selectedLogIds.has(logId)) {
        selectedLogIds.delete(logId);
    } else {
        selectedLogIds.add(logId);
    }
    renderLogsTable();
}

function toggleAllLogs(checkbox) {
    if (checkbox.checked) {
        currentLogs.forEach(log => selectedLogIds.add(log.id));
    } else {
        selectedLogIds.clear();
    }
    renderLogsTable();
}

function selectAllLogs() {
    currentLogs.forEach(log => selectedLogIds.add(log.id));
    renderLogsTable();
}

function viewLogDetail(logId) {
    const log = currentLogs.find(l => l.id === logId);
    if (!log) return;

    const modal = document.getElementById('log-detail-modal');
    const content = document.getElementById('log-detail-content');

    content.innerHTML = `
        <div class="log-detail-section">
            <h3>📋 Overview</h3>
            <div class="log-detail-grid">
                <span class="log-detail-label">Timestamp:</span>
                <span class="log-detail-value">${log.timestamp}</span>

                <span class="log-detail-label">Severity:</span>
                <span class="log-detail-value"><span class="log-severity ${log.severity}">${log.severity.toUpperCase()}</span></span>

                <span class="log-detail-label">Service:</span>
                <span class="log-detail-value">${log.service}</span>

                <span class="log-detail-label">Platform:</span>
                <span class="log-detail-value">${log.platform}</span>

                <span class="log-detail-label">Source:</span>
                <span class="log-detail-value">${log.source}</span>
            </div>
        </div>

        <div class="log-detail-section">
            <h3>💬 Message</h3>
            <p class="log-message-full">${log.message}</p>
        </div>

        <div class="log-detail-section">
            <h3>📚 Stack Trace</h3>
            <div class="log-stack-trace">${log.stackTrace}</div>
        </div>

        <div class="log-detail-section">
            <h3>🔍 Context</h3>
            <div class="log-detail-grid">
                ${Object.entries(log.context).map(([key, value]) => `
                    <span class="log-detail-label">${key}:</span>
                    <span class="log-detail-value">${value}</span>
                `).join('')}
            </div>
        </div>
    `;

    modal.classList.add('active');
    modal.dataset.currentLogId = logId;
}

function closeLogDetail() {
    document.getElementById('log-detail-modal').classList.remove('active');
}

function createTicketFromLog(logId) {
    const log = currentLogs.find(l => l.id === logId);
    if (!log) return;

    addActivity('📋', `Creating ADO ticket for: ${log.message.substring(0, 50)}...`);

    setTimeout(() => {
        const ticketNumber = 'AB#' + Math.floor(Math.random() * 900000 + 100000);
        addActivity('✅', `ADO ticket created: ${ticketNumber}`);
        alert(`ADO Ticket Created!\n\nTicket: ${ticketNumber}\nTitle: ${log.message}\nSeverity: ${log.severity}\nSource: ${log.source}`);
    }, 1000);
}

function aiFixFromLog(logId) {
    const log = currentLogs.find(l => l.id === logId);
    if (!log) return;

    addActivity('🤖', `AI analyzing log: ${log.message.substring(0, 50)}...`);

    setTimeout(() => {
        addActivity('🧠', 'AI identified root cause and generating fix...');
    }, 1000);

    setTimeout(() => {
        addActivity('✅', 'AI fix generated and PR created');
        const prNumber = Math.floor(Math.random() * 9000 + 1000);
        alert(`AI Auto-Fix Complete!\n\nLog: ${log.message}\n\nRoot Cause: ${log.message}\n\nFix: AI has generated a code fix\n\nPR Created: #${prNumber}\nConfidence: 87%\n\nThe fix is ready for review!`);
    }, 2500);
}

function aiFixLog() {
    const modal = document.getElementById('log-detail-modal');
    const logId = modal.dataset.currentLogId;
    closeLogDetail();
    aiFixFromLog(logId);
}

function bulkFixLogs() {
    if (selectedLogIds.size === 0) {
        alert('Please select at least one log entry to fix.');
        return;
    }

    addActivity('🤖', `Starting AI analysis for ${selectedLogIds.size} selected logs...`);

    setTimeout(() => {
        addActivity('🧠', 'AI analyzing logs and generating fixes...');
    }, 1000);

    setTimeout(() => {
        addActivity('✅', `${selectedLogIds.size} fixes generated, creating PRs...`);
    }, 2500);

    setTimeout(() => {
        alert(`Bulk AI Fix Complete!\n\n${selectedLogIds.size} logs processed\n${Math.floor(selectedLogIds.size * 0.8)} fixes generated\n${Math.floor(selectedLogIds.size * 0.8)} PRs created\n\nAverage confidence: 84%`);
        selectedLogIds.clear();
        renderLogsTable();
    }, 4000);
}

function exportLogs() {
    addActivity('📥', `Exporting ${currentLogs.length} logs to CSV...`);
    setTimeout(() => {
        addActivity('✅', 'Export complete: logs_export.csv');
        alert('Export Complete!\n\nFile: logs_export.csv\nRecords: ' + currentLogs.length + '\n\nDownload started.');
    }, 1000);
}

function loadPreviousLogs() {
    addActivity('🔄', 'Loading previous page...');
}

function loadNextLogs() {
    addActivity('🔄', 'Loading next page...');
}

// Alert Rules Management
function openCreateAlertRule() {
    const modal = document.getElementById('create-alert-rule-modal');
    document.getElementById('alert-rule-modal-title').textContent = '➕ Create New Alert Rule';
    document.getElementById('alert-rule-form').reset();
    modal.classList.add('active');
}

function closeCreateAlertRule() {
    document.getElementById('create-alert-rule-modal').classList.remove('active');
}

function editAlertRule(ruleId) {
    const modal = document.getElementById('create-alert-rule-modal');
    document.getElementById('alert-rule-modal-title').textContent = '✏️ Edit Alert Rule';

    // Pre-fill form with existing rule data (mock data for demo)
    if (ruleId === 'api-response') {
        document.getElementById('rule-name').value = 'Critical: API Response Time';
        document.getElementById('rule-severity').value = 'critical';
        document.getElementById('metric-type').value = 'response-time';
        document.getElementById('threshold-value').value = '1000';
        document.getElementById('threshold-unit').value = 'ms';
        document.getElementById('duration').value = '5 minutes';
    }

    modal.classList.add('active');
}

function saveAlertRule(event) {
    event.preventDefault();

    const ruleName = document.getElementById('rule-name').value;
    const severity = document.getElementById('rule-severity').value;
    const metricType = document.getElementById('metric-type').value;
    const threshold = document.getElementById('threshold-value').value;
    const unit = document.getElementById('threshold-unit').value;

    // Get selected platforms
    const selectedPlatforms = Array.from(document.querySelectorAll('input[name="platforms"]:checked'))
        .map(cb => cb.value);

    // Get selected projects
    const allProjects = document.getElementById('all-projects').checked;
    const selectedProjects = allProjects ? ['all'] :
        Array.from(document.querySelectorAll('input[name="projects"]:checked'))
            .map(cb => cb.value);

    addActivity('✅', `Alert rule "${ruleName}" created successfully`);
    addActivity('🔄', `Deploying rule to ${selectedPlatforms.length} platform(s)...`);

    setTimeout(() => {
        addActivity('📊', `Rule deployed to Datadog`);
    }, 1000);

    setTimeout(() => {
        addActivity('📈', `Rule deployed to New Relic`);
    }, 1500);

    setTimeout(() => {
        addActivity('✅', `Alert rule is now active across all platforms`);
        closeCreateAlertRule();

        // Show success message
        alert(`Alert Rule Created Successfully!\n\n` +
              `Rule: ${ruleName}\n` +
              `Severity: ${severity.toUpperCase()}\n` +
              `Condition: ${metricType} > ${threshold}${unit}\n` +
              `Platforms: ${selectedPlatforms.join(', ')}\n` +
              `Projects: ${allProjects ? 'All Projects' : selectedProjects.join(', ')}\n\n` +
              `The rule has been automatically created in all selected observability platforms.`);
    }, 2000);
}

function toggleAllProjects(checkbox) {
    const projectCheckboxes = document.getElementById('project-checkboxes');
    const projectInputs = document.querySelectorAll('input[name="projects"]');

    if (checkbox.checked) {
        // Disable individual project selection
        projectCheckboxes.style.opacity = '0.5';
        projectCheckboxes.style.pointerEvents = 'none';
        projectInputs.forEach(input => {
            input.checked = true;
            input.disabled = true;
        });
    } else {
        // Enable individual project selection
        projectCheckboxes.style.opacity = '1';
        projectCheckboxes.style.pointerEvents = 'auto';
        projectInputs.forEach(input => {
            input.disabled = false;
        });
    }
}

// Initialize date/time fields for logs explorer
function initializeLogsExplorer() {
    const now = new Date();
    const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);

    const formatDateTime = (date) => {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const hours = String(date.getHours()).padStart(2, '0');
        const minutes = String(date.getMinutes()).padStart(2, '0');
        return `${year}-${month}-${day}T${hours}:${minutes}`;
    };

    const startTimeInput = document.getElementById('log-start-time');
    const endTimeInput = document.getElementById('log-end-time');

    if (startTimeInput) {
        startTimeInput.value = formatDateTime(oneHourAgo);
    }
    if (endTimeInput) {
        endTimeInput.value = formatDateTime(now);
    }
}

// Initialize projects list when switching to projects tab
document.addEventListener('DOMContentLoaded', function() {
    renderProjectsList();
    startActivityFeed();
    initializeLogsExplorer();
});
