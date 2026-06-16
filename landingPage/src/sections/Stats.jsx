import React from 'react'

const STATS = [
  { v: '60 sec', l: 'to book a trip', dot: '#4d7c0f' },
  { v: '5 min', l: 'to set up your agency', dot: '#2563eb' },
  { v: '100%', l: 'of fares auto-priced', dot: '#c98a4b' },
  { v: '0', l: 'paper registers', dot: '#c2860b' },
]

export default function Stats() {
  return (
    <section className="px-6 py-20 bg-ink">
      <div className="max-w-6xl mx-auto">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-y-10">
          {STATS.map((s, i) => (
            <div key={i} className={`text-center px-6 ${i > 0 ? 'md:border-l border-white/10' : ''}`}>
              <span className="inline-block w-2 h-2 rounded-full mb-4" style={{ background: s.dot }} />
              <p className="font-display text-5xl md:text-6xl font-semibold text-sand leading-none">{s.v}</p>
              <p className="text-sm text-sand/55 mt-3">{s.l}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
