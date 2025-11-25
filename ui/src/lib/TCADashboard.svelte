<script>
  import { onMount } from 'svelte';
  import Chart from 'chart.js/auto';

  export let data = {};

  // TCA-focused data processing
  $: actions = data.actions || [];
  $: effects = data.effects || [];
  $: features = Object.entries(data.metrics?.features || {});

  // Categorize actions by TCA function
  $: uiEvents = actions.filter(a => a.actionName.includes('Changed') || a.actionName.includes('Tapped') || a.actionName.includes('Selected'));
  $: dataLoading = actions.filter(a => a.actionName.includes('load') || a.actionName.includes('fetch') || a.actionName.includes('Effect'));
  $: stateMutations = actions.filter(a => a.actionName.includes('set') || a.actionName.includes('update') || a.actionName.includes('mutate'));
  $: navigation = actions.filter(a => a.actionName.includes('navigate') || a.actionName.includes('route') || a.actionName.includes('select'));

  // TCA health metrics
  $: effectToActionRatio = actions.length > 0 ? (effects.length / actions.length * 100).toFixed(1) : 0;
  $: slowActionCount = actions.filter(a => a.duration > 0.016).length;
  $: avgActionDuration = actions.length > 0 ? actions.reduce((sum, a) => sum + a.duration, 0) / actions.length * 1000 : 0;

  // Calculate action distribution
  $: actionDistribution = [
    { name: 'UI Events', count: uiEvents.length, percentage: actions.length > 0 ? (uiEvents.length / actions.length * 100).toFixed(1) : 0 },
    { name: 'Data Loading', count: dataLoading.length, percentage: actions.length > 0 ? (dataLoading.length / actions.length * 100).toFixed(1) : 0 },
    { name: 'State Mutations', count: stateMutations.length, percentage: actions.length > 0 ? (stateMutations.length / actions.length * 100).toFixed(1) : 0 },
    { name: 'Navigation', count: navigation.length, percentage: actions.length > 0 ? (navigation.length / actions.length * 100).toFixed(1) : 0 }
  ];

  // Timeline for TCA activity density
  $: timelineData = actions.map(a => ({
    x: a.timestamp,
    y: a.duration * 1000,
    type: getActionType(a.actionName)
  }));

  function getActionType(name) {
    if (name.includes('Changed') || name.includes('Tapped')) return 'UI Event';
    if (name.includes('load') || name.includes('Effect')) return 'Data Loading';
    if (name.includes('set') || name.includes('update')) return 'State Mutation';
    if (name.includes('navigate') || name.includes('select')) return 'Navigation';
    return 'Other';
  }

  function cleanActionName(name) {
    return name.replace(/^TCAAction/, '').trim() || name;
  }

  function formatDuration(ms) {
    if (ms < 1) return `${(ms * 1000).toFixed(1)}μs`;
    if (ms < 1000) return `${ms.toFixed(1)}ms`;
    return `${(ms / 1000).toFixed(2)}s`;
  }

  function getHealthScore() {
    let score = 100;
    if (slowActionCount > 5) score -= 20;
    if (effectToActionRatio > 30) score -= 15;
    if (avgActionDuration > 10) score -= 10;
    return Math.max(0, score);
  }

  onMount(() => {
    // Action Distribution Chart
    const distribCtx = document.getElementById('actionDistributionChart');
    if (distribCtx) {
      new Chart(distribCtx, {
        type: 'doughnut',
        data: {
          labels: actionDistribution.map(d => d.name),
          datasets: [{
            data: actionDistribution.map(d => d.count),
            backgroundColor: ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6'],
            borderWidth: 0
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: true,
              text: 'TCA Action Distribution',
              font: { size: 18, weight: 'bold' },
              color: '#e2e8f0'
            },
            legend: {
              position: 'bottom',
              labels: { color: '#94a3b8' }
            }
          }
        }
      });
    }

    // TCA Activity Timeline
    const timelineCtx = document.getElementById('tcaTimelineChart');
    if (timelineCtx) {
      const actionTypes = ['UI Event', 'Data Loading', 'State Mutation', 'Navigation'];
      const datasets = actionTypes.map((type, index) => ({
        label: type,
        data: timelineData.filter(d => d.type === type),
        backgroundColor: ['#10b981', '#3b82f6', '#f59e0b', '#8b5cf6'][index],
        pointRadius: 6
      }));

      new Chart(timelineCtx, {
        type: 'scatter',
        data: { datasets },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: true,
              text: 'TCA Activity Timeline (State Mutations & Effects)',
              font: { size: 18, weight: 'bold' },
              color: '#e2e8f0'
            },
            legend: {
              position: 'bottom',
              labels: { color: '#94a3b8' }
            }
          },
          scales: {
            x: {
              title: { display: true, text: 'Time (seconds)', color: '#94a3b8' },
              grid: { color: 'rgba(255,255,255,0.1)' },
              ticks: { color: '#94a3b8' }
            },
            y: {
              type: 'logarithmic',
              title: { display: true, text: 'Duration (ms)', color: '#94a3b8' },
              grid: { color: 'rgba(255,255,255,0.1)' },
              ticks: { color: '#94a3b8' }
            }
          }
        }
      });
    }

    // Feature Performance Chart
    const featureCtx = document.getElementById('featurePerformanceChart');
    if (featureCtx && features.length > 0) {
      new Chart(featureCtx, {
        type: 'bar',
        data: {
          labels: features.map(([name]) => name),
          datasets: [{
            label: 'Actions',
            data: features.map(([, metrics]) => metrics.actionCount || 0),
            backgroundColor: '#10b981'
          }, {
            label: 'Slow Actions',
            data: features.map(([, metrics]) => metrics.slowActions || 0),
            backgroundColor: '#ef4444'
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: true,
              text: 'Feature Performance Analysis',
              font: { size: 18, weight: 'bold' },
              color: '#e2e8f0'
            },
            legend: {
              labels: { color: '#94a3b8' }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              title: { display: true, text: 'Count', color: '#94a3b8' },
              grid: { color: 'rgba(255,255,255,0.1)' },
              ticks: { color: '#94a3b8' }
            },
            x: {
              grid: { color: 'rgba(255,255,255,0.1)' },
              ticks: { color: '#94a3b8' }
            }
          }
        }
      });
    }
  });
