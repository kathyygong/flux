let userId = localStorage.getItem('flux_user_id');
let userEmail = localStorage.getItem('flux_user_email');

document.addEventListener("DOMContentLoaded", () => {
    console.log("Flux UI Dashboard initialized");

    // Check URL for Google Auth redirect
    const urlParams = new URLSearchParams(window.location.search);
    const authUserId = urlParams.get('user_id');
    const authEmail = urlParams.get('email');
    const authFullName = urlParams.get('full_name');
    const authIsNew = urlParams.get('is_new') === 'true';

    if (authUserId) {
        // We just came back from Google Auth
        userId = authUserId;
        userEmail = authEmail;
        localStorage.setItem('flux_user_id', userId);
        localStorage.setItem('flux_user_email', userEmail);
        
        // Clean URL
        window.history.replaceState({}, document.title, "/");
        
        document.getElementById('auth-overlay').classList.add('hidden');
        
        if (authIsNew || !authFullName) {
            showBioOverlay();
        } else {
            initDashboard();
        }
        return;
    }

    if (!userId) {
        document.getElementById('auth-overlay').classList.remove('hidden');
        
        let isLogin = false;
        const btnSignup = document.getElementById('tab-btn-signup');
        const btnLogin = document.getElementById('tab-btn-login');
        const submitBtn = document.getElementById('auth-submit');
        
        const authPasswordInput = document.getElementById('auth-password');
        
        btnSignup.addEventListener('click', () => {
            isLogin = false;
            btnSignup.classList.add('active');
            btnLogin.classList.remove('active');
            submitBtn.innerText = 'Sign Up';
            authPasswordInput.autocomplete = 'new-password';
        });
        
        btnLogin.addEventListener('click', () => {
            isLogin = true;
            btnLogin.classList.add('active');
            btnSignup.classList.remove('active');
            submitBtn.innerText = 'Log In';
            authPasswordInput.autocomplete = 'current-password';
        });
        
        // Handle Real Google Auth
        document.getElementById('auth-google-btn').addEventListener('click', () => {
            window.location.href = '/api/v1/auth/google/login';
        });
        
        document.getElementById('auth-form').addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('auth-email').value;
            const password = authPasswordInput.value;
            
            if (!email || !password) return alert('Please fill in all fields');
            
            const endpoint = isLogin ? '/api/v1/auth/login' : '/api/v1/auth/signup';
            const payload = {email, password};
            
            try {
                const res = await fetch(endpoint, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(payload)
                });
                const data = await res.json();
                if (data.status === 'success') {
                    handleAuthSuccess(data.data);
                } else {
                    alert(data.detail || 'Authentication failed');
                }
            } catch (err) {
                console.error("Auth failed", err);
            }
        });
        
        function handleAuthSuccess(userData) {
            userId = userData.id;
            userEmail = userData.email;
            localStorage.setItem('flux_user_id', userId);
            localStorage.setItem('flux_user_email', userEmail);
            document.getElementById('auth-overlay').classList.add('hidden');
            
            if (!userData.full_name) {
                showBioOverlay();
            } else {
                initDashboard();
            }
        }
        
    } else {
        initDashboard();
    }
});

let base64ProfilePic = null;

function showBioOverlay() {
    const bioOverlay = document.getElementById('bio-overlay');
    bioOverlay.classList.remove('hidden');
    
    document.getElementById('bio-pic-input').addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (ev) => {
                base64ProfilePic = ev.target.result;
                document.getElementById('bio-avatar-preview').style.backgroundImage = `url(${base64ProfilePic})`;
                document.getElementById('bio-avatar-placeholder').style.display = 'none';
            };
            reader.readAsDataURL(file);
        }
    });
    
    document.getElementById('bio-submit').addEventListener('click', async () => {
        const name = document.getElementById('bio-name').value;
        if (!name) return alert('Please enter your name');
        
        try {
            await fetch(`/api/v1/auth/profile/${userId}`, {
                method: 'PUT',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    full_name: name,
                    profile_picture: base64ProfilePic
                })
            });
            bioOverlay.classList.add('hidden');
            initDashboard();
        } catch (e) {
            console.error("Bio update failed", e);
        }
    });
}

