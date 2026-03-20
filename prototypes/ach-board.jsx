import { useState, useCallback, useRef, useEffect, useMemo } from "react";

const uid = () => Math.random().toString(36).slice(2, 10);

/* ═══ CONFIG ═══ */
const RATINGS = [
  { key: "CC", emoji: "💚", word: "strongly supports", short: "Strong yes", val: 2, bg: "rgba(126,196,155,0.16)", border: "rgba(126,196,155,0.32)", text: "#7EC49B" },
  { key: "C",  emoji: "👍", word: "supports",          short: "Yes",        val: 1, bg: "rgba(168,213,160,0.11)", border: "rgba(168,213,160,0.24)", text: "#A0CFA0" },
  { key: "N",  emoji: "🤷", word: "irrelevant",        short: "Irrelevant", val: 0, bg: "rgba(154,146,138,0.09)", border: "rgba(154,146,138,0.18)", text: "#8A8278" },
  { key: "I",  emoji: "👎", word: "contradicts",       short: "No",         val: -1,bg: "rgba(232,196,122,0.12)", border: "rgba(232,196,122,0.26)", text: "#E8C47A" },
  { key: "II", emoji: "🚫", word: "strongly contradicts",short:"Strong no",  val: -2,bg: "rgba(212,116,106,0.16)", border: "rgba(212,116,106,0.32)", text: "#D4746A" },
];
const RM = Object.fromEntries(RATINGS.map(r => [r.key, r]));
const HC = ["#EF8B6E","#5CC4B8","#7E9BE0","#E8C47A","#C490D4","#6EC4A0","#D4746A"];
const WV = { H: 3, M: 2, L: 1 };
const WL = { H: "High", M: "Med", L: "Low" };
const FONT = "https://fonts.googleapis.com/css2?family=Figtree:wght@400;500;600;700;800;900&display=swap";

/* ═══ STORAGE ═══ */
const LS = "wi-list", AB = "wi-active";
const bKey = id => `wi-b-${id}`;

async function sGet(k) { try { const r = await window.storage.get(k); return r ? JSON.parse(r.value) : null; } catch { return null; } }
async function sSet(k, v) { try { await window.storage.set(k, JSON.stringify(v)); } catch {} }
async function sDel(k) { try { await window.storage.delete(k); } catch {} }

function freshBoard(withExample) {
  if (!withExample) return { id: uid(), q: "", hyps: [{ id: uid(), name: "", color: HC[0], out: false }, { id: uid(), name: "", color: HC[1], out: false }], evs: [{ id: uid(), text: "", cred: "M", rel: "M" }], mx: {}, notes: {}, conclusion: "" };
  const h1=uid(),h2=uid(),h3=uid(),e1=uid(),e2=uid(),e3=uid(),e4=uid();
  return { id: uid(), q: "Why did our latest product launch underperform?", hyps: [
    { id:h1, name:"Marketing didn't reach the right audience", color:HC[0], out:false },
    { id:h2, name:"The product has usability issues", color:HC[1], out:false },
    { id:h3, name:"Pricing is too high for the market", color:HC[2], out:false }],
    evs: [{ id:e1, text:"Social media impressions were up 40%", cred:"H", rel:"H" },
      { id:e2, text:"Support tickets doubled in the first week", cred:"H", rel:"H" },
      { id:e3, text:"Competitors priced 20% lower", cred:"M", rel:"H" },
      { id:e4, text:"Users who finished onboarding had great retention", cred:"M", rel:"M" }],
    mx:{[`${e1}-${h1}`]:"I",[`${e2}-${h2}`]:"CC",[`${e3}-${h3}`]:"CC",[`${e3}-${h1}`]:"N",[`${e4}-${h2}`]:"I"},
    notes:{[`${e1}-${h1}`]:"Impressions up = marketing DID reach people",[`${e2}-${h2}`]:"Support tickets = confused users",[`${e4}-${h2}`]:"Good retention after onboarding → maybe onboarding issue, not product"},
    conclusion:"" };
}

/* ═══ SHARED STYLES ═══ */
const card = {
  background: "rgba(255,255,255,0.03)",
  backdropFilter: "blur(12px)", WebkitBackdropFilter: "blur(12px)",
  border: "1px solid rgba(255,255,255,0.06)", borderRadius: 20,
  padding: "22px 26px", marginBottom: 16,
  boxShadow: "0 2px 20px rgba(0,0,0,0.12), inset 0 1px 0 rgba(255,255,255,0.04)",
};

/* ═══ PROGRESS RING ═══ */
function ProgressRing({ pct, size = 38, stroke = 3 }) {
  const r = (size - stroke) / 2, circ = 2 * Math.PI * r;
  const done = pct === 100;
  return (
    <svg width={size} height={size} style={{ transform: "rotate(-90deg)", transition: "all 0.3s" }}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth={stroke} />
      <circle cx={size/2} cy={size/2} r={r} fill="none"
        stroke={done ? "#7EC49B" : "#EF8B6E"}
        strokeWidth={stroke} strokeLinecap="round"
        strokeDasharray={circ} strokeDashoffset={circ - (pct / 100) * circ}
        style={{ transition: "stroke-dashoffset 0.6s cubic-bezier(0.4,0,0.2,1), stroke 0.3s" }} />
      <text x={size/2} y={size/2} textAnchor="middle" dominantBaseline="central"
        style={{ transform: "rotate(90deg)", transformOrigin: "center", fontSize: 10, fontWeight: 800, fill: done ? "#7EC49B" : "#EF8B6E", fontFamily: "inherit" }}>
        {pct}
      </text>
    </svg>
  );
}

/* ═══ CONFETTI ═══ */
function Confetti({ active }) {
  const particles = useMemo(() => Array.from({ length: 40 }, (_, i) => ({
    x: Math.random() * 100, delay: Math.random() * 0.5,
    dur: 1.2 + Math.random() * 0.8, size: 4 + Math.random() * 6,
    color: HC[Math.floor(Math.random() * HC.length)],
    drift: (Math.random() - 0.5) * 80,
  })), []);
  if (!active) return null;
  return (
    <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, pointerEvents: "none", zIndex: 9999, overflow: "hidden" }}>
      {particles.map((p, i) => (
        <div key={i} style={{
          position: "absolute", left: `${p.x}%`, top: -20,
          width: p.size, height: p.size, borderRadius: p.size > 7 ? 2 : "50%",
          background: p.color, opacity: 0,
          animation: `confettiFall ${p.dur}s ease-out ${p.delay}s forwards`,
          "--drift": `${p.drift}px`,
        }} />
      ))}
    </div>
  );
}