</script>

<style>
  :global(*) {
    box-sizing: border-box;
  }

  :global(body) {
    margin: 0;
    background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
    color: #e2e8f0;
    font-family: Inter, SF Pro Display, system-ui, sans-serif;
    line-height: 1.6;
  }

  .dashboard {
    max-width: 1400px;
    margin: 0 auto;
    padding: 2rem;
  }

  .header {
    text-align: center;
    margin-bottom: 3rem;
  }

  .header h1 {
    font-size: 3rem;
    font-weight: 800;
    margin: 0;
    background: linear-gradient(135deg, #10b981, #3b82f6);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .header .subtitle {
    font-size: 1.2rem;
    color: #94a3b8;
    margin-top: 0.5rem;
  }

  .health-score {
    background: linear-gradient(135deg, #10b981, #059669);
    border-radius: 1rem;
    padding: 2rem;
    text-align: center;
    margin-bottom: 2rem;
    box-shadow: 0 10px 30px rgba(16, 185, 129, 0.3);
  }

  .health-score h2 {
    margin: 0 0 0.5rem;
    font-size: 2.5rem;
    color: white;
  }

  .health-score p {
    margin: 0;
    color: rgba(255,255,255,0.9);
    font-size: 1.1rem;
  }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 2rem;
    margin-bottom: 3rem;
  }

  .card {
    background: #1e293b;
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 1rem;
    padding: 1.5rem;
    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
    backdrop-filter: blur(10px);
  }

  .card h3 {
    margin: 0 0 1rem;
    color: #10b981;
    font-size: 1.3rem;
    font-weight: 600;
  }

  .metric-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-top: 1rem;
  }

  .metric {
    text-align: center;
    padding: 1rem;
    background: rgba(255,255,255,0.05);
    border-radius: 0.5rem;
  }

  .metric .value {
    font-size: 2rem;
    font-weight: 700;
    color: #e2e8f0;
  }

  .metric .label {
    font-size: 0.9rem;
    color: #94a3b8;
    margin-top: 0.25rem;
  }

  .chart-container {
    height: 350px;
    margin-top: 1rem;
  }

  .action-list {
    margin-top: 1rem;
    max-height: 400px;
    overflow-y: auto;
  }

  .action-item {
    background: rgba(255,255,255,0.05);
    border-radius: 0.5rem;
    padding: 1rem;
    margin-bottom: 0.75rem;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-left: 4px solid #10b981;
  }

  .action-item.slow {
    border-left-color: #ef4444;
  }

  .action-item.effect {
    border-left-color: #3b82f6;
  }

  .action-name {
    font-weight: 600;
    color: #e2e8f0;
    font-family: 'SF Mono', Monaco, monospace;
    font-size: 0.9rem;
  }

  .action-feature {
    color: #94a3b8;
    font-size: 0.85rem;
    margin-top: 0.25rem;
  }

  .action-duration {
    font-weight: 600;
    color: #10b981;
  }

  .tca-principles {
    background: linear-gradient(135deg, #1e293b, #334155);
    border-radius: 1rem;
    padding: 2rem;
    margin-bottom: 2rem;
    border: 1px solid rgba(255,255,255,0.1);
  }

  .tca-principles h2 {
    margin: 0 0 1rem;
    color: #10b981;
    font-size: 1.5rem;
  }

  .principles-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1.5rem;
  }

  .principle {
    background: rgba(255,255,255,0.05);
    border-radius: 0.75rem;
    padding: 1.5rem;
    text-align: center;
  }

  .principle .icon {
    font-size: 2rem;
    margin-bottom: 1rem;
  }

  .principle h3 {
    margin: 0 0 0.5rem;
    color: #e2e8f0;
  }

  .principle p {
    margin: 0;
    color: #94a3b8;
    font-size: 0.9rem;
  }

  @media (max-width: 768px) {
    .dashboard {
      padding: 1rem;
    }

    .header h1 {
      font-size: 2rem;
    }

    .grid {
      grid-template-columns: 1fr;
      gap: 1rem;
    }
  }
