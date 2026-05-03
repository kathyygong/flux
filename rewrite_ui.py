import os

html_path = '/Users/kathygong/flux/app/static/index.html'
css_path = '/Users/kathygong/flux/app/static/index.css'

new_css = """@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');

:root {
    --bg-color: #F5F5F7;
    --surface-color: rgba(255, 255, 255, 0.85);
    --surface-solid: #FFFFFF;
    --primary-color: #0071e3;
    --primary-hover: #0077ed;
    --accent-color: #FF3B30;
    --text-color: #1D1D1F;
    --text-muted: #86868B;
    --success-color: #34C759;
    --warning-color: #FF9F0A;
    --danger-color: #FF3B30;
    --card-radius: 24px;
    --shadow-soft: 0 8px 32px rgba(0, 0, 0, 0.04);
    --shadow-hover: 0 12px 48px rgba(0, 0, 0, 0.08);
    --border-subtle: 1px solid rgba(0, 0, 0, 0.04);
}

* { box-sizing: border-box; margin: 0; padding: 0; }

body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    background-color: var(--bg-color);
    color: var(--text-color);
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    /* Soft animated mesh background */
    background: radial-gradient(circle at top left, #E2E2E8 0%, #F5F5F7 40%, #FFFFFF 100%);
    background-attachment: fixed;
}

#app { height: 100vh; display: flex; flex-direction: row; overflow: hidden; }

/* Glassy Sidebar */
.sidebar {
    width: 280px;
    background: rgba(245, 245, 247, 0.6);
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    border-right: var(--border-subtle);
    display: flex;
    flex-direction: column;
    z-index: 100;
}

.sidebar-header {
    padding: 2.5rem 1.5rem 1.5rem;
    display: flex;
    align-items: center;
    gap: 0.75rem;
}

.logo-box {
    background: linear-gradient(135deg, var(--primary-color), #409CFF);
    color: white;
    padding: 0.5rem;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px rgba(0, 113, 227, 0.3);
}

.sidebar-header h1 { font-size: 1.5rem; font-weight: 800; letter-spacing: -0.03em; }

.sidebar-nav {
    flex: 1; padding: 0 1rem; display: flex; flex-direction: column; gap: 0.5rem;
}

.nav-item {
    display: flex; align-items: center; gap: 1rem; padding: 0.85rem 1.25rem;
    background: transparent; border: none; border-radius: 14px;
    font-family: inherit; font-size: 1rem; font-weight: 500;
    color: var(--text-muted); cursor: pointer; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.nav-item:hover { background: rgba(0,0,0,0.03); color: var(--text-color); }

.nav-item.active {
    background: var(--surface-solid);
    color: var(--primary-color);
    font-weight: 600;
    box-shadow: 0 2px 10px rgba(0,0,0,0.02);
}

.sidebar-footer { padding: 1.5rem; border-top: var(--border-subtle); }

.race-info { margin-bottom: 1.5rem; }
.race-name { font-size: 0.9rem; font-weight: 700; }
.race-days { font-size: 0.8rem; color: var(--text-muted); margin-top: 0.25rem; font-weight: 500; }

.user-profile-row { display: flex; align-items: center; gap: 1rem; cursor: pointer; }
.sidebar-user-name { font-size: 0.95rem; font-weight: 600; }

.global-profile-btn {
    width: 44px; height: 44px; border-radius: 50%;
    background-color: #E2E2E8; color: var(--text-color);
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 1.1rem;
    box-shadow: inset 0 0 0 1px rgba(0,0,0,0.05);
    background-size: cover; background-position: center;
}

/* Main Content Area */
.main-container {
    flex: 1; overflow-y: auto; padding: 3rem;
}

.dashboard { max-width: 1100px; margin: 0 auto; width: 100%; display: flex; flex-direction: column; gap: 2rem; }

/* Premium Cards */
.card-base {
    background: var(--surface-solid);
    border: none;
    border-radius: var(--card-radius);
    box-shadow: var(--shadow-soft);
    padding: 2rem;
    transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), box-shadow 0.3s ease;
}

.card-base:hover { box-shadow: var(--shadow-hover); transform: translateY(-2px); }

/* Typography inside cards */
.card-header h2 { font-size: 1.5rem; font-weight: 700; letter-spacing: -0.02em; margin-bottom: 0.5rem; }
.date-badge { font-size: 0.9rem; font-weight: 600; color: var(--primary-color); background: rgba(0,113,227,0.1); padding: 0.25rem 0.75rem; border-radius: 20px; }

/* Apple-style Widget Grid */
.stats-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.5rem;
}

.stat-card {
    background: #F9F9FB;
    border-radius: 20px;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

.stat-header { font-size: 0.85rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
.stat-value { font-size: 2.5rem; font-weight: 800; color: var(--text-color); letter-spacing: -0.04em; line-height: 1.1; }
.stat-subtitle { font-size: 0.9rem; font-weight: 500; margin-top: 0.5rem; color: var(--text-muted); }

/* Colors */
.text-success { color: var(--success-color); }
.text-warning { color: var(--warning-color); }
.text-danger { color: var(--danger-color); }

/* Buttons */
.btn {
    padding: 1rem 2rem; border-radius: 30px; font-weight: 600; font-size: 1rem;
    cursor: pointer; border: none; transition: all 0.2s ease;
    font-family: inherit; display: inline-flex; align-items: center; justify-content: center;
}
.btn.primary { background: var(--primary-color); color: #fff; box-shadow: 0 4px 14px rgba(0, 113, 227, 0.3); }
.btn.primary:hover { transform: scale(1.02); box-shadow: 0 6px 20px rgba(0, 113, 227, 0.4); }
.btn.secondary { background: #E5E5EA; color: var(--text-color); }
.btn.secondary:hover { background: #D1D1D6; }

/* Plan / Calendar Heatmap */
.calendar-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 0.75rem; margin-top: 1.5rem; }
.calendar-header { text-align: center; font-size: 0.8rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; }
.calendar-cell {
    aspect-ratio: 1; border-radius: 12px; background-color: #F0F0F5;
    display: flex; align-items: center; justify-content: center;
    font-size: 0.9rem; font-weight: 600; color: var(--text-muted);
    transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.calendar-cell.original { background: linear-gradient(135deg, #34C759, #30D158); color: white; box-shadow: 0 2px 8px rgba(52, 199, 89, 0.2); }
.calendar-cell.adapted { background: linear-gradient(135deg, #FF9F0A, #FFB340); color: white; }
.calendar-cell.skipped { background: #FFD6D6; color: #FF3B30; }
.calendar-cell.empty { background: transparent; }
.calendar-cell:hover:not(.empty) { transform: scale(1.1); z-index: 10; }

/* AI Proposal */
.proposal-card {
    background: linear-gradient(135deg, #ffffff, #fcfaff);
    border: 1px solid rgba(139, 92, 246, 0.2);
    box-shadow: 0 8px 32px rgba(139, 92, 246, 0.1);
}
.proposal-header h3 { background: linear-gradient(135deg, var(--accent-color), #8B5CF6); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }

/* Utilities */
.hidden { display: none !important; }
.mb-4 { margin-bottom: 2rem; }
.mt-4 { margin-top: 2rem; }

/* Tabs */
.tab-content { display: none; animation: fadeIn 0.4s ease; }
.tab-content.active { display: block; }
@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

/* Recovery summary */
.recovery-metric { background: #F9F9FB; border-radius: 20px; padding: 1.5rem; display: flex; flex-direction: column; align-items: center; text-align: center; }
.rm-label { font-size: 0.85rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
.rm-val { font-size: 2.5rem; font-weight: 800; color: var(--text-color); margin-bottom: 0.25rem; }

/* Plan View */
.plan-swipe-container { display: flex; align-items: center; justify-content: space-between; padding: 1rem 0; }
.swipe-btn { background: #F5F5F7; border: none; border-radius: 50%; width: 48px; height: 48px; font-size: 1.5rem; cursor: pointer; color: var(--text-color); transition: all 0.2s ease; }
.swipe-btn:hover { background: #E5E5EA; transform: scale(1.05); }
.plan-day-view { flex: 1; text-align: center; padding: 0 2rem; }
.workout-type { display: inline-block; padding: 0.4rem 1rem; background: rgba(0,113,227,0.1); color: var(--primary-color); border-radius: 20px; font-size: 0.85rem; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 1rem; }
.workout-title { font-size: 2.5rem; font-weight: 800; letter-spacing: -0.03em; margin-bottom: 1rem; }
.workout-desc { color: var(--text-muted); font-size: 1.1rem; line-height: 1.6; }

/* Weekly List */
.weekly-summary-list { display: flex; flex-direction: column; gap: 1rem; }
.weekly-summary-item { background: #F9F9FB; border-radius: 20px; padding: 1.5rem; display: flex; align-items: center; gap: 1.5rem; transition: transform 0.2s ease; }
.weekly-summary-item:hover { transform: scale(1.01); background: #ffffff; box-shadow: 0 4px 20px rgba(0,0,0,0.04); }
.weekly-summary-icon { width: 56px; height: 56px; background: rgba(0,113,227,0.1); color: var(--primary-color); border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 1.75rem; }
.weekly-summary-title { font-size: 1.1rem; font-weight: 700; color: var(--text-color); }
.weekly-summary-desc { font-size: 0.95rem; color: var(--text-muted); margin-top: 0.25rem; font-weight: 500; }

/* Auth Overlay */
.auth-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(245, 245, 247, 0.8); backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px); display: flex; align-items: center; justify-content: center; z-index: 9999; }
.auth-card { background: #fff; padding: 3rem; width: 100%; max-width: 440px; border-radius: 24px; box-shadow: 0 12px 48px rgba(0,0,0,0.1); text-align: center; }
.form-control { width: 100%; padding: 1rem 1.25rem; border: 1px solid rgba(0,0,0,0.1); border-radius: 16px; font-family: inherit; font-size: 1.05rem; background: #F9F9FB; transition: all 0.2s ease; margin-bottom: 1rem; }
.form-control:focus { outline: none; border-color: var(--primary-color); box-shadow: 0 0 0 4px rgba(0,113,227,0.1); background: #fff; }

.settings-row { display: flex; justify-content: space-between; align-items: center; padding: 1.5rem 0; border-bottom: 1px solid rgba(0,0,0,0.05); }
.settings-info h4 { font-size: 1.1rem; font-weight: 600; }
.settings-info p { color: var(--text-muted); margin-top: 0.25rem; }
"""

with open(css_path, 'w') as f:
    f.write(new_css)