function initDashboard() {
    // Set settings info
    if (userEmail) {
        document.getElementById('settings-email').innerText = userEmail;
    }

    document.getElementById('logout-btn').addEventListener('click', () => {
        localStorage.removeItem('flux_user_id');
        localStorage.removeItem('flux_user_email');
        window.location.reload();
    });

    // Format current date
    const today = new Date();
    const options = { month: 'short', day: 'numeric' };
    document.getElementById('today-date').innerText = today.toLocaleDateString('en-US', options);

    // Initialize Chart
    initChart();

    // Fetch dashboard data
    fetchDashboardData();
    
    // Setup Tabs Navigation
    setupTabs();
    
    // Fetch plan and recovery data
    fetchPlanData();
    fetchRecoveryData();
    fetchTrainingLogData();
    setupPlanBuilder();
}

function initChart() {
    const ctx = document.getElementById('mileage-chart').getContext('2d');
    
    // Start with empty data — will be populated from dashboard API
    window.mileageChartInstance = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Completed Sessions',
                data: [],
                borderColor: '#0071E3',
                backgroundColor: 'rgba(0, 113, 227, 0.1)',
                borderWidth: 3,
                tension: 0.4,
                fill: true,
                pointBackgroundColor: '#ffffff',
                pointBorderColor: '#0071E3',
                pointBorderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: 'rgba(255, 255, 255, 0.95)',
                    titleColor: '#1D1D1F',
                    bodyColor: '#1D1D1F',
                    borderColor: 'rgba(0, 0, 0, 0.05)',
                    borderWidth: 1,
                    padding: 10,
                    cornerRadius: 8,
                    displayColors: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: { color: 'rgba(0, 0, 0, 0.05)' },
                    ticks: { color: '#86868b', stepSize: 1 }
                },
                x: {
                    grid: { display: false },
                    ticks: { color: '#86868b' }
                }
            }
        }
    });
}

let currentUserData = null;