</style>

<div class="dashboard">
  <div class="header">
    <h1>🏗️ TCA Performance Dashboard</h1>
    <p class="subtitle">State Mutations, Actions, Side Effects & Dependencies Analysis</p>
  </div>

  <div class="health-score">
    <h2>{getHealthScore()}/100</h2>
    <p>TCA Architecture Health Score</p>
  </div>

  <div class="tca-principles">
    <h2>🎯 TCA Core Principles Analysis</h2>
    <div class="principles-grid">
      <div class="principle">
        <div class="icon">🔄</div>
        <h3>State Mutations</h3>
        <p>{stateMutations.length} mutations detected</p>
      </div>
      <div class="principle">
        <div class="icon">⚡</div>
        <h3>Actions</h3>
        <p>{actions.length} total actions</p>
      </div>
      <div class="principle">
        <div class="icon">🌊</div>
        <h3>Side Effects</h3>
        <p>{effects.length} effects running</p>
      </div>
      <div class="principle">
        <div class="icon">🔗</div>
        <h3>Dependencies</h3>
        <p>{effectToActionRatio}% effect-to-action ratio</p>
      </div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <h3>📊 Action Distribution</h3>
      <div class="chart-container">
        <canvas id="actionDistributionChart"></canvas>
      </div>
    </div>

    <div class="card">
      <h3>⏱️ TCA Activity Timeline</h3>
      <div class="chart-container">
        <canvas id="tcaTimelineChart"></canvas>
      </div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <h3>🎯 Key Metrics</h3>
      <div class="metric-grid">
        <div class="metric">
          <div class="value">{actions.length}</div>
          <div class="label">Total Actions</div>
        </div>
        <div class="metric">
          <div class="value">{slowActionCount}</div>
          <div class="label">Slow Actions</div>
        </div>
        <div class="metric">
          <div class="value">{effects.length}</div>
          <div class="label">Effects</div>
        </div>
        <div class="metric">
          <div class="value">{features.length}</div>
          <div class="label">Features</div>
        </div>
        <div class="metric">
          <div class="value">{avgActionDuration.toFixed(1)}ms</div>
          <div class="label">Avg Duration</div>
        </div>
        <div class="metric">
          <div class="value">{effectToActionRatio}%</div>
          <div class="label">Effect/Action Ratio</div>
        </div>
      </div>
    </div>

    <div class="card">
      <h3>🏗️ Feature Performance</h3>
      <div class="chart-container">
        <canvas id="featurePerformanceChart"></canvas>
      </div>
    </div>
  </div>

  <div class="card">
    <h3>🔍 Detailed Action Analysis</h3>
    <div class="action-list">
      {#each actions.sort((a, b) => b.duration - a.duration).slice(0, 20) as action}
        <div class="action-item {action.duration > 0.016 ? 'slow' : ''} {action.actionName.includes('Effect') ? 'effect' : ''}">
          <div>
            <div class="action-name">{cleanActionName(action.actionName)}</div>
            <div class="action-feature">{action.featureName || 'Unknown Feature'}</div>
          </div>
          <div class="action-duration">{(action.duration * 1000).toFixed(1)}ms</div>
        </div>
      {/each}
    </div>
  </div>
</div>