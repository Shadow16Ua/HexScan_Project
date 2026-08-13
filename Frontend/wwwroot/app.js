document.addEventListener('DOMContentLoaded', () => {

    // ==========================================
    // 1. SPA ROUTER (Перемикання сторінок)
    // ==========================================
    const navLinks = document.querySelectorAll('.nav-link');
    const pages = document.querySelectorAll('.page-view');

    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('data-target');
            if (!targetId) return;

            // Ховаємо всі сторінки і знімаємо активні класи з меню
            pages.forEach(page => page.classList.remove('active-page'));
            navLinks.forEach(nav => nav.classList.remove('active'));

            // Показуємо потрібну
            document.getElementById(targetId).classList.add('active-page');
            
            // Якщо це не логотип - робимо лінк активним
            if (!link.classList.contains('logo')) {
                link.classList.add('active');
            }
            
            window.scrollTo({ top: 0, behavior: 'smooth' });
        });
    });

    // ==========================================
    // 2. FAQ АКОРДЕОН
    // ==========================================
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const btn = item.querySelector('.faq-question');
        btn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            // Закриваємо всі інші
            faqItems.forEach(i => {
                i.classList.remove('active');
                i.querySelector('.faq-question').setAttribute('aria-expanded', 'false');
            });
            
            // Відкриваємо поточну
            if (!isActive) {
                item.classList.add('active');
                btn.setAttribute('aria-expanded', 'true');
            }
        });
    });

    // ==========================================
    // 3. ПОВІДОМЛЕННЯ (NOTIFICATIONS)
    // ==========================================
    const notiBtn = document.getElementById('noti-btn');
    const notiDropdown = document.getElementById('noti-dropdown');
    const notiBadge = document.getElementById('noti-badge');
    const notiBody = document.getElementById('noti-body');

    let latestNewsId = null;

    function timeAgo(dateString) {
        const date = new Date(dateString);
        const now = new Date();
        const seconds = Math.floor((now - date) / 1000);
        
        if (seconds < 60) return "Just now";
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60) return `${minutes} min ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours} hours ago`;
        const days = Math.floor(hours / 24);
        return `${days} days ago`;
    }

    async function loadNotifications() {
        try {
            const response = await fetch('notifications.json');
            const allNews = await response.json();

            const FORTY_EIGHT_HOURS_MS = 48 * 60 * 60 * 1000;
            const now = Date.now();
            
            const activeNews = allNews.filter(item => {
                const itemTime = new Date(item.timestamp).getTime();
                return (now - itemTime) <= FORTY_EIGHT_HOURS_MS;
            });

            notiBody.innerHTML = '';

            if (activeNews.length === 0) {
                notiBody.innerHTML = '<div style="padding: 1rem; text-align: center; color: #94a3b8;">No new notifications</div>';
                notiBadge.classList.add('hidden');
                return;
            }

            latestNewsId = activeNews[0].id;

            if (localStorage.getItem('readNews') === latestNewsId) {
                notiBadge.classList.add('hidden');
            } else {
                notiBadge.classList.remove('hidden');
            }

            activeNews.forEach(item => {
                const isUnread = (item.id === latestNewsId && !notiBadge.classList.contains('hidden')) ? 'unread' : '';
                const relativeTime = timeAgo(item.timestamp);
                
                const newsHtml = `
                    <div class="noti-item ${isUnread}">
                        <strong>${item.title}</strong>
                        <p>${item.text}</p>
                        <span class="noti-time">${relativeTime}</span>
                    </div>
                `;
                notiBody.insertAdjacentHTML('beforeend', newsHtml);
            });

        } catch (error) {
            console.error("Failed to load notifications:", error);
            notiBody.innerHTML = '<div style="padding: 1rem; color: #ef4444;">Failed to load updates.</div>';
        }
    }

    loadNotifications();

    notiBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        notiDropdown.classList.toggle('hidden');
        
        if (!notiDropdown.classList.contains('hidden') && !notiBadge.classList.contains('hidden')) {
            notiBadge.classList.add('hidden');
            if (latestNewsId) {
                localStorage.setItem('readNews', latestNewsId);
            }
            document.querySelectorAll('.noti-item.unread').forEach(el => el.classList.remove('unread'));
        }
    });

    document.addEventListener('click', (e) => {
        if (!notiBtn.contains(e.target) && !notiDropdown.contains(e.target)) {
            notiDropdown.classList.add('hidden');
        }
    });

    // ==========================================
    // 4. DRAG & DROP ТА СКАНЕР ФАЙЛІВ
    // ==========================================
    const dropZone = document.getElementById('drop-zone');
    const fileInput = document.getElementById('file-input');
    const scanResults = document.getElementById('scan-results');

    if (dropZone && fileInput) {
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, preventDefaults, false);
        });

        function preventDefaults(e) {
            e.preventDefault();
            e.stopPropagation();
        }

        ['dragenter', 'dragover'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => dropZone.classList.add('dragover'), false);
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => dropZone.classList.remove('dragover'), false);
        });

        dropZone.addEventListener('drop', (e) => {
            const dt = e.dataTransfer;
            const files = dt.files;
            handleFiles(files);
        });

        fileInput.addEventListener('change', function() {
            handleFiles(this.files);
        });
    }

    function handleFiles(files) {
        if (files.length === 0) return;
        const file = files[0];
        simulateScan(file);
    }

    function simulateScan(file) {
        dropZone.classList.add('hidden');
        scanResults.classList.remove('hidden');
        
        scanResults.innerHTML = `
            <h3><i class="fa-solid fa-spinner spin"></i> Analyzing ${file.name}...</h3>
            <p>Running heuristics and checking signatures...</p>
        `;

        setTimeout(() => {
            const isSafe = Math.random() > 0.3; 
            
            if (isSafe) {
                scanResults.innerHTML = `
                    <h3 class="status-safe"><i class="fa-solid fa-circle-check"></i> File is Clean</h3>
                    <p><strong>${file.name}</strong> (${(file.size / 1024 / 1024).toFixed(2)} MB)<br>
                    No threats were detected by our engines.</p>
                    <button class="btn-secondary" onclick="location.reload()" style="margin-top: 1rem;">Scan Another</button>
                `;
                scanResults.style.borderLeftColor = 'var(--success)';
            } else {
                scanResults.innerHTML = `
                    <h3 class="status-threat"><i class="fa-solid fa-triangle-exclamation"></i> Threat Detected</h3>
                    <p><strong>${file.name}</strong><br>
                    Malicious signature found: Trojan.Generic.Auto</p>
                    <button class="btn-secondary" onclick="location.reload()" style="margin-top: 1rem;">Back</button>
                `;
                scanResults.style.borderLeftColor = 'var(--danger)';
            }
        }, 3000);
    }

    // ==========================================
    // 5. IP GEOLOCATION ТА URL СКАНЕР
    // ==========================================
    const btnIp = document.getElementById('btn-locate-ip');
    const ipInput = document.getElementById('ip-input');
    const ipResult = document.getElementById('ip-result');

    if (btnIp) {
        btnIp.addEventListener('click', async () => {
            const ip = ipInput.value.trim();
            ipResult.classList.remove('hidden');
            ipResult.innerHTML = '<i class="fa-solid fa-spinner spin"></i> Locating...';

            try {
                const response = await fetch(`https://ipapi.co/${ip ? ip + '/' : ''}json/`);
                const data = await response.json();

                if (data.error) {
                    ipResult.innerHTML = `<span class="status-threat">Error: ${data.reason}</span>`;
                    return;
                }

                ipResult.innerHTML = `
                    <strong>Location:</strong> ${data.city}, ${data.country_name} <br>
                    <strong>ISP:</strong> ${data.org}
                `;
            } catch (error) {
                ipResult.innerHTML = '<span class="status-threat">Failed to fetch data.</span>';
            }
        });
    }

    const btnUrl = document.getElementById('btn-scan-url');
    if (btnUrl) {
        btnUrl.addEventListener('click', () => {
            const btnText = btnUrl.innerText;
            btnUrl.innerHTML = '<i class="fa-solid fa-spinner spin"></i>';
            setTimeout(() => {
                btnUrl.innerText = 'Safe!';
                btnUrl.style.background = 'var(--success)';
                setTimeout(() => {
                    btnUrl.innerText = btnText;
                    btnUrl.style.background = '';
                }, 2000);
            }, 1500);
        });
    }
});