async function fetchDashboardData() {
    if (!userId) return;
    try {
        // Fetch dashboard data for user
        const response = await fetch(`/api/v1/dashboard/${userId}`);
        const json = await response.json();
        
        if (json.status !== 'success') {
            console.error("Dashboard error", json.detail);
            return;
        }
        
        const data = json.data;
        currentUserData = data.user;
        
        // Render global profile btn and sidebar profile
        const profileBtn = document.getElementById('global-profile-btn');
        profileBtn.classList.remove('hidden');
        if (data.user.profile_picture) {
            profileBtn.style.backgroundImage = `url(${data.user.profile_picture})`;
            profileBtn.innerHTML = '';
        } else {
            const initials = data.user.full_name ? data.user.full_name.split(' ').map(n=>n[0]).join('').substring(0,2).toUpperCase() : '?';
            profileBtn.style.backgroundImage = 'none';
            profileBtn.innerText = initials;
        }
        
        const sidebarUserName = document.getElementById('sidebar-user-name');
        if (sidebarUserName) {
            sidebarUserName.innerText = data.user.full_name || data.user.email;
        }
        
        // Dynamic Greeting
        const hour = new Date().getHours();
        let greeting = "Good evening";
        if (hour < 12) greeting = "Good morning";
        else if (hour < 18) greeting = "Good afternoon";
        
        const firstName = data.user.full_name ? data.user.full_name.split(' ')[0] : 'Runner';
        const greetingEl = document.getElementById('greeting-text');
        if (greetingEl) greetingEl.innerText = `${greeting}, ${firstName}!`;
        
        // AI Insight
        const insightEl = document.getElementById('insight-text');
        if (insightEl) {
            if (data.readiness && data.readiness.score >= 80) {
                insightEl.innerText = "Recovery is optimal. Push hard on today's session!";
            } else if (data.readiness && data.readiness.score <= 50) {
                insightEl.innerText = "Your body needs rest. Prioritize active recovery today.";
            } else {
                insightEl.innerText = "You're doing great. Stay consistent with the plan.";
            }
        }
        
        // Setup Profile Edit Page
        setupProfileEditPage();

        // Update top-level metrics
        document.getElementById('readiness-score').innerText = `${data.readiness.score}%`;
        const readinessSubtitle = document.getElementById('readiness-subtitle');
        readinessSubtitle.innerText = data.readiness.label;
        readinessSubtitle.className = `stat-subtitle ${data.readiness.colorClass}`;
        document.getElementById('completion-pct').innerText = `${data.completion_pct}%`;
        document.getElementById('current-streak').innerText = `${data.streak} Days`;
        
        // Update Sidebar Plan Meta
        const goalNameEl = document.getElementById('sidebar-goal-name');
        const goalDaysEl = document.getElementById('sidebar-goal-days');
        const overviewNameEl = document.getElementById('plan-overview-name');
        const overviewDaysEl = document.getElementById('plan-overview-days');
        
        if (data.plan_meta) {
            goalNameEl.innerText = data.plan_meta.goal;
            if (overviewNameEl) overviewNameEl.innerText = `${data.plan_meta.goal} Plan`;
            
            if (data.plan_meta.target_date) {
                const targetDate = new Date(data.plan_meta.target_date);
                const diffTime = targetDate - new Date();
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                const daysStr = `${Math.max(0, diffDays)} days to go`;
                goalDaysEl.innerText = daysStr;
                if (overviewDaysEl) overviewDaysEl.innerText = daysStr.replace('to go', 'left');
            } else {
                goalDaysEl.innerText = 'No target date';
                if (overviewDaysEl) overviewDaysEl.innerText = 'No target date';
            }
        } else {
            goalNameEl.innerText = 'No Goal Active';
            goalDaysEl.innerText = 'Go to Plan settings';
            if (overviewNameEl) overviewNameEl.innerText = 'No Active Plan';
        }

        // Populate Today's Plan
        if (data.todays_plan) {
            document.getElementById('workout-type').innerText = data.todays_plan.type;
            document.getElementById('workout-title').innerText = data.todays_plan.title;
            document.getElementById('workout-desc').innerText = data.todays_plan.description;
            document.getElementById('workout-meta').style.display = 'flex';
            document.getElementById('workout-duration').innerText = `${data.todays_plan.duration} mins`;
            
            const completeBtn = document.getElementById('mark-complete-btn');
            if (completeBtn) {
                if (data.todays_plan.status === 'completed') {
                    completeBtn.innerText = 'Completed ✓';
                    completeBtn.disabled = true;
                    completeBtn.classList.add('secondary');
                    completeBtn.classList.remove('primary');
                } else {
                    completeBtn.innerText = 'Mark Complete';
                    completeBtn.disabled = false;
                    completeBtn.classList.add('primary');
                    completeBtn.classList.remove('secondary');
                    
                    // Add click handler (replace clone to remove old listeners)
                    const newBtn = completeBtn.cloneNode(true);
                    completeBtn.parentNode.replaceChild(newBtn, completeBtn);
                    
                    newBtn.addEventListener('click', async () => {
                        await fetch(`/api/v1/dashboard/activity/${data.todays_plan.id}/complete`, {
                            method: 'POST'
                        });
                        
                        // Fire Confetti!
                        if (typeof confetti !== 'undefined') {
                            confetti({
                                particleCount: 150,
                                spread: 80,
                                origin: { y: 0.6 },
                                colors: ['#0071e3', '#34C759', '#FF9F0A', '#FF3B30']
                            });
                        }
                        
                        newBtn.innerText = 'Completed ✓';
                        newBtn.disabled = true;
                        newBtn.classList.add('secondary');
                        newBtn.classList.remove('primary');
                        
                        setTimeout(fetchDashboardData, 1500);
                    });
                }
            }
        } else {
            document.getElementById('workout-type').innerText = 'Rest Day';
            document.getElementById('workout-title').innerText = 'Recovery';
            document.getElementById('workout-desc').innerText = 'No workout scheduled for today. Focus on mobility and hydration.';
            document.getElementById('workout-meta').style.display = 'none';
            
            const completeBtn = document.getElementById('mark-complete-btn');
            if (completeBtn) completeBtn.style.display = 'none';
        }

        // Handle AI Proposal
        if (data.ai_proposal && data.ai_proposal.exists) {
            const proposalContainer = document.getElementById('ai-proposal-container');
            document.getElementById('proposal-reason').innerText = data.ai_proposal.reason;
            proposalContainer.classList.remove('hidden');

            const acceptBtn = document.getElementById('accept-proposal');
            const newAccept = acceptBtn.cloneNode(true);
            acceptBtn.parentNode.replaceChild(newAccept, acceptBtn);
            
            newAccept.addEventListener('click', async () => {
                await fetch(`/api/v1/dashboard/proposal/${data.ai_proposal.id}/action`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: 'accept' })
                });

                // Update UI to reflect the change
                document.getElementById('workout-title').innerText = data.ai_proposal.suggestion;
                
                const workoutDetails = document.getElementById('todays-workout');
                workoutDetails.style.opacity = 0;
                setTimeout(() => {
                    workoutDetails.style.transition = 'opacity 0.4s ease';
                    workoutDetails.style.opacity = 1;
                }, 50);

                proposalContainer.classList.add('hidden');
                fetchDashboardData(); // Refresh data from backend
            });

            const declineBtn = document.getElementById('decline-proposal');
            const newDecline = declineBtn.cloneNode(true);
            declineBtn.parentNode.replaceChild(newDecline, declineBtn);
            
            newDecline.addEventListener('click', async () => {
                await fetch(`/api/v1/dashboard/proposal/${data.ai_proposal.id}/action`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ action: 'reject' })
                });
                proposalContainer.classList.add('hidden');
            });
        }

        // Handle Resiliency Dashboard
        if (data.resiliency) {
            const total = data.resiliency.original_count + data.resiliency.adapted_count + data.resiliency.skipped_count;
            if (total > 0) {
                const origPct = Math.round((data.resiliency.original_count / total) * 100);
                const adaptPct = Math.round((data.resiliency.adapted_count / total) * 100);
                const skipPct = Math.round((data.resiliency.skipped_count / total) * 100);
                
                document.getElementById('stat-original').innerText = `${origPct}%`;
                document.getElementById('stat-saved').innerText = `${adaptPct}%`;
                document.getElementById('stat-skipped').innerText = `${skipPct}%`;
                
                // Resiliency Score for Plan Overview
                const resilPct = Math.round(((data.resiliency.original_count + data.resiliency.adapted_count) / total) * 100);
                const overviewResilEl = document.getElementById('plan-overview-resiliency');
                if (overviewResilEl) overviewResilEl.innerText = `${resilPct}%`;
            } else {
                document.getElementById('stat-original').innerText = '0%';
                document.getElementById('stat-saved').innerText = '0%';
                document.getElementById('stat-skipped').innerText = '0%';
                const overviewResilEl = document.getElementById('plan-overview-resiliency');
                if (overviewResilEl) overviewResilEl.innerText = '100%';
            }
        }
        
        // Plan Overview: Weeks & Progress from plan_meta
        if (data.plan_meta) {
            const completedWeeks = data.plan_meta.completed_weeks || 0;
            const totalWeeks = data.plan_meta.total_weeks || 1;
            
            const overviewWeeksEl = document.getElementById('plan-overview-weeks');
            if (overviewWeeksEl) overviewWeeksEl.innerText = `${completedWeeks} / ${totalWeeks}`;
            
            const progPct = Math.min(100, Math.round((completedWeeks / totalWeeks) * 100));
            const progFill = document.getElementById('plan-progress-fill');
            const progText = document.getElementById('plan-progress-text');
            const progWeeks = document.getElementById('plan-progress-weeks-label');
            
            if (progFill) progFill.style.width = `${progPct}%`;
            if (progText) progText.innerText = `${progPct}% Completed`;
            if (progWeeks) progWeeks.innerText = `Week ${completedWeeks} of ${totalWeeks}`;
        }
        
        // Mileage Chart — update from real data
        if (data.weekly_mileage && window.mileageChartInstance) {
            window.mileageChartInstance.data.labels = data.weekly_mileage.labels;
            window.mileageChartInstance.data.datasets[0].data = data.weekly_mileage.data;
            window.mileageChartInstance.update();
        }

        // Heatmap Calendar
        if (data.resiliency && data.resiliency.heatmap) {
            const heatmapContainer = document.getElementById('heatmap');
            heatmapContainer.innerHTML = '';
            
            const stateMap = {};
            data.resiliency.heatmap.forEach(cell => {
                stateMap[cell.date] = cell.state;
            });
            
            const now = new Date();
            const year = now.getFullYear();
            const month = now.getMonth();
            
            document.getElementById('calendar-month').innerText = now.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
            
            const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
            weekdays.forEach(day => {
                const div = document.createElement('div');
                div.className = 'calendar-header';
                div.innerText = day;
                heatmapContainer.appendChild(div);
            });
            
            const firstDay = new Date(year, month, 1).getDay();
            const daysInMonth = new Date(year, month + 1, 0).getDate();
            
            for (let i = 0; i < firstDay; i++) {
                const div = document.createElement('div');
                div.className = 'calendar-cell empty';
                heatmapContainer.appendChild(div);
            }
            
            for (let i = 1; i <= daysInMonth; i++) {
                const dateStr = `${year}-${String(month+1).padStart(2, '0')}-${String(i).padStart(2, '0')}`;
                const div = document.createElement('div');
                div.className = 'calendar-cell';
                div.innerText = i;
                
                if (stateMap[dateStr]) {
                    div.classList.add(stateMap[dateStr]);
                }
                
                heatmapContainer.appendChild(div);
            }
        }
        
        // Training Log — render from real data
        if (data.training_log) {
            renderTrainingLogFromAPI(data.training_log);
        }

        // Setup Tabs Navigation
        setupTabs();
        
        // Fetch plan and recovery data
        fetchPlanData();
        fetchRecoveryData();

    } catch (error) {
        console.error("Error fetching dashboard data:", error);
    }
}

