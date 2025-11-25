<script>
  import { onMount } from 'svelte';
  import Chart from 'chart.js/auto';

  export let data;

  $: metrics = data.metrics || {};
  $: actions = data.actions || [];
  $: effects = data.effects || [];
  $: recommendations = data.recommendations || [];
  $: complexityScore = data.complexityScore || 0;
  $: metadata = data.metadata || {};

  $: slowActions = actions.filter(action => action.duration > 0.016);
  $: fastActions = actions.filter(action => action.duration <= 0.016);

  $: features = Object.entries(metrics.features || {});
  $: topSlowActions = slowActions.sort((a, b) => b.duration - a.duration).slice(0, 8);

  $: actionChartData = {
    labels: actions.map(a => cleanActionName(a.actionName)),
    datasets: [{
      label: 'Duration (ms)',
      data: actions.map(a => a.duration * 1000),
      backgroundColor: actions.map(a => a.duration > 0.016 ? '#ef4444' : '#10b981')
    }]
  };

  $: featureChartData = {
    labels: features.map(([name]) => name),
    datasets: [{
      label: 'Actions',
      data: features.map(([, metrics]) => metrics.actionCount || 0),
      backgroundColor: '#3b82f6'
    }, {
      label: 'Slow Actions',
      data: features.map(([, metrics]) => metrics.slowActions || 0),
      backgroundColor: '#f59e0b'
    }]
  };

  $: timelineData = {
    datasets: [{
      label: 'Fast Actions',
      data: fastActions.map(a => ({ x: a.timestamp, y: a.duration * 1000 })),
      backgroundColor: '#10b981',
      pointRadius: 5
    }, {
      label: 'Slow Actions',
      data: slowActions.map(a => ({ x: a.timestamp, y: a.duration * 1000 })),
      backgroundColor: '#ef4444',
      pointRadius: 7
    }]
  };

  function cleanActionName(name) {
    return name.replace(/^TCAAction/, '').trim() || name;
  }

  function getScoreClass(score) {
    if (score < 25) return 'score-good';
    if (score < 50) return 'score-warn';
    if (score < 75) return 'score-hot';
    return 'score-bad';
  }

  function formatDuration(seconds) {
    if (seconds < 0.001) return `${(seconds * 1000000).toFixed(0)}μs`;
    if (seconds < 1) return `${(seconds * 1000).toFixed(1)}ms`;
    return `${seconds.toFixed(2)}s`;
  }

  function getActionClass(action) {
    return action.duration > 0.016 ? 'slow' : '';
  }

  function formatRecommendation(rec) {
    // Add better formatting for TCA-specific recommendations
    if (rec.includes('@Dependency')) {
      return 'Consider using @Dependency for better dependency injection';
    }
    if (rec.includes('debounce')) {
      return 'Consider debouncing frequent state changes';
    }
    return rec;
  }

  onMount(() => {
    // Feature Chart
    const featureCtx = document.getElementById('featureChart');
    if (featureCtx) {
      new Chart(featureCtx, {
        type: 'bar',
        data: featureChartData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: true,
              text: 'Actions by Feature',
              font: { size: 16 }
            }
          },
          scales: {
            y: {
              beginAtZero: true,
              title: {
                display: true,
                text: 'Count'
              }
            }
          }
        }
      });
    }

    // Timeline Chart
    const timelineCtx = document.getElementById('timelineChart');
    if (timelineCtx) {
      new Chart(timelineCtx, {
        type: 'scatter',
        data: timelineData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            title: {
              display: true,
              text: 'Action Timeline',
              font: { size: 16 }
            }
          },
          scales: {
            x: {
              title: {
                display: true,
                text: 'Timestamp (s)'
              }
            },
            y: {
              type: 'logarithmic',
              title: {
                display: true,
                text: 'Duration (ms)'
              }
            }
          }
        }
      });
    }
  });
</script>

