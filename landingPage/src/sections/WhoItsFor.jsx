import React from 'react'
import { Car, Briefcase, Building2, MapPin } from 'lucide-react'

const SEGMENTS = [
  { icon: <Car size={20} />, title: 'Travel agencies', desc: 'Daily bookings, vehicle and driver assignment, and every payment in one place.', bg: '#f6eee6', fg: '#b5651d' },
  { icon: <Briefcase size={20} />, title: 'Tour operators', desc: 'Multi-day trips with round-trip pricing, fuel and toll logs, and clean client reports.', bg: '#e4eafb', fg: '#2563eb' },
  { icon: <Building2 size={20} />, title: 'Fleet owners', desc: 'Service, document expiry and per-vehicle revenue across the whole fleet.', bg: '#ecf4de', fg: '#4d7c0f' },
  { icon: <MapPin size={20} />, title: 'Cab & rental services', desc: 'Pickups, distances and driver settlements handled fast — even on the move.', bg: '#f7edd6', fg: '#c2860b' },
]

export default function WhoItsFor() {
  return (
    <section id="who" className="px-6 py-24">
      <div className="max-w-6xl mx-auto grid lg:grid-cols-[0.85fr_1.15fr] gap-14 lg:gap-20 items-start">
        <div className="lg:sticky lg:top-28">
          <span className="eyebrow mb-4"><span className="w-6 h-px bg-clay" /> Who it's for</span>
          <h2 className="font-display text-4xl lg:text-5xl font-semibold text-ink leading-tight mb-4">
            One car or a hundred — Vego fits the way you already work.
          </h2>
          <p className="text-ink-soft text-lg leading-relaxed mb-7">
            Whether it’s a single sedan or a yard full of tempo travellers, the workflow
            bends to you, not the other way around.
          </p>
          <a href="#download" className="btn-primary inline-flex items-center px-5 py-3 rounded-xl text-sm">Get started free</a>
        </div>

        <div className="divide-y divide-sand-border border-t border-b border-sand-border">
          {SEGMENTS.map((s, i) => (
            <div key={i} className="flex items-start gap-5 py-7 group">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: s.bg, color: s.fg }}>{s.icon}</div>
              <div>
                <h3 className="font-display text-xl font-semibold text-ink mb-1">{s.title}</h3>
                <p className="text-ink-soft leading-relaxed">{s.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