/* ═══ ANIMATED NUMBER ═══ */
function AnimNum({ value, color }) {
  const [display, setDisplay] = useState(value);
  const prev = useRef(value);
  useEffect(() => {
    const from = prev.current, to = value;
    if (from === to) return;
    let start = null;
    const dur = 400;
    const step = (ts) => {
      if (!start) start = ts;
      const t = Math.min((ts - start) / dur, 1);
      const ease = 1 - Math.pow(1 - t, 3);
      setDisplay(Math.round(from + (to - from) * ease));
      if (t < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
    prev.current = to;
  }, [value]);
  return <span style={{ fontSize: 18, fontWeight: 800, color, minWidth: 50, textAlign: "right", display: "inline-block", fontFamily: "inherit", fontVariantNumeric: "tabular-nums" }}>{display > 0 ? "+" : ""}{display}</span>;
}

/* ═══ POPOVER ═══ */
function Popover({ cellKey, cur, pos, onPick, onClose, onNote }) {
  const ref = useRef(null);
  useEffect(() => {
    const h = e => { if (ref.current && !ref.current.contains(e.target)) onClose(); };
    document.addEventListener("mousedown", h); return () => document.removeEventListener("mousedown", h);
  }, [onClose]);
  const isMobile = window.innerWidth < 640;
  const style = isMobile
    ? { position: "fixed", bottom: 0, left: 0, right: 0, zIndex: 9999, animation: "sheetUp 0.2s ease both" }
    : { position: "fixed", top: Math.min(pos.top, window.innerHeight - 330), left: Math.min(pos.left, window.innerWidth - 210), zIndex: 9999, animation: "popIn 0.15s ease both" };
  return (
    <div ref={ref} style={style}>
      <div style={{
        background: "#1E1C1A", border: "1px solid rgba(255,255,255,0.10)",
        borderRadius: isMobile ? "20px 20px 0 0" : 14, padding: isMobile ? "12px 8px 24px" : 6,
        boxShadow: "0 12px 48px rgba(0,0,0,0.6)", display: "flex", flexDirection: "column", gap: 2, minWidth: isMobile ? "auto" : 190,
      }}>
        {isMobile && <div style={{ width: 36, height: 4, borderRadius: 2, background: "rgba(255,255,255,0.15)", margin: "0 auto 8px" }} />}
        {RATINGS.map(r => {
          const active = cur === r.key;
          return (
            <button key={r.key} onClick={() => { onPick(r.key); onClose(); }}
              style={{ display: "flex", alignItems: "center", gap: 10, padding: isMobile ? "12px 16px" : "9px 14px", background: active ? r.bg : "transparent", border: "none", borderRadius: 10, cursor: "pointer", fontFamily: "inherit", transition: "all 0.12s", outline: active ? `1px solid ${r.border}` : "1px solid transparent" }}
              onMouseEnter={e => { if (!active) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
              onMouseLeave={e => { if (!active) e.currentTarget.style.background = "transparent"; }}>
              <span style={{ fontSize: isMobile ? 22 : 18, width: 28, textAlign: "center" }}>{r.emoji}</span>
              <span style={{ fontSize: isMobile ? 15 : 13, fontWeight: 600, color: r.text, flex: 1 }}>{r.short}</span>
              {active && <span style={{ fontSize: 11, color: r.text }}>✓</span>}
            </button>
          );
        })}
        <div style={{ height: 1, background: "rgba(255,255,255,0.06)", margin: "2px 6px" }} />
        {cur && (
          <button onClick={() => { onPick(""); onClose(); }}
            style={{ display: "flex", alignItems: "center", gap: 10, padding: isMobile ? "12px 16px" : "8px 14px", background: "transparent", border: "none", borderRadius: 10, cursor: "pointer", fontFamily: "inherit" }}
            onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.04)"}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
            <span style={{ fontSize: 14, width: 28, textAlign: "center", color: "#5A544E" }}>⌫</span>
            <span style={{ fontSize: 13, fontWeight: 500, color: "#6A6460" }}>Clear</span>
          </button>
        )}
        <button onClick={() => { onNote(); onClose(); }}
          style={{ display: "flex", alignItems: "center", gap: 10, padding: isMobile ? "12px 16px" : "8px 14px", background: "transparent", border: "none", borderRadius: 10, cursor: "pointer", fontFamily: "inherit" }}
          onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.04)"}
          onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
          <span style={{ fontSize: 14, width: 28, textAlign: "center" }}>📝</span>
          <span style={{ fontSize: 13, fontWeight: 500, color: "#9A928A" }}>Add note</span>
        </button>
      </div>
    </div>
  );
}

/* ═══ CELL ═══ */
function Cell({ rk, hasNote, onOpen, dimmed, justChanged }) {
  const [hov, setHov] = useState(false);
  const r = RM[rk]; const empty = !rk;
  return (
    <td onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)} onClick={dimmed ? undefined : onOpen}
      style={{
        textAlign: "center", padding: 0, position: "relative",
        minWidth: 100, height: 66, transition: "background 0.2s, opacity 0.2s, box-shadow 0.3s",
        userSelect: "none", cursor: dimmed ? "default" : "pointer",
        background: dimmed ? "rgba(255,255,255,0.01)" : empty ? (hov ? "rgba(255,255,255,0.05)" : "rgba(255,255,255,0.015)") : r.bg,
        borderRight: "1px solid rgba(255,255,255,0.04)", borderBottom: "1px solid rgba(255,255,255,0.04)",
        boxShadow: !empty && !dimmed ? `inset 0 0 20px ${r.border}` : "none",
        opacity: dimmed ? 0.25 : 1,
        animation: justChanged ? "cellPop 0.35s cubic-bezier(0.34,1.56,0.64,1)" : "none",
      }}>
      {empty ? (
        <span style={{ fontSize: 22, color: hov && !dimmed ? "rgba(255,255,255,0.25)" : "rgba(255,255,255,0.06)", transition: "all 0.2s" }}>+</span>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: "100%", gap: 2 }}>
          <span style={{ fontSize: 21, lineHeight: 1 }}>{r.emoji}</span>
          <span style={{ fontSize: 9.5, color: r.text, fontWeight: 600, letterSpacing: 0.3, opacity: 0.9 }}>{r.word}</span>
        </div>
      )}
      {hasNote && !dimmed && <span style={{ position: "absolute", top: 3, right: 4, fontSize: 9, color: "#EF8B6E", opacity: 0.8 }}>📝</span>}
    </td>
  );
}