<style>
  :root {
    color: #0f172a;
    background: #0f1623;
    font-family: Inter, SF Pro Display, system-ui, -apple-system, sans-serif;
  }

  * {
    box-sizing: border-box;
  }

  body {
    margin: 0;
    background: radial-gradient(circle at 20% 20%, #182338, #0f1623 50%), #0f1623;
    color: #e2e8f0;
  }

  .page {
    max-width: 1180px;
    margin: 32px auto 64px;
    padding: 0 20px 40px;
  }

  .hero {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 24px 28px;
    border-radius: 18px;
    background: linear-gradient(135deg, #10b981, #059669);
    color: #0b1020;
    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  }

  .hero h1 {
    margin: 6px 0;
    font-size: 32px;
  }

  .hero .sub {
    margin: 0;
    opacity: 0.8;
  }

  .eyebrow {
    margin: 0;
    text-transform: uppercase;
    letter-spacing: 0.18em;
    font-size: 11px;
    opacity: 0.8;
  }

  .score-card {
    background: rgba(255, 255, 255, 0.9);
    padding: 14px 18px;
    border-radius: 14px;
    min-width: 150px;
    text-align: right;
    color: #0f172a;
    box-shadow: inset 0 1px rgba(255, 255, 255, 0.5);
  }

  .score-card h2 {
    margin: 6px 0 0;
    font-size: 28px;
  }

  .score-card p {
    margin: 0;
    font-size: 12px;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  .score-good { border: 2px solid #10b981; }
  .score-warn { border: 2px solid #f59e0b; }
  .score-hot { border: 2px solid #f97316; }
  .score-bad { border: 2px solid #ef4444; }

  .grid.kpis {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 14px;
    margin: 18px 0 24px;
  }

  .card {
    padding: 16px 18px;
    background: #121a2b;
    border: 1px solid rgba(255, 255, 255, 0.04);
    border-radius: 12px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
  }

  .label {
    margin: 0 0 6px;
    font-size: 12px;
    letter-spacing: 0.04em;
    color: #94a3b8;
  }

  .value {
    margin: 0;
    font-size: 24px;
    font-weight: 700;
    color: #e2e8f0;
  }

  .panel {
    background: #0f172a;
    border: 1px solid rgba(255, 255, 255, 0.04);
    border-radius: 14px;
    margin-bottom: 18px;
    padding: 18px;
    box-shadow: 0 10px 34px rgba(0, 0, 0, 0.47);
  }

  .panel-header h3 {
    margin: 0;
  }

  .panel-header p {
    margin: 4px 0 0;
    color: #94a3b8;
  }

  .bars {
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-top: 12px;
  }

  .bar-row {
    display: grid;
    grid-template-columns: 160px 1fr 120px;
    align-items: center;
    gap: 10px;
  }

  .bar-label {
    font-weight: 600;
  }

  .bar-track {
    height: 12px;
    background: #162239;
    border-radius: 999px;
    overflow: hidden;
  }

  .bar-fill {
    height: 100%;
    background: linear-gradient(90deg, #10b981, #22d3ee);
  }

  .bar-meta {
    color: #94a3b8;
    font-size: 13px;
    text-align: right;
  }

  .list {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin-top: 12px;
  }

  .list-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
    padding: 12px;
    background: #11192b;
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.04);
  }

  .list-title {
    margin: 0;
    font-weight: 600;
    font-family: 'SF Mono', Monaco, monospace;
    font-size: 0.9em;
  }

  .list-sub {
    margin: 4px 0 0;
    color: #94a3b8;
    font-size: 13px;
  }

  .chip {
    padding: 6px 10px;
    border-radius: 999px;
    background: #1f2937;
    color: #e2e8f0;
    border: 1px solid rgba(255, 255, 255, 0.08);
  }

  .list-row.slow {
    border-left: 4px solid #ef4444;
  }

  .list-row:not(.slow) {
    border-left: 4px solid #10b981;
  }

  .empty {
    margin: 12px 0 0;
    color: #94a3b8;
  }

  .distrib-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 16px;
    margin-top: 12px;
  }

  .bars-inline {
    display: flex;
    align-items: flex-end;
    gap: 4px;
    height: 140px;
    padding: 12px;
    background: #0d1422;
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.04);
  }

  .bar-mini {
    width: 10px;
    background: linear-gradient(180deg, #34d399, #10b981);
    border-radius: 3px 3px 0 0;
    display: inline-block;
  }

  .improvement-banner {
    background: linear-gradient(135deg, #fbbf24, #f59e0b);
    color: #78350f;
    padding: 20px;
    margin: 18px 30px;
    border-radius: 12px;
    text-align: center;
    font-weight: 600;
  }

  .improvement-highlight {
    background: rgba(255, 255, 255, 0.2);
    padding: 2px 6px;
    border-radius: 4px;
    font-family: 'SF Mono', Monaco, monospace;
    font-size: 0.9em;
  }

  @media (max-width: 640px) {
    .hero {
      flex-direction: column;
      align-items: flex-start;
    }
    .bar-row {
      grid-template-columns: 1fr;
    }
    .bar-meta {
      text-align: left;
    }
  }
</style>

<div class="page">
  <header class="hero">
    <div>
      <p class="eyebrow">TCA Performance Analysis - Improved</p>
      <h1>{metadata.name || 'Untitled'}</h1>
      <p class="sub">Enhanced Human-Readable Output • {metadata.analyzedAt ? new Date(metadata.analyzedAt).toLocaleDateString() : ''}</p>
    </div>
    <div class="score-card {getScoreClass(complexityScore)}">
      <p>Score</p>
      <h2>{complexityScore.toFixed(1)}/100</h2>
    </div>
  </header>

  <div class="improvement-banner">
    ✨ <strong>Cleaner Output:</strong> <span class="improvement-highlight">sidebarSelectionChanged</span> instead of <span class="improvement-highlight">TCAAction</span>
    &nbsp;|&nbsp;
    📊 <strong>Better Features:</strong> <span class="improvement-highlight">ReadingLibrary</span> instead of <span class="improvement-highlight">Action</span>
    &nbsp;|&nbsp;
    💡 <strong>Smart Recommendations:</strong> TCA-specific advice instead of generic tips
  </div>

  <section class="grid kpis">
    <div class="card">
      <p class="label">Total Actions</p>
      <p class="value">{actions.length}</p>
    </div>
    <div class="card">
      <p class="label">Slow Actions</p>
      <p class="value">{slowActions.length}</p>
    </div>
    <div class="card">
      <p class="label">Avg Duration</p>
      <p class="value">{metrics.avgDuration ? formatDuration(metrics.avgDuration) : '0ms'}</p>
    </div>
    <div class="card">
      <p class="label">Max Duration</p>
      <p class="value">{metrics.maxDuration ? formatDuration(metrics.maxDuration) : '0ms'}</p>
    </div>
    <div class="card">
      <p class="label">Features</p>
      <p class="value">{features.length}</p>
    </div>
    <div class="card">
      <p class="label">Effects</p>
      <p class="value">{effects.length}</p>
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>🎯 Clean Actions</h3>
      <p>Real TCA action names and proper feature grouping</p>
    </div>
    <div class="list">
      {#if topSlowActions.length > 0}
        {#each topSlowActions as action}
          <div class="list-row {getActionClass(action)}">
            <div>
              <p class="list-title">{cleanActionName(action.actionName)}</p>
              <p class="list-sub">{action.featureName} • {action.metadata || 'No metadata'}</p>
            </div>
            <div class="chip">{formatDuration(action.duration)}</div>
          </div>
        {/each}
      {:else}
        <p class="empty">No slow actions detected. Great performance!</p>
      {/if}
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>📊 Feature Performance</h3>
      <p>Actions and slow actions per feature</p>
    </div>
    <div class="bars">
      {#each features as [featureName, featureMetrics]}
        <div class="bar-row">
          <div class="bar-label">{featureName}</div>
          <div class="bar-track">
            <div class="bar-fill" style="width: {Math.min(100, (featureMetrics.actionCount || 0) / actions.length * 100)}%"></div>
          </div>
          <div class="bar-meta">
            {(featureMetrics.actionCount || 0)} actions • {(featureMetrics.slowActions || 0)} slow
          </div>
        </div>
      {/each}
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>📈 Action Distribution</h3>
      <p>Duration at a glance</p>
    </div>
    <div style="height: 400px; margin-top: 20px;">
      <canvas id="featureChart"></canvas>
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>⏱️ Timeline Analysis</h3>
      <p>Action bursts over trace time</p>
    </div>
    <div style="height: 400px; margin-top: 20px;">
      <canvas id="timelineChart"></canvas>
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>💡 Enhanced Recommendations</h3>
      <p>TCA-specific performance advice</p>
    </div>
    <div class="list">
      {#if recommendations.length > 0}
        {#each recommendations as recommendation}
          <div class="list-row">
            <div>
              <p class="list-title">{formatRecommendation(recommendation)}</p>
            </div>
          </div>
        {/each}
      {:else}
        <p class="empty">No recommendations. Performance looks good!</p>
      {/if}
    </div>
  </section>

  <section class="panel">
    <div class="panel-header">
      <h3>🏗️ Effect Analysis</h3>
      <p>Long-running effects and patterns</p>
    </div>
    <div class="list">
      {#if effects.length > 0}
        {#each effects.slice(0, 5) as effect}
          <div class="list-row">
            <div>
              <p class="list-title">{effect.name}</p>
              <p class="list-sub">{effect.featureName} • {formatDuration(effect.duration)}</p>
            </div>
            <div class="chip">{effect.duration > 0.5 ? 'Long-running' : 'Normal'}</div>
          </div>
        {/each}
      {:else}
        <p class="empty">No effects detected</p>
      {/if}
    </div>
  </section>
</div>