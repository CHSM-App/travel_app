import React from 'react'

const ROUTES = [
  'Mumbai → Pune', 'Nashik → Shirdi', 'Pune → Mahabaleshwar', 'Delhi → Jaipur',
  'Bengaluru → Mysuru', 'Kolhapur → Goa', 'Chennai → Pondicherry', 'Surat → Saputara',
  'Ahmedabad → Statue of Unity', 'Mumbai → Lonavala',
]

export default function Ticker() {
  return (
    <div className="border-y border-sand-border bg-sand-soft/40">
      <div className="max-w-6xl mx-auto px-6 py-4 flex items-center gap-6">
        <span className="text-[11px] font-semibold uppercase tracking-wider text-ink-soft whitespace-nowrap hidden sm:block">
          Trips booked today
        </span>
        <div className="marquee-wrap flex-1">
          <div className="marquee-track animate-marquee">
            {[...ROUTES, ...ROUTES].map((r, i) => (
              <span key={i} className="px-5 text-sm text-ink-soft whitespace-nowrap font-mono">{r}</span>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