function setupTabs() {
    const navItems = document.querySelectorAll('.nav-item');
    const tabs = document.querySelectorAll('.tab-content');

    navItems.forEach(item => {
        item.addEventListener('click', () => {
            // Remove active from all nav and tabs
            navItems.forEach(n => n.classList.remove('active'));
            tabs.forEach(t => t.classList.remove('active'));

            // Add active to clicked nav and target tab
            item.classList.add('active');
            const targetId = item.getAttribute('data-tab');
            document.getElementById(targetId).classList.add('active');
        });
    });
}

let planActivities = [];
let currentPlanIndex = 0;

async function fetchPlanData() {
    if (!userId) return;
    try {
        const response = await fetch(`/api/v1/dashboard/${userId}`);
        const json = await response.json();
        
        if (json.data.plan_activities && json.data.plan_activities.length > 0) {
            planActivities = json.data.plan_activities.map(a => ({
                ...a,
                date: new Date(a.date)
            }));
        } else {
            // Fallback mock
            const today = new Date();
            planActivities = [
                { type: "Run", title: "Intervals", desc: "6x800m at 5k pace", duration: "60", date: new Date(today.getTime() - 86400000) },
                { type: "Recovery", title: "Rest Day", desc: "Mobility and hydration", duration: "0", date: today },
                { type: "Run", title: "Tempo Run", desc: "20 min warm up, 30 min tempo, 10 min cool down", duration: "60", date: new Date(today.getTime() + 86400000) },
                { type: "Run", title: "Long Run", desc: "10 miles steady pace", duration: "90", date: new Date(today.getTime() + 86400000*2) },
            ];
        }
        
        currentPlanIndex = 0; // Start at the closest to today
        const todayStr = new Date().toDateString();
        const todayIndex = planActivities.findIndex(a => a.date.toDateString() === todayStr);
        if (todayIndex !== -1) currentPlanIndex = todayIndex;
        
        renderPlanDay();
        
        // Remove old listeners to prevent stacking
        const prevBtn = document.getElementById('plan-prev');
        const nextBtn = document.getElementById('plan-next');
        const newPrev = prevBtn.cloneNode(true);
        const newNext = nextBtn.cloneNode(true);
        prevBtn.parentNode.replaceChild(newPrev, prevBtn);
        nextBtn.parentNode.replaceChild(newNext, nextBtn);
        
        newPrev.addEventListener('click', () => {
            if (currentPlanIndex > 0) { currentPlanIndex--; renderPlanDay(); }
        });
        newNext.addEventListener('click', () => {
            if (currentPlanIndex < planActivities.length - 1) { currentPlanIndex++; renderPlanDay(); }
        });
        
        renderWeeklySummary();
        
    } catch (e) { console.error("Error plan data", e); }
}

