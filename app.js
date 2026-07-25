const metricKeys=["results","cost","budget","spent","impressions","reach"];
const moneyKeys=["cost","budget","spent"];
const months=["January","February","March","April","May","June","July","August","September","October","November","December"];
const emptyMetrics=()=>({results:0,cost:0,budget:0,spent:0,impressions:0,reach:0});
const defaults=[
 {name:"Healbite Animal Bite Clinic – Pasig",short:"Pasig",...emptyMetrics()},
 {name:"Healbite Animal Bite Clinic – Mandaluyong",short:"Mandaluyong",...emptyMetrics()}
];

let state=JSON.parse(localStorage.getItem("healbite-dashboard")||"null")||{};
if(!Array.isArray(state.clinics))state.clinics=[];
state.clinics=defaults.map((base,i)=>({...base,...(state.clinics[i]&&typeof state.clinics[i]==="object"?state.clinics[i]:{})}));
state.startDate=state.startDate||"";
state.endDate=state.endDate||"";
if(!Array.isArray(state.monthly))state.monthly=[];
state.monthly=months.map((month,i)=>({
 month,
 pasig:{...emptyMetrics(),...(state.monthly[i]?.pasig||{})},
 mandaluyong:{...emptyMetrics(),...(state.monthly[i]?.mandaluyong||{})}
}));
delete state.period;
let editing=false;

const peso=n=>new Intl.NumberFormat("en-PH",{style:"currency",currency:"PHP",maximumFractionDigits:2}).format(n||0);
const count=n=>new Intl.NumberFormat("en-PH").format(n||0);
const total=key=>state.clinics.reduce((sum,c)=>sum+Number(c[key]||0),0);
const formatMetric=(key,value)=>moneyKeys.includes(key)?peso(value):count(value);
function totals(){const results=total("results"),spent=total("spent");return{results,cost:results?spent/results:0,budget:total("budget"),spent,impressions:total("impressions"),reach:total("reach")}}
function dateLabel(){if(!state.startDate&&!state.endDate)return"Choose a date range";const nice=d=>d?new Date(d+"T00:00:00").toLocaleDateString("en-PH",{month:"short",day:"numeric",year:"numeric"}):"—";return`${nice(state.startDate)} – ${nice(state.endDate)}`}

function ensureMonthlySection(){
 if(document.getElementById("monthlyPanel"))return;
 const panel=document.createElement("section");
 panel.id="monthlyPanel";
 panel.className="panel monthly-panel";
 panel.innerHTML=`
  <div class="panel-head"><div><h2>Monthly comparison</h2><p>Complete January–December performance by clinic</p></div><span class="chip">Pasig vs Mandaluyong</span></div>
  <div class="table-wrap monthly-wrap"><table class="monthly-table">
   <thead>
    <tr><th rowspan="2">Month</th><th colspan="6" class="clinic-group pasig-group">Pasig</th><th colspan="6" class="clinic-group manda-group">Mandaluyong</th></tr>
    <tr>${metricKeys.map(k=>`<th>${metricLabel(k)}</th>`).join("")}${metricKeys.map(k=>`<th>${metricLabel(k)}</th>`).join("")}</tr>
   </thead>
   <tbody id="monthlyRows"></tbody><tfoot id="monthlyTotals"></tfoot>
  </table></div>`;
 document.querySelector(".utilization").before(panel);
 const style=document.createElement("style");
 style.textContent=`
  .monthly-panel{overflow:hidden}.monthly-wrap{max-height:600px}.monthly-table{min-width:1700px}
  .monthly-table thead{position:sticky;top:0;z-index:2}.monthly-table th{white-space:nowrap}
  .monthly-table th:first-child,.monthly-table td:first-child{position:sticky;left:0;z-index:1;background:#0d1117}
  .monthly-table td:first-child{font-weight:700;color:#e6edf3}.clinic-group{text-align:center!important;font-size:12px!important}
  .pasig-group{color:#7ee787!important;background:#12351f!important}.manda-group{color:#79c0ff!important;background:#112b46!important}
  .monthly-table tbody tr:hover td{background:#1c2128}.monthly-table tbody tr:hover td:first-child{background:#161b22}
  .monthly-cell{width:92px;color:#e6edf3;text-align:right;background:#0d1117;border:1px solid #58a6ff;border-radius:5px;padding:7px}
  .monthly-table tfoot td{position:static;background:#2ea04312}.monthly-table tfoot td:first-child{position:sticky;left:0;background:#17351f}
 `;
 document.head.appendChild(style);
}
function metricLabel(key){return({results:"Results",cost:"Cost / result",budget:"Budget",spent:"Amount spent",impressions:"Impressions",reach:"Reach"})[key]}
function monthlyCell(monthIndex,clinic,key,value){
 return editing?`<input class="monthly-cell" type="number" min="0" data-month="${monthIndex}" data-clinic="${clinic}" data-key="${key}" value="${value}">`:formatMetric(key,value);
}
function monthlyAggregate(clinic,key){
 if(key==="cost"){const results=state.monthly.reduce((s,m)=>s+Number(m[clinic].results||0),0),spent=state.monthly.reduce((s,m)=>s+Number(m[clinic].spent||0),0);return results?spent/results:0}
 return state.monthly.reduce((sum,m)=>sum+Number(m[clinic][key]||0),0);
}
function renderMonthly(){
 ensureMonthlySection();
 monthlyRows.innerHTML=state.monthly.map((m,i)=>`<tr><td>${m.month}</td>${metricKeys.map(k=>`<td>${monthlyCell(i,"pasig",k,m.pasig[k])}</td>`).join("")}${metricKeys.map(k=>`<td>${monthlyCell(i,"mandaluyong",k,m.mandaluyong[k])}</td>`).join("")}</tr>`).join("");
 monthlyTotals.innerHTML=`<tr><td>FULL YEAR</td>${metricKeys.map(k=>`<td>${formatMetric(k,monthlyAggregate("pasig",k))}</td>`).join("")}${metricKeys.map(k=>`<td>${formatMetric(k,monthlyAggregate("mandaluyong",k))}</td>`).join("")}</tr>`;
 document.querySelectorAll(".monthly-cell").forEach(el=>el.oninput=e=>{state.monthly[Number(e.target.dataset.month)][e.target.dataset.clinic][e.target.dataset.key]=Number(e.target.value)||0});
}

