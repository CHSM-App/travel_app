import React from 'react'

const STEPS = [
  { n: '01', c: '#b5651d', title: 'Add your fleet', desc: 'Register vehicles, drivers and customers in minutes. Set each vehicle’s per-km rate once — Vego does the maths forever after.' },
  { n: '02', c: '#2563eb', title: 'Book the trip', desc: 'Enter pickup and drop, pick a vehicle and driver, and let Vego calculate distance, fare and round-trip pricing on the spot.' },
  { n: '03', c: '#4d7c0f', title: 'Track & grow', desc: 'Record payments and expenses, watch your live ledger, and pull the reports that show what’s actually profitable.' },
]

export default function HowItWorks() {
  return (
    <section id="how" className="px-6 py-24 bg-sand-soft/40 border-y border-sand-border">
      <div className="max-w-6xl mx-auto">
        <div className="max-w-2xl mb-16">
          <span className="eyebrow mb-4"><span className="w-6 h-px bg-clay" /> Getting started</span>
          <h2 className="font-display text-4xl lg:text-5xl font-semibold text-ink leading-tight">
            Up and running in an afternoon — not a quarter.
          </h2>
          <p className="text-ink-soft mt-4 text-lg">Built for busy owners. No training. No manual.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-px bg-sand-border border border-sand-border rounded-2xl overflow-hidden">
          {STEPS.map((s, i) => (
            <div key={i} className="bg-white p-8">
              <div className="w-12 h-12 rounded-full flex items-center justify-center font-display text-lg font-semibold mb-6 text-white" style={{ background: s.c }}>{s.n}</div>
              <h3 className="font-display text-xl font-semibold text-ink mb-2">{s.title}</h3>
              <p className="text-ink-soft leading-relaxed text-[15px]">{s.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
