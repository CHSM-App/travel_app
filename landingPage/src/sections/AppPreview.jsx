import React from 'react'
import { Route, Car, BarChart3 } from 'lucide-react'

function Panel({ label, tag, icon, children }) {
  return (
    <div className="card rounded-2xl overflow-hidden shadow-soft">
      <div className="flex items-center justify-between px-5 py-3.5 border-b border-sand-border">
        <div className="flex items-center gap-2 text-ink">{icon}<span className="text-sm font-semibold">{label}</span></div>
        <span className="chip text-[11px]">{tag}</span>
      </div>
      <div className="p-5">{children}</div>
    </div>
  )
}

export default function AppPreview() {
  return (
    <section id="preview" className="px-6 py-24">
      <div className="max-w-6xl mx-auto">
        <div className="max-w-2xl mb-14">
          <span className="eyebrow mb-4"><span className="w-6 h-px bg-clay" /> A look inside</span>
          <h2 className="font-display text-4xl lg:text-5xl font-semibold text-ink leading-tight">
            Every screen built for speed on the road.
          </h2>
        </div>

        <div className="grid md:grid-cols-3 gap-5">
          <Panel label="Trips" tag="Bookings" icon={<Route size={16} className="text-clay" />}>
            <div className="space-y-px -mx-1">
              {[
                { n: 'Mumbai → Pune', s: 'Confirmed', p: '₹8,880', bg: '#ecf4de', fg: '#4d7c0f' },
                { n: 'Nashik → Shirdi', s: 'On the way', p: '₹3,400', bg: '#e4eafb', fg: '#2563eb' },
                { n: 'Pune → Mahabaleshwar', s: 'Upcoming', p: '₹6,250', bg: '#f7edd6', fg: '#c2860b' },
                { n: 'Mumbai → Lonavala', s: 'Completed', p: '₹4,100', bg: '#f6eee6', fg: '#8a7f73' },
              ].map((t, i) => (
                <div key={i} className="flex items-center justify-between py-3 px-1 border-b border-sand-border last:border-0">
                  <div className="min-w-0">
                    <p className="text-[13px] text-ink truncate">{t.n}</p>
                    <span className="text-[9px] px-1.5 py-0.5 rounded-full font-semibold" style={{ background: t.bg, color: t.fg }}>{t.s}</span>
                  </div>
                  <span className="text-[13px] font-mono text-ink">{t.p}</span>
                </div>
              ))}
            </div>
          </Panel>

          <Panel label="Fleet" tag="Vehicles" icon={<Car size={16} className="text-clay" />}>
            <div className="grid grid-cols-2 gap-2.5">
              {[
                { n: 'Innova Crysta', r: 'MH-12-AB-1234', p: '₹60/km' },
                { n: 'Swift Dzire', r: 'MH-14-CD-5678', p: '₹40/km' },
                { n: 'Tempo Traveller', r: 'MH-12-EF-9012', p: '₹85/km' },
                { n: 'Ertiga', r: 'MH-12-GH-3456', p: '₹48/km' },
              ].map((v, i) => (
                <div key={i} className="border border-sand-border rounded-xl p-3">
                  <p className="text-[13px] font-medium text-ink">{v.n}</p>
                  <p className="text-[9px] font-mono text-ink-soft mt-0.5">{v.r}</p>
                  <p className="text-sm font-semibold text-clay mt-1.5">{v.p}</p>
                </div>
              ))}
            </div>
          </Panel>

          <Panel label="Reports" tag="Analytics" icon={<BarChart3 size={16} className="text-clay" />}>
            <div className="bg-ink rounded-xl p-4 mb-3">
              <p className="text-[10px] text-sand/55">Revenue · this week</p>
              <p className="font-display text-2xl font-semibold text-sand">₹84,500</p>
              <p className="text-[10px] text-sand/45 mt-0.5">26 trips · ₹22,140 expenses</p>
            </div>
            <div className="flex items-end gap-1.5 h-20">
              {[44, 62, 38, 80, 56, 70, 100].map((h, i) => (
                <div key={i} className="flex-1 rounded-t-md" style={{ height: `${h}%`, background: i === 6 ? '#b5651d' : '#f6eee6', border: '1px solid #ece4d9' }} />
              ))}
            </div>
          </Panel>
        </div>
      </div>
    </section>
  )
}