function renderPlanDay() {
    if (planActivities.length === 0) return;
    const act = planActivities[currentPlanIndex];
    document.getElementById('plan-type').innerText = act.type || 'Workout';
    document.getElementById('plan-title').innerText = act.title || 'Session';
    document.getElementById('plan-desc').innerText = act.description || act.desc || '';
    document.getElementById('plan-date-display').innerText = act.date.toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' });
}

function renderWeeklySummary() {
    const container = document.getElementById('weekly-summary-list');
    if (!container) return;
    container.innerHTML = '';
    
    if (planActivities.length === 0) {
        container.innerHTML = '<p class="workout-desc">No upcoming workouts.</p>';
        return;
    }

    // Group activities by week
    const weeks = [];
    let currentWeek = [];
    
    planActivities.forEach((act, index) => {
        currentWeek.push(act);
        // Break into new week every 7 days or at the end
        if (currentWeek.length === 7 || index === planActivities.length - 1) {
            weeks.push([...currentWeek]);
            currentWeek = [];
        }
    });

    weeks.forEach((week, i) => {
        // Find longest run or key workout of the week
        let keyWorkout = week[0];
        let totalMins = 0;
        let runCount = 0;
        
        week.forEach(act => {
            const dur = parseInt(act.duration) || 0;
            totalMins += dur;
            if (act.type && act.type.toLowerCase().includes('run')) runCount++;
            
            if (dur > (parseInt(keyWorkout.duration) || 0)) {
                keyWorkout = act;
            }
        });
        
        const summaryItem = document.createElement('div');
        summaryItem.className = 'weekly-summary-item';
        
        const iconDiv = document.createElement('div');
        iconDiv.className = 'weekly-summary-icon';
        iconDiv.innerText = i === 0 ? '🔥' : '🏃'; // highlight current week
        
        const detailsDiv = document.createElement('div');
        detailsDiv.className = 'weekly-summary-details';
        
        const titleDiv = document.createElement('div');
        titleDiv.className = 'weekly-summary-title';
        titleDiv.innerText = `Week ${i + 1}`;
        
        const descDiv = document.createElement('div');
        descDiv.className = 'weekly-summary-desc';
        descDiv.innerText = `${runCount} runs • ${Math.round(totalMins/60)} hrs • Key: ${keyWorkout.title}`;
        
        detailsDiv.appendChild(titleDiv);
        detailsDiv.appendChild(descDiv);
        summaryItem.appendChild(iconDiv);
        summaryItem.appendChild(detailsDiv);
        
        container.appendChild(summaryItem);
    });
}