/* ═══ EDITABLE ═══ */
function Ed({ value, onChange, ph, style: s }) {
  const [on, setOn] = useState(false);
  const [d, setD] = useState(value);
  const r = useRef(null);
  useEffect(() => setD(value), [value]);
  useEffect(() => { if (on && r.current) { r.current.focus(); r.current.select(); } }, [on]);
  if (on) return <input ref={r} value={d} onChange={e => setD(e.target.value)} onBlur={() => { onChange(d || value); setOn(false); }} onKeyDown={e => { if (e.key === "Enter") { onChange(d || value); setOn(false); } if (e.key === "Escape") setOn(false); }} style={{ ...s, background: "rgba(255,255,255,0.06)", border: "1.5px solid #EF8B6E", borderRadius: 8, padding: "5px 10px", outline: "none", width: "100%", boxSizing: "border-box", fontFamily: "inherit", color: "#F0EBE6" }} placeholder={ph} />;
  return <span onClick={() => setOn(true)} style={{ ...s, cursor: "text", borderBottom: "1.5px dashed rgba(255,255,255,0.10)", paddingBottom: 1 }} title="Click to edit">{value || <span style={{ color: "#4A4440", fontStyle: "italic" }}>{ph}</span>}</span>;
}

/* ═══ BOARD SWITCHER ═══ */
function BoardSwitcher({ boards, activeId, onSwitch, onNew, onDelete }) {
  const [open, setOpen] = useState(false);
  const ref = useRef(null);
  useEffect(() => { const h = e => { if (ref.current && !ref.current.contains(e.target)) setOpen(false); }; document.addEventListener("mousedown", h); return () => document.removeEventListener("mousedown", h); }, []);
  const active = boards.find(b => b.id === activeId);
  return (
    <div ref={ref} style={{ position: "relative" }}>
      <button onClick={() => setOpen(!open)} style={{
        fontFamily: "inherit", fontSize: 13, fontWeight: 600, cursor: "pointer",
        background: "rgba(255,255,255,0.04)", color: "#C0B8B0", border: "1px solid rgba(255,255,255,0.08)",
        borderRadius: 10, padding: "8px 14px", display: "flex", alignItems: "center", gap: 8, transition: "all 0.15s", maxWidth: 220,
      }} onMouseEnter={e => { e.currentTarget.style.background = "rgba(255,255,255,0.08)"; }} onMouseLeave={e => { e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}>
        <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{active?.name || "Untitled board"}</span>
        <span style={{ fontSize: 10, color: "#5A544E", flexShrink: 0 }}>▼</span>
      </button>
      {open && (
        <div style={{
          position: "absolute", top: "calc(100% + 6px)", left: 0, minWidth: 260,
          background: "#1E1C1A", border: "1px solid rgba(255,255,255,0.10)", borderRadius: 14,
          boxShadow: "0 12px 48px rgba(0,0,0,0.5)", padding: 6, zIndex: 100, animation: "popIn 0.15s ease both",
        }}>
          {boards.map(b => (
            <div key={b.id} style={{ display: "flex", alignItems: "center", gap: 8 }}>
              <button onClick={() => { onSwitch(b.id); setOpen(false); }}
                style={{
                  flex: 1, display: "flex", flexDirection: "column", gap: 2, padding: "10px 14px",
                  background: b.id === activeId ? "rgba(239,139,110,0.1)" : "transparent",
                  border: "none", borderRadius: 10, cursor: "pointer", fontFamily: "inherit", textAlign: "left", transition: "background 0.12s",
                }}
                onMouseEnter={e => { if (b.id !== activeId) e.currentTarget.style.background = "rgba(255,255,255,0.04)"; }}
                onMouseLeave={e => { if (b.id !== activeId) e.currentTarget.style.background = "transparent"; }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: b.id === activeId ? "#EF8B6E" : "#C0B8B0", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{b.name || "Untitled"}</span>
                <span style={{ fontSize: 11, color: "#4A4440" }}>{b.updated ? new Date(b.updated).toLocaleDateString() : ""}</span>
              </button>
              {boards.length > 1 && (
                <button onClick={(e) => { e.stopPropagation(); onDelete(b.id); }}
                  style={{ background: "none", border: "none", color: "#3A3530", cursor: "pointer", fontSize: 12, padding: "4px 6px", borderRadius: 6, transition: "color 0.15s" }}
                  onMouseEnter={e => e.target.style.color = "#D4746A"} onMouseLeave={e => e.target.style.color = "#3A3530"}>✕</button>
              )}
            </div>
          ))}
          <div style={{ height: 1, background: "rgba(255,255,255,0.06)", margin: "4px 6px" }} />
          <button onClick={() => { onNew(); setOpen(false); }}
            style={{ display: "flex", alignItems: "center", gap: 8, padding: "10px 14px", width: "100%", background: "transparent", border: "none", borderRadius: 10, cursor: "pointer", fontFamily: "inherit", transition: "background 0.12s" }}
            onMouseEnter={e => e.currentTarget.style.background = "rgba(255,255,255,0.04)"}
            onMouseLeave={e => e.currentTarget.style.background = "transparent"}>
            <span style={{ color: "#EF8B6E", fontWeight: 700, fontSize: 15 }}>+</span>
            <span style={{ color: "#9A928A", fontWeight: 600, fontSize: 13 }}>New board</span>
          </button>
        </div>
      )}
    </div>
  );
}

/* ═══ EXPORT ═══ */
function exportMd(b, scores) {
  let md = `# Weigh It\n\n`; if (b.q) md += `**Question:** ${b.q}\n\n`;
  md += `## Explanations\n`; b.hyps.forEach((h,i) => { const s = scores[h.id]; md += `${i+1}. ${h.out?"~~":""}${h.name||"Unnamed"}${h.out?"~~ (ruled out)":""} → score: ${s!=null?(s>0?"+":"")+s:"n/a"}\n`; });
  md += `\n## Evidence\n\n`; b.evs.forEach(e => { md += `**${e.text||"Unnamed"}** (trust: ${WL[e.cred]}, relevance: ${WL[e.rel]})\n`; b.hyps.forEach(h => { const r=b.mx[`${e.id}-${h.id}`]; const n=b.notes[`${e.id}-${h.id}`]; if(r) md+=`  - vs. ${h.name||"?"}: ${RM[r]?.word}${n?` — "${n}"`:""}\n`; }); md+="\n"; });
  if (b.conclusion) md += `## Conclusion\n\n${b.conclusion}\n\n`;
  md += `---\n_Weigh It — based on Analysis of Competing Hypotheses_\n`; return md;
}

/* ═══ MAIN ═══ */
export default function App() {
  const [loaded, setLoaded] = useState(false);
  const [boards, setBoards] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [b, setB] = useState(null); // active board
  const [pop, setPop] = useState(null);
  const [selCell, setSelCell] = useState(null);
  const [showRes, setShowRes] = useState(false);
  const [saveStatus, setSaveStatus] = useState("");
  const [exported, setExported] = useState(false);
  const [justChanged, setJustChanged] = useState(null); // cellKey
  const [showConfetti, setShowConfetti] = useState(false);
  const [undoStack, setUndoStack] = useState([]);
  const timer = useRef(null);
  const prevFilled = useRef(0);

  /* load */
  useEffect(() => {
    (async () => {
      let list = await sGet(LS);
      let aId = await sGet(AB);
      if (!list || list.length === 0) {
        const ex = freshBoard(true);
        list = [{ id: ex.id, name: ex.q, updated: Date.now() }];
        await sSet(LS, list); await sSet(bKey(ex.id), ex); aId = ex.id; await sSet(AB, aId);
      }
      setBoards(list);
      const id = aId && list.find(l => l.id === aId) ? aId : list[0].id;
      const data = await sGet(bKey(id)) || freshBoard(true);
      setActiveId(id); setB(data); setLoaded(true);
    })();
  }, []);

  /* autosave */
  useEffect(() => {
    if (!loaded || !b) return;
    if (timer.current) clearTimeout(timer.current);
    setSaveStatus("saving");
    timer.current = setTimeout(async () => {
      await sSet(bKey(b.id), b);
      const name = b.q || "Untitled board";
      setBoards(prev => { const next = prev.map(x => x.id === b.id ? { ...x, name, updated: Date.now() } : x); sSet(LS, next); return next; });
      setSaveStatus("saved"); setTimeout(() => setSaveStatus(""), 2000);
    }, 600);
    return () => { if (timer.current) clearTimeout(timer.current); };
  }, [b, loaded]);

  /* Ctrl+Z */
  useEffect(() => {
    const h = e => { if ((e.metaKey || e.ctrlKey) && e.key === "z" && undoStack.length > 0) { e.preventDefault(); doUndo(); } };
    document.addEventListener("keydown", h); return () => document.removeEventListener("keydown", h);
  }, [undoStack]);

  const pushUndo = useCallback(() => {
    if (!b) return;
    setUndoStack(prev => [...prev.slice(-19), JSON.parse(JSON.stringify(b))]);
  }, [b]);

  function doUndo() {
    if (undoStack.length === 0) return;
    const prev = undoStack[undoStack.length - 1];
    setUndoStack(s => s.slice(0, -1));
    setB(prev);
  }

  async function switchBoard(id) {
    const data = await sGet(bKey(id)) || freshBoard(false);
    setActiveId(id); setB(data); setUndoStack([]); setSelCell(null); setShowRes(false); setPop(null);
    await sSet(AB, id);
  }

  async function newBoard() {
    const nb = freshBoard(false);
    const entry = { id: nb.id, name: "Untitled", updated: Date.now() };
    const next = [...boards, entry];
    setBoards(next); await sSet(LS, next); await sSet(bKey(nb.id), nb);
    switchBoard(nb.id);
  }

  async function deleteBoard(id) {
    if (boards.length <= 1) return;
    const next = boards.filter(x => x.id !== id);
    setBoards(next); await sSet(LS, next); await sDel(bKey(id));
    if (id === activeId) switchBoard(next[0].id);
  }

  /* helpers to update board */
  const up = useCallback((fn) => setB(prev => fn(prev ? { ...prev } : prev)), []);
  const setMx = useCallback((key, val) => {
    setJustChanged(key); setTimeout(() => setJustChanged(null), 400);
    up(b => { b.mx = val ? { ...b.mx, [key]: val } : (() => { const n = { ...b.mx }; delete n[key]; return n; })(); return b; });
  }, [up]);

  /* scoring (safe for null b) */
  const scores = {}; let maxAbs = 0;
  if (b) {
    b.hyps.forEach(h => { if (h.out) { scores[h.id]=null; return; } let s=0; b.evs.forEach(e => { const r=b.mx[`${e.id}-${h.id}`]; if(r&&RM[r]) s+=RM[r].val*(WV[e.cred]||2)*(WV[e.rel]||2); }); scores[h.id]=s; if(Math.abs(s)>maxAbs) maxAbs=Math.abs(s); });
  }
  const active = b ? b.hyps.filter(h => !h.out) : [];
  const ranked = [...active].sort((a,bb) => (scores[bb.id]||0)-(scores[a.id]||0));
  const ruled = b ? b.hyps.filter(h => h.out) : [];
  const totalC = b ? active.length * b.evs.length : 0;
  const filled = b ? Object.entries(b.mx).filter(([k,v]) => { if(!v) return false; const hId=k.split("-")[1]; return !b.hyps.find(h=>h.id===hId)?.out; }).length : 0;
  const pct = totalC > 0 ? Math.round((filled/totalC)*100) : 0;

  // confetti on 100%
  useEffect(() => {
    if (pct === 100 && prevFilled.current < totalC && totalC > 0) { setShowConfetti(true); setTimeout(() => setShowConfetti(false), 2500); }
    prevFilled.current = filled;
  }, [pct, filled, totalC]);

  const diag = b ? b.evs.map(e => { const vs=active.map(h=>RM[b.mx[`${e.id}-${h.id}`]]?.val??0); return{ev:e,spread:vs.length?Math.max(...vs)-Math.min(...vs):0}; }).sort((a,bb)=>bb.spread-a.spread) : [];
  const sp=selCell?.split("-"); const selEv=sp?.[0]&&b?b.evs.find(e=>e.id===sp[0]):null; const selHyp=sp?.[1]&&b?b.hyps.find(h=>h.id===sp[1]):null;

  if (!loaded || !b) return <div style={{ minHeight: "100vh", background: "#111014", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "'Figtree',sans-serif" }}><span style={{ color: "#4A4440" }}>Loading…</span></div>;

  return (
    <div style={{ minHeight: "100vh", fontFamily: "'Figtree',sans-serif", color: "#F0EBE6", background: "#111014", backgroundImage: "radial-gradient(ellipse 80% 50% at 50% 0%, rgba(239,139,110,0.05) 0%, transparent 60%), radial-gradient(ellipse 60% 50% at 85% 100%, rgba(126,196,155,0.03) 0%, transparent 50%)" }}>
      <link href={FONT} rel="stylesheet" />
      <style>{`
        *{box-sizing:border-box}
        ::selection{background:rgba(239,139,110,0.3)}
        input::placeholder,textarea::placeholder{color:#4A4440}
        @keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
        @keyframes popIn{from{opacity:0;transform:scale(0.92) translateY(-4px)}to{opacity:1;transform:scale(1) translateY(0)}}
        @keyframes sheetUp{from{opacity:0;transform:translateY(40px)}to{opacity:1;transform:translateY(0)}}
        @keyframes cellPop{0%{transform:scale(1)}40%{transform:scale(1.08)}100%{transform:scale(1)}}
        @keyframes softPulse{0%,100%{opacity:1}50%{opacity:.5}}
        @keyframes confettiFall{0%{opacity:1;transform:translateY(0) translateX(0) rotate(0deg)}100%{opacity:0;transform:translateY(100vh) translateX(var(--drift)) rotate(720deg)}}
        @keyframes gentlePulse{0%,100%{box-shadow:0 6px 30px rgba(239,139,110,0.25)}50%{box-shadow:0 6px 30px rgba(239,139,110,0.40)}}
        .crd{animation:fadeUp .5s ease both}
        .hov-row:hover{background:rgba(255,255,255,0.015)!important}
        .sticky-head th{position:sticky;top:0;z-index:2}
        @media(max-width:640px){.hdr-wrap{flex-direction:column!important;gap:12px!important} .hdr-right{width:100%!important;justify-content:space-between!important}}
      `}</style>

      <Confetti active={showConfetti} />
      {pop && <Popover cellKey={pop.key} cur={b.mx[pop.key]||""} pos={pop} onPick={v=>setMx(pop.key,v)} onClose={()=>setPop(null)} onNote={()=>setSelCell(pop.key)} />}

      <div style={{ maxWidth: 960, margin: "0 auto", padding: "32px 24px 80px" }}>

        {/* ── HEADER ── */}
        <div className="crd hdr-wrap" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 28, gap: 16, flexWrap: "wrap" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 48, height: 48, borderRadius: 16, background: "linear-gradient(135deg, #EF8B6E, #E8C47A)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 24, boxShadow: "0 4px 24px rgba(239,139,110,0.25)" }}>🧠</div>
            <div>
              <h1 style={{ margin: 0, fontSize: 26, fontWeight: 900, letterSpacing: -0.5, background: "linear-gradient(135deg, #F0EBE6, #B0A8A0)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>Weigh It</h1>
              <p style={{ margin: 0, fontSize: 13, color: "#5A544E" }}>Think it through before you jump.</p>
            </div>
          </div>
          <div className="hdr-right" style={{ display: "flex", alignItems: "center", gap: 8, flexShrink: 0 }}>
            <ProgressRing pct={pct} />
            <BoardSwitcher boards={boards} activeId={activeId} onSwitch={switchBoard} onNew={newBoard} onDelete={deleteBoard} />
            {undoStack.length > 0 && (
              <button onClick={doUndo} title="Undo (⌘Z)" style={{ fontFamily: "inherit", fontSize: 13, fontWeight: 600, cursor: "pointer", background: "rgba(255,255,255,0.04)", color: "#8A8278", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, padding: "8px 12px", transition: "all 0.15s" }}
                onMouseEnter={e=>{e.target.style.background="rgba(255,255,255,0.08)";}} onMouseLeave={e=>{e.target.style.background="rgba(255,255,255,0.04)";}}>↩ Undo</button>
            )}
            <span style={{ fontSize: 11, color: saveStatus==="saved"?"#7EC49B":"#3A3530", transition: "color .3s", fontWeight: 500, animation: saveStatus==="saving"?"softPulse 1s infinite":"none", minWidth: 50 }}>
              {saveStatus==="saving"?"saving…":saveStatus==="saved"?"✓ saved":""}
            </span>
            <button onClick={() => { navigator.clipboard.writeText(exportMd(b,scores)).then(()=>{setExported(true);setTimeout(()=>setExported(false),2500);}).catch(()=>{}); }}
              style={{ fontFamily: "inherit", fontSize: 13, fontWeight: 600, cursor: "pointer", background: "rgba(255,255,255,0.04)", color: "#8A8278", border: "1px solid rgba(255,255,255,0.08)", borderRadius: 10, padding: "8px 14px", transition: "all 0.15s" }}
              onMouseEnter={e=>{e.target.style.background="rgba(255,255,255,0.08)";}} onMouseLeave={e=>{e.target.style.background="rgba(255,255,255,0.04)";}}>{exported?"✓ Copied":"📋 Export"}</button>
          </div>
        </div>

        {/* ── QUESTION ── */}
        <div className="crd" style={{ ...card, animationDelay: ".04s" }}>
          <label style={{ fontSize: 13, fontWeight: 600, color: "#7A7470", display: "block", marginBottom: 8 }}>What are you trying to figure out?</label>
          <input value={b.q} onChange={e => up(b=>{b.q=e.target.value;return b;})} placeholder="e.g. Why are signups dropping?" style={{ width: "100%", background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.07)", borderRadius: 12, padding: "13px 18px", fontSize: 17, fontFamily: "inherit", fontWeight: 500, color: "#F0EBE6", outline: "none", transition: "border .2s, box-shadow .2s" }}
            onFocus={e=>{e.target.style.borderColor="rgba(239,139,110,0.4)";e.target.style.boxShadow="0 0 0 3px rgba(239,139,110,0.07)";}} onBlur={e=>{e.target.style.borderColor="rgba(255,255,255,0.07)";e.target.style.boxShadow="none";}} />
        </div>

        {/* ── EXPLANATIONS ── */}
        <div className="crd" style={{ ...card, animationDelay: ".08s" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <label style={{ fontSize: 13, fontWeight: 600, color: "#7A7470" }}>Possible explanations</label>
            <button onClick={() => { if(b.hyps.length>=7) return; pushUndo(); up(b=>{b.hyps=[...b.hyps,{id:uid(),name:"",color:HC[b.hyps.length%HC.length],out:false}];return b;}); }}
              disabled={b.hyps.length>=7} style={{ fontFamily:"inherit",fontSize:13,fontWeight:700,cursor:b.hyps.length>=7?"not-allowed":"pointer",background:"none",color:"#EF8B6E",border:"none",padding:"4px 8px",opacity:b.hyps.length>=7?0.3:1 }}>+ add</button>
          </div>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {b.hyps.map((h,i) => (
              <div key={h.id} style={{ display: "flex", alignItems: "center", gap: 10, background: "rgba(255,255,255,0.02)", borderRadius: 12, padding: "10px 14px", border: "1px solid rgba(255,255,255,0.05)", opacity: h.out?0.4:1, transition: "all .25s" }}>
                <div style={{ width: 12, height: 12, borderRadius: "50%", background: h.color, boxShadow: h.out?"none":`0 0 10px ${h.color}33`, flexShrink: 0 }} />
                <span style={{ flex: 1, textDecoration: h.out?"line-through":"none", fontSize: 14, fontWeight: 500, color: "#F0EBE6" }}>
                  {h.out ? (h.name||`Explanation ${i+1}`) : <Ed value={h.name} ph={`Explanation ${i+1}…`} onChange={v=>up(b=>{b.hyps=b.hyps.map(x=>x.id===h.id?{...x,name:v}:x);return b;})} style={{ fontSize: 14, fontWeight: 500, color: "#F0EBE6" }} />}
                </span>
                <button onClick={() => { pushUndo(); up(b=>{b.hyps=b.hyps.map(x=>x.id===h.id?{...x,out:!x.out}:x);return b;}); }}
                  style={{ fontFamily:"inherit",fontSize:11,fontWeight:700,cursor:"pointer",flexShrink:0,background:h.out?"rgba(126,196,155,0.1)":"rgba(212,116,106,0.08)",border:`1px solid ${h.out?"rgba(126,196,155,0.2)":"rgba(212,116,106,0.2)"}`,color:h.out?"#7EC49B":"#D4746A",borderRadius:8,padding:"4px 11px",transition:"all .15s" }}>{h.out?"↩ undo":"✕ rule out"}</button>
                {b.hyps.length>2&&<button onClick={()=>{pushUndo();up(b=>{b.hyps=b.hyps.filter(x=>x.id!==h.id);const nm={...b.mx},nn={...b.notes};Object.keys(nm).forEach(k=>{if(k.includes(h.id))delete nm[k]});Object.keys(nn).forEach(k=>{if(k.includes(h.id))delete nn[k]});b.mx=nm;b.notes=nn;return b;});}} style={{background:"none",border:"none",color:"#2A2520",fontSize:12,cursor:"pointer",padding:"2px 4px"}} onMouseEnter={e=>e.target.style.color="#D4746A"} onMouseLeave={e=>e.target.style.color="#2A2520"}>✕</button>}
              </div>
            ))}
          </div>
        </div>

        {/* ── EVIDENCE ── */}
        <div className="crd" style={{ ...card, animationDelay: ".12s" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <label style={{ fontSize: 13, fontWeight: 600, color: "#7A7470" }}>What do you know so far?</label>
            <button onClick={()=>up(b=>{b.evs=[...b.evs,{id:uid(),text:"",cred:"M",rel:"M"}];return b;})} style={{fontFamily:"inherit",fontSize:13,fontWeight:700,cursor:"pointer",background:"none",color:"#EF8B6E",border:"none",padding:"4px 8px"}}>+ add</button>
          </div>
          <p style={{ fontSize: 12, color: "#4A4440", margin: "0 0 10px" }}>Data, observations, gut feelings. ▲▼ to reorder.</p>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {b.evs.map((e,i) => (
              <div key={e.id} style={{ display: "flex", alignItems: "center", gap: 8, background: "rgba(255,255,255,0.02)", borderRadius: 12, padding: "10px 14px", border: "1px solid rgba(255,255,255,0.05)", flexWrap: "wrap" }}>
                <div style={{ display: "flex", flexDirection: "column", gap: 0, flexShrink: 0 }}>
                  <button onClick={()=>{if(i===0)return;up(b=>{const a=[...b.evs];[a[i],a[i-1]]=[a[i-1],a[i]];b.evs=a;return b;});}} disabled={i===0} style={{background:"none",border:"none",color:i===0?"#1A1816":"#5A544E",fontSize:9,cursor:i===0?"default":"pointer",padding:0,lineHeight:1}}>▲</button>
                  <button onClick={()=>{if(i===b.evs.length-1)return;up(b=>{const a=[...b.evs];[a[i],a[i+1]]=[a[i+1],a[i]];b.evs=a;return b;});}} disabled={i===b.evs.length-1} style={{background:"none",border:"none",color:i===b.evs.length-1?"#1A1816":"#5A544E",fontSize:9,cursor:i===b.evs.length-1?"default":"pointer",padding:0,lineHeight:1}}>▼</button>
                </div>
                <span style={{fontSize:12,fontWeight:800,color:"#2A2520",width:18,textAlign:"center",flexShrink:0}}>{i+1}</span>
                <Ed value={e.text} ph="Something you've observed…" onChange={v=>up(b=>{b.evs=b.evs.map(x=>x.id===e.id?{...x,text:v}:x);return b;})} style={{fontSize:14,color:"#F0EBE6",flex:1,minWidth:120}} />
                <div style={{ display: "flex", gap: 6, flexShrink: 0 }}>
                  {[["trust","cred"],["rel","rel"]].map(([label,field])=>(
                    <div key={field} style={{display:"flex",alignItems:"center",gap:2}}>
                      <span style={{fontSize:10,color:"#4A4440",fontWeight:600}}>{label}</span>
                      {["H","M","L"].map(v=>(
                        <button key={v} onClick={()=>up(b=>{b.evs=b.evs.map(x=>x.id===e.id?{...x,[field]:v}:x);return b;})} title={WL[v]}
                          style={{width:28,height:22,borderRadius:6,fontSize:10,fontWeight:700,cursor:"pointer",fontFamily:"inherit",border:"none",transition:"all .15s",background:e[field]===v?"rgba(239,139,110,0.15)":"transparent",color:e[field]===v?"#EF8B6E":"#3A3530"}}>{WL[v]}</button>
                      ))}
                    </div>
                  ))}
                </div>
                {b.evs.length>1&&<button onClick={()=>{pushUndo();up(b=>{b.evs=b.evs.filter(x=>x.id!==e.id);const nm={...b.mx},nn={...b.notes};Object.keys(nm).forEach(k=>{if(k.startsWith(e.id))delete nm[k]});Object.keys(nn).forEach(k=>{if(k.startsWith(e.id))delete nn[k]});b.mx=nm;b.notes=nn;return b;});}} style={{background:"none",border:"none",color:"#2A2520",fontSize:12,cursor:"pointer",padding:"2px 4px"}} onMouseEnter={e=>e.target.style.color="#D4746A"} onMouseLeave={e=>e.target.style.color="#2A2520"}>✕</button>}
              </div>
            ))}
          </div>
        </div>

        {/* ── MATRIX ── */}
        <div className="crd" style={{ ...card, animationDelay: ".16s" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <label style={{ fontSize: 13, fontWeight: 600, color: "#7A7470" }}>Weigh each piece against each explanation</label>
            {filled>0&&<span style={{fontSize:12,color:"#4A4440",fontWeight:600}}>{filled}/{totalC}</span>}
          </div>
          <p style={{fontSize:12,color:"#4A4440",margin:"0 0 12px"}}>Click any cell to rate it.</p>
          <div style={{display:"flex",gap:5,marginBottom:12,flexWrap:"wrap"}}>
            {RATINGS.map(r=><span key={r.key} style={{display:"inline-flex",alignItems:"center",gap:4,background:r.bg,borderRadius:7,padding:"3px 9px",border:`1px solid ${r.border}`,fontSize:10,color:r.text,fontWeight:600}}>{r.emoji} {r.word}</span>)}
          </div>
          <div style={{overflowX:"auto",borderRadius:14,border:"1px solid rgba(255,255,255,0.06)",background:"rgba(0,0,0,0.18)",maxHeight:460}}>
            <table style={{width:"100%",borderCollapse:"collapse"}}>
              <thead className="sticky-head"><tr>
                <th style={{textAlign:"left",padding:"13px 16px",fontSize:11,fontWeight:600,letterSpacing:.5,color:"#5A544E",background:"#161416",borderRight:"1px solid rgba(255,255,255,0.04)",borderBottom:"1px solid rgba(255,255,255,0.08)",minWidth:180,fontFamily:"inherit",position:"sticky",left:0,zIndex:3}}>EVIDENCE</th>
                {b.hyps.map(h=>(
                  <th key={h.id} style={{padding:"13px 8px",textAlign:"center",background:"#161416",borderRight:"1px solid rgba(255,255,255,0.04)",borderBottom:"1px solid rgba(255,255,255,0.08)",minWidth:100,fontFamily:"inherit",opacity:h.out?.3:1}}>
                    <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:4}}>
                      <div style={{width:10,height:10,borderRadius:"50%",background:h.color,boxShadow:`0 0 8px ${h.color}44`}} />
                      <span style={{fontSize:11,fontWeight:600,color:"#B0A8A0",lineHeight:1.2,textDecoration:h.out?"line-through":"none",maxWidth:90,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{h.name||`Expl.${b.hyps.indexOf(h)+1}`}</span>
                      {h.out&&<span style={{fontSize:8,color:"#D4746A",fontWeight:700,letterSpacing:.5}}>RULED OUT</span>}
                    </div>
                  </th>
                ))}
              </tr></thead>
              <tbody>{b.evs.map((e,i)=>(
                <tr key={e.id} className="hov-row">
                  <td style={{padding:"11px 16px",borderRight:"1px solid rgba(255,255,255,0.04)",borderBottom:"1px solid rgba(255,255,255,0.04)",fontSize:13,color:"#B0A8A0",verticalAlign:"middle",background:"#131114",position:"sticky",left:0,zIndex:1}}>
                    {e.text||<span style={{color:"#2A2520",fontStyle:"italic"}}>Evidence {i+1}</span>}
                  </td>
                  {b.hyps.map(h=>{const k=`${e.id}-${h.id}`;return <Cell key={h.id} rk={b.mx[k]||""} dimmed={h.out} hasNote={!!b.notes[k]} justChanged={justChanged===k} onOpen={ev=>setPop({key:k,top:ev.currentTarget.getBoundingClientRect().bottom+4,left:ev.currentTarget.getBoundingClientRect().left})}/>;
                  })}
                </tr>
              ))}</tbody>
            </table>
          </div>

          {selCell&&selEv&&selHyp&&(
            <div style={{marginTop:14,background:"rgba(239,139,110,0.05)",borderRadius:14,padding:"14px 20px",border:"1px solid rgba(239,139,110,0.12)",animation:"fadeUp .2s ease both",boxShadow:"0 4px 20px rgba(0,0,0,0.15)"}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:10}}>
                <span style={{fontSize:12,color:"#7A7470"}}>📝 <strong style={{color:"#C0B8B0"}}>{selEv.text||"Evidence"}</strong> → <strong style={{color:selHyp.color}}>{selHyp.name||"Explanation"}</strong></span>
                <button onClick={()=>setSelCell(null)} style={{background:"none",border:"none",color:"#4A4440",cursor:"pointer",fontSize:13,fontFamily:"inherit"}}>✕</button>
              </div>
              <textarea value={b.notes[selCell]||""} onChange={e=>up(b=>{b.notes={...b.notes,[selCell]:e.target.value};return b;})} placeholder="Why did you rate it this way?" rows={2}
                style={{width:"100%",background:"rgba(255,255,255,0.04)",border:"1px solid rgba(255,255,255,0.07)",borderRadius:10,padding:"11px 14px",fontSize:14,fontFamily:"inherit",color:"#F0EBE6",outline:"none",resize:"vertical",lineHeight:1.6}}
                onFocus={e=>{e.target.style.borderColor="rgba(239,139,110,0.3)";}} onBlur={e=>{e.target.style.borderColor="rgba(255,255,255,0.07)";}} />
            </div>
          )}
        </div>

        {/* ── RESULTS ── */}
        {filled>0&&(
          <div style={{textAlign:"center",margin:"18px 0 14px"}}>
            <button onClick={()=>setShowRes(!showRes)} style={{
              fontFamily:"inherit",fontSize:16,fontWeight:700,cursor:"pointer",
              background:showRes?"rgba(255,255,255,0.04)":"linear-gradient(135deg,#EF8B6E,#E8C47A)",
              color:showRes?"#5A544E":"#111014",border:showRes?"1px solid rgba(255,255,255,0.08)":"none",
              borderRadius:14,padding:"15px 36px",transition:"all .25s",
              boxShadow:showRes?"none":"0 6px 30px rgba(239,139,110,0.25)",
              animation:!showRes&&pct===100?"gentlePulse 2s ease infinite":"none",
            }}>{showRes?"Hide results":"See what the evidence says ↓"}</button>
          </div>
        )}

        {showRes&&filled>0&&(
          <div style={{display:"flex",flexDirection:"column",gap:16}}>
            <div className="crd" style={card}>
              <label style={{fontSize:13,fontWeight:600,color:"#7A7470",display:"block",marginBottom:14}}>Which explanation holds up best?</label>
              {ranked.map((h,i)=>{const s=scores[h.id]||0;const p=maxAbs>0?Math.abs(s)/maxAbs*100:0;return(
                <div key={h.id} style={{display:"flex",alignItems:"center",gap:14,padding:"13px 0",borderBottom:i<ranked.length-1?"1px solid rgba(255,255,255,0.04)":"none",animation:`fadeUp .4s ease ${i*0.08}s both`}}>
                  <span style={{fontSize:24,fontWeight:900,width:32,textAlign:"right",color:i===0?"#EF8B6E":"#2A2520"}}>{i+1}</span>
                  <div style={{width:12,height:12,borderRadius:"50%",background:h.color,boxShadow:`0 0 10px ${h.color}33`,flexShrink:0}} />
                  <div style={{flex:1}}>
                    <div style={{fontSize:14,fontWeight:600,color:"#F0EBE6",marginBottom:5}}>{h.name||`Explanation ${b.hyps.indexOf(h)+1}`}</div>
                    <div style={{height:5,background:"rgba(255,255,255,0.04)",borderRadius:3,overflow:"hidden"}}>
                      <div style={{height:"100%",borderRadius:3,transition:"width .7s cubic-bezier(.4,0,.2,1)",width:`${Math.max(p,3)}%`,background:s>=0?`linear-gradient(90deg,${h.color}55,${h.color})`:`linear-gradient(90deg,#D4746A55,#D4746A)`}} />
                    </div>
                  </div>
                  <AnimNum value={s} color={s>0?"#7EC49B":s<0?"#D4746A":"#4A4440"} />
                </div>
              );})}
              {ruled.length>0&&<div style={{marginTop:12,paddingTop:12,borderTop:"1px solid rgba(255,255,255,0.04)"}}><span style={{fontSize:12,fontWeight:700,color:"#D4746A"}}>Ruled out: </span>{ruled.map((h,i)=><span key={h.id} style={{fontSize:12,color:"#D4746A",textDecoration:"line-through"}}>{h.name||"?"}{i<ruled.length-1?", ":""}</span>)}</div>}
              <div style={{marginTop:14,padding:"12px 16px",borderRadius:12,background:"rgba(239,139,110,0.05)",borderLeft:"3px solid #EF8B6E",fontSize:13,color:"#7A7470",lineHeight:1.6}}>💡 The best explanation isn't the one with the most support — it's the one with the fewest contradictions.</div>
            </div>

            {(diag.some(d=>d.spread>=2)||diag.some(d=>d.spread===0))&&(
              <div className="crd" style={card}>
                <label style={{fontSize:13,fontWeight:600,color:"#7A7470",display:"block",marginBottom:12}}>Which evidence actually matters?</label>
                {diag.filter(d=>d.spread>=2).length>0&&<div style={{marginBottom:12}}><div style={{fontSize:12,fontWeight:700,color:"#7EC49B",marginBottom:6}}>🎯 Helps you decide:</div>{diag.filter(d=>d.spread>=2).map(d=><div key={d.ev.id} style={{padding:"9px 14px",background:"rgba(126,196,155,0.07)",borderRadius:10,border:"1px solid rgba(126,196,155,0.18)",fontSize:13,color:"#A0CFA0",marginBottom:5}}>{d.ev.text||"Unnamed"}</div>)}</div>}
                {diag.filter(d=>d.spread===0).length>0&&<div><div style={{fontSize:12,fontWeight:700,color:"#E8C47A",marginBottom:6}}>😐 Doesn't differentiate:</div>{diag.filter(d=>d.spread===0).map(d=><div key={d.ev.id} style={{padding:"9px 14px",background:"rgba(232,196,122,0.05)",borderRadius:10,border:"1px solid rgba(232,196,122,0.12)",fontSize:13,color:"#C0A870",marginBottom:5}}>{d.ev.text||"Unnamed"}</div>)}</div>}
              </div>
            )}

            {(()=>{const w=[];active.forEach(h=>{const hrs=b.evs.map(e=>b.mx[`${e.id}-${h.id}`]).filter(Boolean);if(hrs.length>2&&hrs.every(r=>r==="CC"||r==="C"))w.push(`Everything supports "${h.name||"one explanation"}" — are you seeing what you want to see?`);});if(b.evs.length<3)w.push("Only a few data points. Could you be missing something?");if(!w.length)return null;return(
              <div className="crd" style={{...card,background:"rgba(232,196,122,0.04)",border:"1px solid rgba(232,196,122,0.10)"}}>
                <label style={{fontSize:13,fontWeight:700,color:"#E8C47A",display:"block",marginBottom:8}}>🪞 Honest check</label>
                {w.map((m,i)=><p key={i} style={{fontSize:13,color:"#A09070",margin:"0 0 4px",lineHeight:1.5}}>{m}</p>)}
              </div>);
            })()}

            <div className="crd" style={{...card,background:"rgba(239,139,110,0.03)",border:"1px solid rgba(239,139,110,0.10)"}}>
              <label style={{fontSize:15,fontWeight:700,color:"#EF8B6E",display:"block",marginBottom:4}}>So, what do you think?</label>
              <p style={{fontSize:12,color:"#5A544E",margin:"0 0 10px"}}>Write your conclusion. What did you decide? What's unresolved? Included in exports.</p>
              <textarea value={b.conclusion} onChange={e=>up(b=>{b.conclusion=e.target.value;return b;})} placeholder="Based on the evidence, I believe…" rows={4}
                style={{width:"100%",background:"rgba(255,255,255,0.04)",border:"1px solid rgba(255,255,255,0.07)",borderRadius:12,padding:"13px 18px",fontSize:15,fontFamily:"inherit",color:"#F0EBE6",outline:"none",resize:"vertical",lineHeight:1.7}}
                onFocus={e=>{e.target.style.borderColor="rgba(239,139,110,0.35)";e.target.style.boxShadow="0 0 0 3px rgba(239,139,110,0.06)";}} onBlur={e=>{e.target.style.borderColor="rgba(255,255,255,0.07)";e.target.style.boxShadow="none";}} />
            </div>
          </div>
        )}

        <div style={{textAlign:"center",marginTop:36,padding:"14px 0",borderTop:"1px solid rgba(255,255,255,0.03)"}}>
          <p style={{fontSize:11,color:"#2A2520",margin:0}}>Based on Analysis of Competing Hypotheses — a thinking technique from intelligence analysis. Made friendly.</p>
        </div>
      </div>
    </div>
  );
}
