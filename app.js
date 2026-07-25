const defaults=[
 {name:"Healbite Animal Bite Clinic – Pasig",short:"Pasig",results:0,cost:0,budget:0,spent:0,impressions:0,reach:0},
 {name:"Healbite Animal Bite Clinic – Mandaluyong",short:"Mandaluyong",results:0,cost:0,budget:0,spent:0,impressions:0,reach:0}
];
let state=JSON.parse(localStorage.getItem("healbite-dashboard")||"null")||{clinics:defaults,startDate:"",endDate:""};
state.startDate=state.startDate||"";
state.endDate=state.endDate||"";
delete state.period;
let editing=false;
const peso=n=>new Intl.NumberFormat("en-PH",{style:"currency",currency:"PHP",maximumFractionDigits:2}).format(n||0);
const count=n=>new Intl.NumberFormat("en-PH").format(n||0);
const total=key=>state.clinics.reduce((sum,c)=>sum+Number(c[key]||0),0);
function totals(){const results=total("results"),spent=total("spent");return{results,cost:results?spent/results:0,budget:total("budget"),spent,impressions:total("impressions"),reach:total("reach")}}
function dateLabel(){if(!state.startDate&&!state.endDate)return"Choose a date range";const nice=d=>d?new Date(d+"T00:00:00").toLocaleDateString("en-PH",{month:"short",day:"numeric",year:"numeric"}):"—";return`${nice(state.startDate)} – ${nice(state.endDate)}`}
function render(){
 const t=totals(),pct=t.budget?Math.round(t.spent/t.budget*100):0;
 const cards=[["Results",count(t.results),"Total ad results"],["Cost per result",peso(t.cost),"Weighted average"],["Budget",peso(t.budget),"Total allocated"],["Amount spent",peso(t.spent),pct+"% of budget"],["Impressions",count(t.impressions),"Total ad views"],["Reach",count(t.reach),"Unique audience"]];
 metrics.innerHTML=cards.map(x=>`<article class="card"><label>${x[0]}</label><strong>${x[1]}</strong><small>${x[2]}</small></article>`).join("");
 startDate.value=state.startDate;endDate.value=state.endDate;startDate.disabled=!editing;endDate.disabled=!editing;periodChip.textContent=dateLabel();
 clinicRows.innerHTML=state.clinics.map((c,i)=>`<tr><td><strong>${c.short}</strong><br><small>${c.name}</small></td>${["results","cost","budget","spent","impressions","reach"].map(k=>`<td>${editing?`<input class="cell" type="number" min="0" data-i="${i}" data-k="${k}" value="${c[k]}">`:["cost","budget","spent"].includes(k)?peso(c[k]):count(c[k])}</td>`).join("")}</tr>`).join("");
 totalsRow.innerHTML=`<tr><td>Total</td><td>${count(t.results)}</td><td>${peso(t.cost)}</td><td>${peso(t.budget)}</td><td>${peso(t.spent)}</td><td>${count(t.impressions)}</td><td>${count(t.reach)}</td></tr>`;
 bars.innerHTML=state.clinics.map(c=>{const p=c.budget?Math.min(100,c.spent/c.budget*100):0;return`<div class="bar-row"><div class="bar-label"><strong>${c.short}</strong><span>${peso(c.spent)} / ${peso(c.budget)}</span></div><div class="bar"><i style="width:${p}%"></i></div><b>${Math.round(p)}%</b></div>`}).join("");
 document.querySelectorAll(".cell").forEach(el=>el.oninput=e=>{state.clinics[e.target.dataset.i][e.target.dataset.k]=Number(e.target.value)||0});
 editBtn.textContent=editing?"Save dashboard":"Edit data";
}
editBtn.onclick=()=>{if(editing){state.startDate=startDate.value;state.endDate=endDate.value;localStorage.setItem("healbite-dashboard",JSON.stringify(state))}editing=!editing;render()};
render();