async function fetchRecoveryData() {
    if (!userId) return;
    try {
        // Fetch real biometrics
        const response = await fetch(`/api/v1/biometrics/${userId}?limit=14`);
        const json = await response.json();
        
        let data = json.data.reverse(); // oldest to newest
        
        // If user has no data, mock 14 days of realistic HRV for MVP UI
        if (data.length === 0) {
            const today = new Date();
            for (let i = 13; i >= 0; i--) {
                data.push({
                    recorded_date: new Date(today.getTime() - i * 86400000).toISOString(),
                    hrv: 45 + Math.random() * 20, // 45 to 65
                    sleep_duration_min: 420 + Math.random() * 120, // 7 to 9 hours
                    resting_hr: 50 + Math.random() * 10
                });
            }
        }
        
        if (data.length > 0) {
            const latest = data[data.length - 1];
            
            // Calculate a mock score based on HRV 
            const score = Math.round((latest.hrv / 65) * 100);
            
            document.getElementById('rec-score').innerText = Math.min(100, score);
            document.getElementById('rec-hrv').innerText = Math.round(latest.hrv);
            document.getElementById('rec-sleep').innerText = (latest.sleep_duration_min / 60).toFixed(1) + 'h';
            document.getElementById('rec-rhr').innerText = Math.round(latest.resting_hr);
            
            // Trends (Mock)
            document.getElementById('rec-score-delta').innerText = '↑ 5% from last week';
            document.getElementById('rec-score-delta').className = 'rm-delta text-success';
            document.getElementById('rec-hrv-delta').innerText = '↓ 2ms';
            
            // Render Charts
            // destroy existing charts if exist
            ['scoreChart', 'hrvChart', 'sleepChart', 'rhrChart'].forEach(id => {
                if (window[id]) window[id].destroy();
            });
            
            const labels = data.map(d => new Date(d.recorded_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }));
            
            const scoreData = data.map(d => Math.min(100, Math.round((d.hrv / 65) * 100)));
            const hrvData = data.map(d => Math.round(d.hrv));
            const sleepData = data.map(d => parseFloat((d.sleep_duration_min / 60).toFixed(1)));
            const rhrData = data.map(d => Math.round(d.resting_hr));
            
            function createLineChart(id, label, chartData, color) {
                const ctx = document.getElementById(id);
                if (!ctx) return null;
                return new Chart(ctx.getContext('2d'), {
                    type: 'line',
                    data: {
                        labels: labels,
                        datasets: [{
                            label: label,
                            data: chartData,
                            borderColor: color,
                            backgroundColor: color + '1A', // 10% opacity for fill
                            fill: true,
                            tension: 0.4,
                            pointRadius: 3,
                            pointBackgroundColor: '#fff',
                            pointBorderColor: color,
                            pointBorderWidth: 2
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: { legend: { display: false } },
                        scales: {
                            y: { grid: { color: 'rgba(0, 0, 0, 0.05)', drawBorder: false }, ticks: { color: '#86868b' } },
                            x: { grid: { display: false }, ticks: { color: '#86868b', maxTicksLimit: 7 } }
                        },
                        interaction: {
                            intersect: false,
                            mode: 'index',
                        },
                    }
                });
            }

            window.scoreChart = createLineChart('chart-score', 'Score', scoreData, '#34C759');
            window.hrvChart = createLineChart('chart-hrv', 'HRV', hrvData, '#0071e3');
            window.sleepChart = createLineChart('chart-sleep', 'Sleep', sleepData, '#8B5CF6');
            window.rhrChart = createLineChart('chart-rhr', 'RHR', rhrData, '#FF3B30');
        }
    } catch (e) { console.error("Error recovery data", e); }
}

let editBase64Pic = null;

function setupProfileEditPage() {
    const btn = document.getElementById('sidebar-profile-trigger') || document.getElementById('global-profile-btn');
    const page = document.getElementById('profile-page');
    const closeBtn = document.getElementById('close-profile-btn');
    
    btn.onclick = () => {
        page.classList.remove('hidden');
        if (currentUserData) {
            document.getElementById('edit-email').value = currentUserData.email || '';
            document.getElementById('edit-name').value = currentUserData.full_name || '';
            
            if (currentUserData.profile_picture) {
                editBase64Pic = currentUserData.profile_picture;
                document.getElementById('edit-avatar-preview').style.backgroundImage = `url(${editBase64Pic})`;
                document.getElementById('edit-avatar-placeholder').style.display = 'none';
            } else {
                editBase64Pic = null;
                document.getElementById('edit-avatar-preview').style.backgroundImage = 'none';
                document.getElementById('edit-avatar-placeholder').style.display = 'block';
            }
        }
    };
    
    closeBtn.onclick = () => {
        page.classList.add('hidden');
    };
    
    document.getElementById('edit-pic-input').onchange = (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (ev) => {
                editBase64Pic = ev.target.result;
                document.getElementById('edit-avatar-preview').style.backgroundImage = `url(${editBase64Pic})`;
                document.getElementById('edit-avatar-placeholder').style.display = 'none';
            };
            reader.readAsDataURL(file);
        }
    };
    
    document.getElementById('edit-profile-submit').onclick = async () => {
        const name = document.getElementById('edit-name').value;
        if (!name) return alert('Name cannot be empty');
        
        try {
            const res = await fetch(`/api/v1/auth/profile/${userId}`, {
                method: 'PUT',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    full_name: name,
                    profile_picture: editBase64Pic
                })
            });
            const data = await res.json();
            if (data.status === 'success') {
                page.classList.add('hidden');
                // refresh dashboard data to update the button and local state
                fetchDashboardData();
            }
        } catch (e) {
            console.error(e);
        }
    };
}

