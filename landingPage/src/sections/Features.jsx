import React from 'react'
import {
  Route, Wallet, BarChart3, Car, UserCheck, ShieldCheck,
  BellRing, ArrowRight, Check,
} from 'lucide-react'

/* ── Visuals (flat, hairline, no gradients) ──────── */
function FareVisual() {
  return (
    <div className="card rounded-2xl p-6 shadow-soft">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-ink-soft mb-4">New booking</p>
      <div className="space-y-3">
        <div className="flex items-center justify-between border border-sand-border rounded-xl px-4 py-3">
          <span className="text-sm text-ink-soft">Route</span>
          <span className="text-sm font-medium text-ink">Mumbai → Pune</span>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div className="border border-sand-border rounded-xl px-4 py-3">
            <p className="text-[11px] text-ink-soft">Distance</p>
            <p className="text-sm font-medium text-ink font-mono">148 km</p>
          </div>
          <div className="border border-sand-border rounded-xl px-4 py-3">
            <p className="text-[11px] text-ink-soft">Rate</p>
            <p className="text-sm font-medium text-ink font-mono">₹60 / km</p>
          </div>
        </div>
        <div className="flex items-center justify-between bg-ink rounded-xl px-4 py-3.5">
          <span className="text-sm text-sand/70">Trip total</span>
          <span className="font-display text-xl font-semibold text-sand">₹8,880</span>
        </div>
      </div>
    </div>
  )
}

