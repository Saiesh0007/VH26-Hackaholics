const MAX_POINTS = 60;
const TIER_COLORS = {
    1: '#4caf50',
    2: '#2196f3',
    3: '#ff9800',
    4: '#f44336',
};
const LEVEL_CLASSES = ['level-0', 'level-1', 'level-2', 'level-3'];

let latencyChart, throughputChart, classChart;
let currentMode = 'adaptive';
const TIER_LABELS = ['Tier 1 (Payment/Order)', 'Tier 2 (Inventory)', 'Tier 3 (Clicks)', 'Tier 4 (Logs)'];

function initCharts() {
    const sharedOpts = {
        responsive: true,
        animation: { duration: 200 },
        scales: {
            x: { display: false },
            y: { beginAtZero: true, ticks: { color: '#8899a6' }, grid: { color: '#2a2f36' } }
        },
        plugins: { legend: { labels: { color: '#e7e9ea', boxWidth: 12 } } }
    };

    latencyChart = new Chart(document.getElementById('latencyChart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                { label: 'Tier 1', data: [], borderColor: TIER_COLORS[1], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 2', data: [], borderColor: TIER_COLORS[2], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 3', data: [], borderColor: TIER_COLORS[3], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 4', data: [], borderColor: TIER_COLORS[4], borderWidth: 2, pointRadius: 0, tension: 0.3 },
            ]
        },
        options: sharedOpts
    });

    classChart = new Chart(document.getElementById('classChart'), {
        type: 'doughnut',
        data: {
            labels: TIER_LABELS,
            datasets: [{
                data: [0, 0, 0, 0],
                backgroundColor: [TIER_COLORS[1], TIER_COLORS[2], TIER_COLORS[3], TIER_COLORS[4]],
                borderWidth: 0,
            }]
        },
        options: {
            responsive: true,
            animation: { duration: 300 },
            cutout: '55%',
            plugins: {
                legend: { display: false },
            }
        }
    });

    throughputChart = new Chart(document.getElementById('throughputChart'), {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                { label: 'Tier 1', data: [], borderColor: TIER_COLORS[1], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 2', data: [], borderColor: TIER_COLORS[2], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 3', data: [], borderColor: TIER_COLORS[3], borderWidth: 2, pointRadius: 0, tension: 0.3 },
                { label: 'Tier 4', data: [], borderColor: TIER_COLORS[4], borderWidth: 2, pointRadius: 0, tension: 0.3 },
            ]
        },
        options: sharedOpts
    });
}

function pushChartData(chart, label, values) {
    chart.data.labels.push(label);
    values.forEach((v, i) => chart.data.datasets[i].data.push(v));
    if (chart.data.labels.length > MAX_POINTS) {
        chart.data.labels.shift();
        chart.data.datasets.forEach(ds => ds.data.shift());
    }
    chart.update('none');
}

function renderCounters(elementId, counters) {
    const el = document.getElementById(elementId);
    el.innerHTML = Object.entries(counters)
        .map(([k, v]) => `<div class="counter-item"><span class="counter-label">${k}</span><span class="counter-value">${v.toLocaleString()}</span></div>`)
        .join('');
}

const QUEUE_CONFIG = [
    { key: 'input',          label: 'Input',  max: 10000, css: 'input' },
    { key: 'tier1',          label: 'Tier 1', max: null,  css: 'tier1' },
    { key: 'tier2',          label: 'Tier 2', max: 5000,  css: 'tier2' },
    { key: 'tier3',          label: 'Tier 3', max: 2000,  css: 'tier3' },
    { key: 'tier4',          label: 'Tier 4', max: 500,   css: 'tier4' },
    { key: 'deferred_tier2', label: 'Def T2', max: 3000,  css: 'deferred' },
    { key: 'deferred_tier3', label: 'Def T3', max: 2000,  css: 'deferred' },
];

function renderQueueDepths(queues) {
    const el = document.getElementById('queueDepths');
    el.innerHTML = QUEUE_CONFIG.map(q => {
        const current = queues[q.key] || 0;
        const unlimited = q.max === null;
        const pct = unlimited ? Math.min(current / 100, 1) * 100 : (current / q.max) * 100;
        const danger = !unlimited && pct > 90;
        const full = !unlimited && current >= q.max;
        const maxLabel = unlimited ? '∞' : q.max.toLocaleString();
        const fullTag = full ? '<span class="full-tag">FULL</span>' : '';
        return `<div class="queue-bar-row">
            <span class="queue-bar-label">${q.label}</span>
            <div class="queue-bar">
                <div class="queue-bar-fill ${q.css}${danger ? ' danger' : ''}" style="width:${Math.min(pct, 100)}%"></div>
            </div>
            <span class="queue-bar-count">${current.toLocaleString()} / ${maxLabel}${fullTag}</span>
        </div>`;
    }).join('');
}