function render(){
 const t=totals(),pct=t.budget?Math.round(t.spent/t.budget*100):0;
 const cards=[["Results",count(t.results),"Total ad results"],["Cost per result",peso(t.cost),"Weighted average"],["Budget",peso(t.budget),"Total allocated"],["Amount spent",peso(t.spent),pct+"% of budget"],["Impressions",count(t.impressions),"Total ad views"],["Reach",count(t.reach),"Unique audience"]];
 metrics.innerHTML=cards.map(x=>`<article class="card"><label>${x[0]}</label><strong>${x[1]}</strong><small>${x[2]}</small></article>`).join("");
 startDate.value=state.startDate;endDate.value=state.endDate;startDate.disabled=!editing;endDate.disabled=!editing;periodChip.textContent=dateLabel();
 clinicRows.innerHTML=state.clinics.map((c,i)=>`<tr><td><strong>${c.short}</strong><br><small>${c.name}</small></td>${metricKeys.map(k=>`<td>${editing?`<input class="cell" type="number" min="0" data-i="${i}" data-k="${k}" value="${c[k]}">`:formatMetric(k,c[k])}</td>`).join("")}</tr>`).join("");
 totalsRow.innerHTML=`<tr><td>Total</td><td>${count(t.results)}</td><td>${peso(t.cost)}</td><td>${peso(t.budget)}</td><td>${peso(t.spent)}</td><td>${count(t.impressions)}</td><td>${count(t.reach)}</td></tr>`;
 bars.innerHTML=state.clinics.map(c=>{const p=c.budget?Math.min(100,c.spent/c.budget*100):0;return`<div class="bar-row"><div class="bar-label"><strong>${c.short}</strong><span>${peso(c.spent)} / ${peso(c.budget)}</span></div><div class="bar"><i style="width:${p}%"></i></div><b>${Math.round(p)}%</b></div>`}).join("");
 document.querySelectorAll(".cell").forEach(el=>el.oninput=e=>{state.clinics[e.target.dataset.i][e.target.dataset.k]=Number(e.target.value)||0});
 renderMonthly();
 editBtn.textContent=editing?"Save dashboard":"Edit data";
}
editBtn.onclick=()=>{if(editing){state.startDate=startDate.value;state.endDate=endDate.value;localStorage.setItem("healbite-dashboard",JSON.stringify(state))}editing=!editing;render()};
render();