function PaymentsVisual() {
  const rows = [
    { n: 'Rajesh Sharma', s: 'Paid', a: '₹0', bg: '#ecf4de', fg: '#4d7c0f' },
    { n: 'Mehta Tours', s: 'Partial', a: '₹3,200', bg: '#f7edd6', fg: '#c2860b' },
    { n: 'A. Khan', s: 'Pending', a: '₹6,500', bg: '#f7e3e0', fg: '#b91c1c' },
  ]
  return (
    <div className="card rounded-2xl p-6 shadow-soft">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-ink-soft mb-4">Customer balances</p>
      <div className="space-y-2.5">
        {rows.map((r, i) => (
          <div key={i} className="flex items-center justify-between border border-sand-border rounded-xl px-4 py-3">
            <span className="text-sm text-ink">{r.n}</span>
            <div className="flex items-center gap-2.5">
              <span className="text-sm font-medium text-ink font-mono">{r.a}</span>
              <span className="text-[10px] px-2 py-0.5 rounded-full font-semibold" style={{ background: r.bg, color: r.fg }}>{r.s}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

function ReportsVisual() {
  return (
    <div className="card rounded-2xl p-6 shadow-soft">
      <div className="flex items-center justify-between mb-5">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-ink-soft">Revenue · this week</p>
        <span className="font-display text-lg font-semibold text-ink">₹84,500</span>
      </div>
      <div className="flex items-end gap-2 h-28 mb-5">
        {[44, 62, 38, 80, 56, 70, 100].map((h, i) => (
          <div key={i} className="flex-1 rounded-t-md" style={{ height: `${h}%`, background: i === 6 ? '#b5651d' : '#f6eee6', border: '1px solid #ece4d9' }} />
        ))}
      </div>
      <div className="flex gap-2">
        <span className="chip">Export PDF</span>
        <span className="chip">Export Excel</span>
      </div>
    </div>
  )
}

function Row({ idx, eyebrow, title, body, bullets, visual, flip }) {
  return (
    <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
      <div className={flip ? 'lg:order-2' : ''}>
        <p className="idx mb-3">{idx}</p>
        <span className="eyebrow eyebrow-muted mb-4 block">{eyebrow}</span>
        <h3 className="font-display text-3xl lg:text-4xl font-semibold text-ink leading-tight mb-4">{title}</h3>
        <p className="text-ink-soft leading-relaxed mb-6 max-w-md">{body}</p>
        <ul className="space-y-2.5">
          {bullets.map((b, i) => (
            <li key={i} className="flex items-start gap-2.5 text-sm text-ink">
              <Check size={16} className="text-clay mt-0.5 flex-shrink-0" /> {b}
            </li>
          ))}
        </ul>
      </div>
      <div className={flip ? 'lg:order-1' : ''}>{visual}</div>
    </div>
  )
}

const SMALL = [
  { icon: <Car size={18} />, t: 'Fleet & vehicles', d: 'Registration, capacity, mileage, per-km rate and full service history per vehicle.', bg: '#e4eafb', fg: '#2563eb' },
  { icon: <UserCheck size={18} />, t: 'Driver management', d: 'Contacts, licences and assignments — the right driver on every trip.', bg: '#ecf4de', fg: '#4d7c0f' },
  { icon: <ShieldCheck size={18} />, t: 'Compliance alerts', d: 'PUC, insurance and licence expiry reminders before they lapse.', bg: '#f7e3e0', fg: '#b91c1c' },
  { icon: <BellRing size={18} />, t: 'Daily reminders', d: "Push alerts for tomorrow's trips, dues and renewals — even when closed.", bg: '#f7edd6', fg: '#c2860b' },
  { icon: <Route size={18} />, t: 'Round-trip pricing', d: 'One-way and return fares calculated correctly, every single time.', bg: '#f6eee6', fg: '#b5651d' },
  { icon: <Wallet size={18} />, t: 'Expense logging', d: 'Fuel, tolls, repairs and maintenance, captured against each trip.', bg: '#faf0d4', fg: '#ca8a04' },
]

export default function Features() {
  return (
    <section id="features" className="px-6 py-24">
      <div className="max-w-6xl mx-auto">
        {/* heading */}
        <div className="max-w-2xl mb-20">
          <span className="eyebrow mb-4"><span className="w-6 h-px bg-clay" /> The product</span>
          <h2 className="font-display text-4xl lg:text-5xl font-semibold text-ink leading-tight">
            One app from the first enquiry to the final settlement.
          </h2>
        </div>

        {/* editorial rows */}
        <div className="space-y-24">
          <Row
            idx="01 — Booking & pricing"
            eyebrow="Auto-fare engine"
            title="Quote the right fare before the call ends."
            body="Type the pickup and drop. Vego pulls the distance and multiplies it by your vehicle's rate — tolls, fuel and driver charges layered on top, round trips handled automatically."
            bullets={['Distance pulled automatically', 'Per-vehicle per-km rates', 'One-way & return logic built in']}
            visual={<FareVisual />}
          />
          <Row
            flip
            idx="02 — Money"
            eyebrow="Payment tracking"
            title="Always know exactly who owes what."
            body="Advances, part-payments and pending balances are tracked per trip and per customer. Payment dates are recorded separately from booking dates, so your books stay honest."
            bullets={['Per-trip & per-customer balances', 'Partial payments supported', 'Unpaid trips surfaced on the dashboard']}
            visual={<PaymentsVisual />}
          />
          <Row
            idx="03 — Insight"
            eyebrow="Reports & exports"
            title="See what's actually making money."
            body="Booking, driver, vehicle, customer and revenue reports — filtered by any date range and exported to PDF or Excel for your accountant and GST filing."
            bullets={['Five report types', 'Any date range', 'PDF & Excel export']}
            visual={<ReportsVisual />}
          />
        </div>

        {/* small features grid */}
        <div className="mt-24 grid sm:grid-cols-2 lg:grid-cols-3 gap-px bg-sand-border border border-sand-border rounded-2xl overflow-hidden">
          {SMALL.map((f, i) => (
            <div key={i} className="bg-white p-7">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-4" style={{ background: f.bg, color: f.fg }}>{f.icon}</div>
              <h4 className="font-display text-lg font-semibold text-ink mb-1.5">{f.t}</h4>
              <p className="text-sm text-ink-soft leading-relaxed">{f.d}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
