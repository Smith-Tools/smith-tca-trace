import Foundation

/// HTML formatting for interactive visualizations
@available(macOS 14, *)
struct HTMLFormatter: Sendable {
    /// Generate interactive HTML visualization
    static func generateInteractiveHTML(_ analysis: TraceAnalysis) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let analysisJSON = String(data: try! encoder.encode(analysis), encoding: .utf8) ?? "{}"

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>TCA Performance Analysis: \(analysis.metadata.name)</title>
            <style>
                :root { color: #0f172a; background: #0f1623; font-family: 'Inter','SF Pro Display', system-ui, -apple-system, sans-serif; }
                * { box-sizing: border-box; }
                body { margin: 0; background: radial-gradient(circle at 20% 20%, #182338, #0f1623 50%), #0f1623; color: #e2e8f0; }
                .page { max-width: 1180px; margin: 32px auto 64px; padding: 0 20px 40px; }
                .hero { display:flex; justify-content: space-between; gap:16px; padding:24px 28px; border-radius:18px;
                        background: linear-gradient(135deg,#5b7bff 0%, #8a7bff 40%, #2dd4bf 100%); color:#0b1020;
                        box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
                .hero h1 { margin:6px 0; font-size:32px; }
                .hero .sub { margin:0; opacity:0.8; }
                .eyebrow { margin:0; text-transform:uppercase; letter-spacing:0.18em; font-size:11px; opacity:0.8; }
                .score { background: rgba(255,255,255,0.9); padding:14px 18px; border-radius:14px; min-width:150px;
                         text-align:right; color:#0f172a; box-shadow: inset 0 1px 0 rgba(255,255,255,0.5); }
                .score h2 { margin:6px 0 0; font-size:28px; }
                .score p { margin:0; font-size:12px; letter-spacing:0.06em; text-transform:uppercase; }
                .kpis { display:grid; grid-template-columns: repeat(auto-fit,minmax(160px,1fr)); gap:14px; margin:18px 0 24px; }
                .card { padding:16px 18px; background:#121a2b; border:1px solid rgba(255,255,255,0.04); border-radius:12px;
                        box-shadow:0 10px 30px rgba(0,0,0,0.25); }
                .label { margin:0 0 6px; font-size:12px; letter-spacing:0.04em; color:#94a3b8; }
                .value { margin:0; font-size:24px; font-weight:700; color:#e2e8f0; }
                .panel { background:#0f172a; border:1px solid rgba(255,255,255,0.04); border-radius:14px; margin-bottom:18px; padding:18px;
                         box-shadow:0 10px 34px rgba(0,0,0,0.28); }
                .panel-header h3 { margin:0; }
                .panel-header p { margin:4px 0 0; color:#94a3b8; }
                .bars { display:flex; flex-direction:column; gap:12px; margin-top:12px; }
                .bar-row { display:grid; grid-template-columns: 160px 1fr 120px; align-items:center; gap:10px; }
                .bar-label { font-weight:600; }
                .bar-track { height:12px; background:#162239; border-radius:999px; overflow:hidden; }
                .bar-fill { height:100%; background: linear-gradient(90deg,#3b82f6,#22d3ee); }
                .bar-meta { color:#94a3b8; font-size:13px; text-align:right; }
                .list { display:flex; flex-direction:column; gap:10px; margin-top:12px; }
                .list-row { display:flex; align-items:center; justify-content:space-between; gap:12px; padding:12px; background:#11192b;
                            border-radius:10px; border:1px solid rgba(255,255,255,0.04); }
                .list-title { margin:0; font-weight:600; }
                .list-sub { margin:4px 0 0; color:#94a3b8; font-size:13px; }
                .chip { padding:6px 10px; border-radius:999px; background:#1f2937; color:#e2e8f0; border:1px solid rgba(255,255,255,0.08); }
                .empty { margin:12px 0 0; color:#94a3b8; }
                .distrib-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:16px; margin-top:12px; }
                #obs-grid div { box-sizing:border-box; }
                .plot-box { background:#0d1422; border-radius:10px; padding:4px; min-height:240px; border:1px solid rgba(255,255,255,0.04); }
                @media (max-width:640px){ .hero{flex-direction:column; align-items:flex-start;} .bar-row{grid-template-columns:1fr;} .bar-meta{text-align:left;} }
            </style>
        </head>
        <body>
            <main class="page">
              <section class="hero">
                <div>
                  <p class="eyebrow">TCA Performance Analysis</p>
                  <h1>\(analysis.metadata.name)</h1>
                  <p class="sub">Duration \(String(format: "%.2f", analysis.duration)) s</p>
                </div>
                <div class="score">
                  <p>Score</p>
                  <h2>\(String(format: "%.1f", analysis.complexityScore))/100</h2>
                </div>
              </section>
              <section class="kpis" id="kpis"></section>
              <section class="panel">
                <div class="panel-header"><h3>Feature Load</h3><p>Actions & slow actions per feature</p></div>
                <div class="bars" id="feature-bars"></div>
              </section>
              <section class="panel">
                <div class="panel-header"><h3>Slowest Actions</h3><p>Top offenders by duration</p></div>
                <div id="slow-list" class="list"></div>
              </section>
              <section class="panel">
                <div class="panel-header"><h3>Effect Hotspots</h3><p>Effects longer than 500ms</p></div>
                <div id="effect-list" class="list"></div>
              </section>
              <section class="panel">
                <div class="panel-header"><h3>Observable Notebook Views</h3><p>Inline Observable/Plot charts</p></div>
                <div id="obs-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:16px;">
                  <div class="plot-box" id="obs-actions-hist"></div>
                  <div class="plot-box" id="obs-effects-hist"></div>
                  <div class="plot-box" id="obs-timeline"></div>
                </div>
              </section>
            </main>

            <script type="module">
              import {Runtime, Inspector} from "https://cdn.jsdelivr.net/npm/@observablehq/runtime@5/dist/runtime.js";
              import * as Plot from "https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6/dist/plot.umd.min.js";
              const data = \(analysisJSON);
              const actionsRaw = data.actions || [];
              const effectsRaw = data.effects || [];

              const actions = actionsRaw
                .map(a => ({...a, d: Number(a.duration) || 0, t: Number(a.timestamp) || 0}))
                .filter(a => Number.isFinite(a.d) && Number.isFinite(a.t));

              const effects = effectsRaw
                .map(e => {
                  const dur = Number(e.endTime) - Number(e.startTime);
                  return {...e, duration: dur, d: dur, t: Number(e.startTime) || 0};
                })
                .filter(e => Number.isFinite(e.d) && Number.isFinite(e.t));
              const totalDuration = data.duration || 1;
              const metrics = data.metrics || {};

              const el = (tag, cls, text) => { const n=document.createElement(tag); if(cls) n.className=cls; if(text) n.textContent=text; return n; };
              // KPIs
              const kpiRoot = document.getElementById('kpis');
              const kpis = [
                {label:'Total Actions', value: metrics.totalActions ?? actions.length},
                {label:'Slow Actions', value: metrics.slowActions ?? 0},
                {label:'Avg Duration', value: `${((metrics.avgDuration ?? 0)*1000).toFixed(1)} ms`},
                {label:'Total Duration', value: `${(data.duration ?? 0).toFixed(2)} s`},
                {label:'Features', value: Object.keys(metrics.features || {}).length},
                {label:'Effects', value: effects.length}
              ];
              kpis.forEach(k => {
                const c=el('div','card');
                c.append(el('p','label',k.label));
                c.append(el('p','value',String(k.value)));
                kpiRoot.append(c);
              });

              // Feature bars
              const featureRoot = document.getElementById('feature-bars');
              const features = Object.entries(metrics.features || {});
              const totalActs = metrics.totalActions || actions.length || 1;
              features.forEach(([name,m])=>{
                const row = el('div','bar-row');
                row.append(el('div','bar-label',name));
                const track = el('div','bar-track');
                const fill = el('div','bar-fill');
                const width = Math.min(100, ((m.actionCount||0)/totalActs)*100);
                fill.style.width = width + '%';
                track.append(fill);
                row.append(track);
                row.append(el('div','bar-meta',`${m.actionCount||0} actions · ${m.slowActions||0} slow`));
                featureRoot.append(row);
              });

              // Slow actions
              const slowList = document.getElementById('slow-list');
              const slowActions = actions.filter(a => a.duration > 0.016).sort((a,b)=>b.duration-a.duration).slice(0,12);
              if(!slowActions.length) slowList.append(el('p','empty','No slow actions.'));
              slowActions.forEach(a=>{
                const row=el('div','list-row');
                const left=el('div');
                left.append(el('p','list-title',`${a.featureName}.${a.actionName}`));
                left.append(el('p','list-sub',(a.metadata||'').replace(/%s/g,'').trim() || '—'));
                row.append(left);
                row.append(el('div','chip',`${(a.duration*1000).toFixed(1)} ms`));
                slowList.append(row);
              });

              // Effect hotspots
              const effectList = document.getElementById('effect-list');
              const hot = effects.filter(e=>e.duration>0.5).sort((a,b)=>b.duration-a.duration).slice(0,12);
              if(!hot.length) effectList.append(el('p','empty','No long-running effects (>500ms).'));
              hot.forEach(e=>{
                const row=el('div','list-row');
                const left=el('div');
                left.append(el('p','list-title',`${e.featureName}.${e.name}`));
                left.append(el('p','list-sub',(e.metadata||'').replace(/%s/g,'').trim() || '—'));
                row.append(left);
                row.append(el('div','chip',`${(e.duration*1000).toFixed(1)} ms`));
                effectList.append(row);
              });

              // Observable Plot charts
              const runtime = new Runtime();
              const main = runtime.module();
              const emptyMsg = (msg) => { const p=document.createElement("p"); p.style.color="#94a3b8"; p.style.margin="8px"; p.textContent=msg; return p; };

              main.variable(Inspector(document.querySelector("#obs-actions-hist"))).define("actionsHistogram", () => {
                if(!actions.length) return emptyMsg("No actions");
                const finite = actions.filter(a => Number.isFinite(a.d));
                if(!finite.length) return emptyMsg("No numeric durations");
                return Plot.plot({
                  height:220, marginLeft:40, marginBottom:35,
                  x:{label:"Duration (s)", grid:true},
                  y:{label:"Count"},
                  color:{scheme:"blues"},
                  marks:[
                    Plot.rectY(finite, Plot.binX({y:"count"}, {x:"d", thresholds:30})),
                    Plot.ruleY([0])
                  ]
                });
              });

              main.variable(Inspector(document.querySelector("#obs-effects-hist"))).define("effectsHistogram", () => {
                if(!effects.length) return emptyMsg("No effects");
                const finite = effects.filter(e => Number.isFinite(e.d));
                if(!finite.length) return emptyMsg("No numeric durations");
                return Plot.plot({
                  height:220, marginLeft:40, marginBottom:35,
                  x:{label:"Duration (s)", grid:true},
                  y:{label:"Count"},
                  color:{scheme:"teals"},
                  marks:[
                    Plot.rectY(finite, Plot.binX({y:"count"}, {x:"d", thresholds:30})),
                    Plot.ruleY([0])
                  ]
                });
              });

              main.variable(Inspector(document.querySelector("#obs-timeline"))).define("timelineDensity", () => {
                if(!actions.length) return emptyMsg("No actions");
                const finite = actions.filter(a => Number.isFinite(a.t));
                if(!finite.length) return emptyMsg("No numeric timestamps");
                return Plot.plot({
                  height:220, marginLeft:40, marginBottom:35,
                  x:{label:"Trace time (s)", domain:[0,totalDuration], grid:true},
                  y:{label:"Count"},
                  color:{scheme:"pinks"},
                  marks:[
                    Plot.rectY(finite, Plot.binX({y:"count"}, {x:"t", thresholds:25})),
                    Plot.ruleY([0])
                  ]
                });
              });
            </script>
        </body>
        </html>
        """
    }
}