async function fetchTrainingLogData() {
    // No-op — training log is now rendered from dashboard API data via renderTrainingLogFromAPI
}

function renderTrainingLogFromAPI(logItems) {
    const container = document.getElementById('training-log-list');
    if (!container) return;
    container.innerHTML = '';
    
    if (!logItems || logItems.length === 0) {
        container.innerHTML = '<p class="workout-desc">No training history yet. Complete your first workout!</p>';
        return;
    }
    
    logItems.forEach(item => {
        const div = document.createElement('div');
        div.className = 'weekly-summary-item log-item';
        
        let iconHtml = '';
        let badgeHtml = '';
        const itemDate = new Date(item.date);
        const today = new Date();
        today.setHours(0,0,0,0);
        const isPast = itemDate < today;
        
        // Determine display status
        if (item.status === 'completed') {
            iconHtml = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>';
        } else if (item.status === 'adapted' || item.status === 'accepted') {
            div.style.borderLeft = '4px solid var(--accent-purple)';
            iconHtml = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="m9 12 2 2 4-4"/></svg>';
            badgeHtml = '<span style="color: var(--accent-purple); margin-left: 0.5rem; background: rgba(175, 82, 222, 0.1); padding: 0.2rem 0.6rem; border-radius: 999px;">SMART ADAPT</span>';
        } else if (isPast && item.status === 'scheduled') {
            // Past + still scheduled = missed
            div.style.opacity = '0.5';
            div.style.filter = 'grayscale(100%)';
            iconHtml = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="5" y1="12" x2="19" y2="12"/></svg>';
        } else {
            // Upcoming scheduled
            iconHtml = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>';
        }
        
        div.innerHTML = `
            <div class="weekly-summary-icon" style="${(item.status==='adapted'||item.status==='accepted') ? 'color: var(--accent-purple);' : ''}">
                ${iconHtml}
            </div>
            <div>
                <div style="font-size: 0.85rem; font-weight: 700; color: var(--text-muted); margin-bottom: 0.35rem; text-transform: uppercase;">
                    ${itemDate.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
                    ${badgeHtml}
                </div>
                <div class="weekly-summary-title">${item.title}</div>
                <div class="weekly-summary-desc">${item.description || ''}</div>
            </div>
        `;
        container.appendChild(div);
    });
}