function handleMessage(data) {
    // Level bar
    const bar = document.getElementById('levelBar');
    bar.textContent = data.level_name;
    bar.className = 'level-bar ' + LEVEL_CLASSES[data.level];

    // Latency values
    for (let t = 1; t <= 4; t++) {
        const val = data.latency_ms['tier' + t];
        document.getElementById('lat' + t).textContent = val !== null ? val.toFixed(1) + ' ms' : '— ms';
    }

    // Proof line
    const proof = document.getElementById('proofLine');
    const paymentShed = data.counters.shed.payment || 0;
    if (paymentShed === 0) {
        proof.textContent = 'Payments shed: 0 ✓';
        proof.className = 'proof-line';
    } else {
        proof.textContent = 'Payments shed: ' + paymentShed + ' ✗ ALERT';
        proof.className = 'proof-line proof-fail';
    }

    // Queue depths
    renderQueueDepths(data.queues);

    // Backpressure
    const bp = document.getElementById('bpStatus');
    bp.textContent = data.backpressure ? 'ACTIVE' : 'Inactive';
    bp.className = data.backpressure ? 'value bp-active' : 'value bp-inactive';
    document.getElementById('inputQ').textContent = data.queues.input.toLocaleString();

    // Rate
    const approxRate = Math.round(data.rate_multiplier * BASE_RATE);
    document.getElementById('rateValue').textContent = data.rate_multiplier.toFixed(1) + 'x (~' + approxRate.toLocaleString() + '/min)';
    highlightRateButton(data.rate_multiplier);

    // Total processed
    const total = Object.values(data.counters.processed).reduce((a, b) => a + b, 0);
    document.getElementById('totalProcessed').textContent = total.toLocaleString();

    // Charts
    const label = new Date(data.timestamp * 1000).toLocaleTimeString();
    pushChartData(latencyChart, label, [
        data.latency_ms.tier1 || 0,
        data.latency_ms.tier2 || 0,
        data.latency_ms.tier3 || 0,
        data.latency_ms.tier4 || 0,
    ]);
    pushChartData(throughputChart, label, [
        data.throughput_per_sec['1'] || 0,
        data.throughput_per_sec['2'] || 0,
        data.throughput_per_sec['3'] || 0,
        data.throughput_per_sec['4'] || 0,
    ]);

    // Classification donut
    if (data.classified_per_sec) {
        const cls = data.classified_per_sec;
        const vals = [cls['1'] || 0, cls['2'] || 0, cls['3'] || 0, cls['4'] || 0];
        classChart.data.datasets[0].data = vals;
        classChart.update();
        const total = vals.reduce((a, b) => a + b, 0) || 1;
        document.getElementById('classRates').innerHTML = vals.map((v, i) => {
            const pct = ((v / total) * 100).toFixed(0);
            return `<span class="class-badge" style="border-color:${TIER_COLORS[i+1]}">T${i+1}: ${v}/s (${pct}%)</span>`;
        }).join('');
    }

    // Counter tables
    renderCounters('shedCounters', data.counters.shed);
    renderCounters('deferredCounters', data.counters.deferred);
    renderCounters('batchedCounters', data.counters.batched);
    renderCounters('processedCounters', data.counters.processed);
}

function connectWS() {
    const ws = new WebSocket('ws://' + location.host + '/ws');
    ws.onmessage = (evt) => handleMessage(JSON.parse(evt.data));
    ws.onclose = () => setTimeout(connectWS, 2000);
}

const BASE_RATE = 3400;
const PRESETS = [1000, 3400, 10000, 20000, 50000, 68000];

function setRate(eventsPerMin) {
    fetch('/api/rate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ events_per_min: eventsPerMin }),
    });
}

function setCustomRate() {
    const input = document.getElementById('customRate');
    const val = parseInt(input.value, 10);
    if (val >= 100 && val <= 340000) {
        setRate(val);
        input.value = '';
    }
}

function highlightRateButton(multiplier) {
    const currentRate = Math.round(multiplier * BASE_RATE);
    document.querySelectorAll('.btn-rate').forEach(btn => {
        const btnRate = parseInt(btn.dataset.rate, 10);
        btn.classList.toggle('active', Math.abs(btnRate - currentRate) < 200);
    });
}

function toggleMode() {
    const btn = document.getElementById('modeBtn');
    if (currentMode === 'adaptive') {
        fetch('/api/mode/naive', { method: 'POST' });
        currentMode = 'naive';
        btn.textContent = 'Mode: Naive';
    } else {
        fetch('/api/mode/adaptive', { method: 'POST' });
        currentMode = 'adaptive';
        btn.textContent = 'Mode: Adaptive';
    }
}

initCharts();
connectWS();
