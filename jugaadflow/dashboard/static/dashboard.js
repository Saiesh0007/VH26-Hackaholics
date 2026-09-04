const MAX_POINTS = 60;
const TIER_COLORS = {
    1: '#4caf50',
    2: '#2196f3',
    3: '#ff9800',
    4: '#f44336',
};
const LEVEL_CLASSES = ['level-0', 'level-1', 'level-2', 'level-3'];

let latencyChart, throughputChart;
let currentMode = 'adaptive';

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

function renderQueueDepths(queues) {
    const el = document.getElementById('queueDepths');
    const items = [
        ['Tier 1', queues.tier1],
        ['Tier 2', queues.tier2],
        ['Tier 3', queues.tier3],
        ['Tier 4', queues.tier4],
        ['Def T2', queues.deferred_tier2],
        ['Def T3', queues.deferred_tier3],
    ];
    el.innerHTML = items
        .map(([k, v]) => `<div class="counter-item"><span class="counter-label">${k}</span><span class="counter-value">${v.toLocaleString()}</span></div>`)
        .join('');
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
    document.getElementById('rateValue').textContent = data.rate_multiplier + 'x';

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

function triggerSpike() {
    fetch('/api/spike', { method: 'POST' });
}

function triggerNormal() {
    fetch('/api/normal', { method: 'POST' });
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