// ===== Plan Builder =====
let currentPlanData = null; // Track existing plan data for modify flow

function setupPlanBuilder() {
    const overlay = document.getElementById('plan-builder-overlay');
    const createBtn = document.getElementById('create-plan-btn');
    const modifyBtn = document.getElementById('modify-plan-btn');
    const cancelBtn = document.getElementById('plan-builder-cancel');
    const submitBtn = document.getElementById('plan-builder-submit');
    const titleEl = document.getElementById('plan-builder-title');
    
    if (!overlay || !createBtn) return;

    // Set default dates
    const today = new Date();
    const defaultStart = today.toISOString().split('T')[0];
    const defaultEnd = new Date(today.getTime() + 30 * 86400000).toISOString().split('T')[0];
    document.getElementById('plan-input-start').value = defaultStart;
    document.getElementById('plan-input-end').value = defaultEnd;

    // Create Plan button
    createBtn.addEventListener('click', () => {
        titleEl.innerText = 'Create Your Plan';
        submitBtn.innerText = 'Generate Plan';
        currentPlanData = null;
        // Clear form
        document.getElementById('plan-input-name').value = '';
        document.getElementById('plan-input-distance').value = 'Marathon';
        document.getElementById('plan-input-start').value = defaultStart;
        document.getElementById('plan-input-end').value = defaultEnd;
        overlay.classList.remove('hidden');
    });

    // Modify Plan button – fetch existing plan and prefill form
    modifyBtn.addEventListener('click', async () => {
        titleEl.innerText = 'Modify Your Plan';
        submitBtn.innerText = 'Regenerate Plan';
        
        try {
            const res = await fetch(`/api/v1/training-plans/user/${userId}`);
            const json = await res.json();
            if (json.data) {
                currentPlanData = json.data;
                document.getElementById('plan-input-name').value = json.data.name || '';
                document.getElementById('plan-input-distance').value = json.data.race_distance || 'Marathon';
                document.getElementById('plan-input-start').value = json.data.start_date || defaultStart;
                document.getElementById('plan-input-end').value = json.data.end_date || defaultEnd;
            }
        } catch (e) {
            console.error('Error fetching plan:', e);
        }
        
        overlay.classList.remove('hidden');
    });

    // Cancel
    cancelBtn.addEventListener('click', () => {
        overlay.classList.add('hidden');
    });

    // Submit
    submitBtn.addEventListener('click', async () => {
        const name = document.getElementById('plan-input-name').value.trim();
        const distance = document.getElementById('plan-input-distance').value;
        const startDate = document.getElementById('plan-input-start').value;
        const endDate = document.getElementById('plan-input-end').value;

        if (!name || !startDate || !endDate) {
            alert('Please fill in all fields.');
            return;
        }
        if (new Date(endDate) <= new Date(startDate)) {
            alert('End date must be after start date.');
            return;
        }

        submitBtn.innerText = 'Generating...';
        submitBtn.disabled = true;

        const payload = {
            user_id: parseInt(userId),
            name: name,
            goal_race: name,
            race_distance: distance,
            start_date: startDate,
            end_date: endDate,
        };

        try {
            let url = '/api/v1/training-plans';
            let method = 'POST';

            if (currentPlanData && currentPlanData.id) {
                url = `/api/v1/training-plans/${currentPlanData.id}`;
                method = 'PUT';
            }

            const res = await fetch(url, {
                method: method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
            });

            const json = await res.json();

            if (res.ok) {
                overlay.classList.add('hidden');
                // Refresh all plan-related data
                fetchPlanData();
                fetchDashboardData();
            } else {
                alert('Error: ' + (json.detail || 'Failed to generate plan'));
            }
        } catch (e) {
            console.error('Plan builder error:', e);
            alert('An error occurred while generating the plan.');
        } finally {
            submitBtn.innerText = currentPlanData ? 'Regenerate Plan' : 'Generate Plan';
            submitBtn.disabled = false;
        }
    });
}

