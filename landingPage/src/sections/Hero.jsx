import React from 'react'
import { ArrowRight, Star, Navigation, TrendingUp } from 'lucide-react'
import { DownloadButtons } from '../components/DownloadButtons'

/* App-authentic phone mockup — Warm Sand, flat, no gradients. */
function PhoneMock() {
  return (
    <div className="phone w-[280px]">
      <div className="rounded-[31px] overflow-hidden bg-white h-[572px] relative border border-sand-border">
        {/* status bar */}
        <div className="flex items-center justify-between px-5 pt-3.5 pb-1.5 text-[10px] text-ink-soft font-mono">
          <span>9:41</span><span>5G</span>
        </div>

        {/* header */}
        <div className="px-5 pt-1 flex items-center justify-between">
          <div>
            <p className="text-[11px] text-ink-soft">Mon, 16 June</p>
            <p className="font-display text-lg font-semibold text-ink leading-tight">Rajesh Travels</p>
          </div>
          <div className="w-9 h-9 rounded-full bg-ink flex items-center justify-center text-[11px] font-semibold text-sand">RT</div>
        </div>

        {/* summary card — warm charcoal, exactly like the app's hero card */}
        <div className="mx-5 mt-4 rounded-2xl bg-ink p-4">
          <p className="text-[11px] text-sand/55">Today's revenue</p>
          <p className="font-display text-3xl font-semibold text-sand mt-0.5">₹24,600</p>
          <div className="grid grid-cols-2 gap-3 mt-4 pt-3 border-t border-white/10">
            <div><p className="text-[10px] text-sand/45">Active trips</p><p className="text-sm font-semibold text-sand">7</p></div>
            <div><p className="text-[10px] text-sand/45">Pending dues</p><p className="text-sm font-semibold text-sand">₹12,400</p></div>
          </div>
        </div>

        {/* live trips */}
        <div className="px-5 mt-5">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-ink-soft mb-2.5">Live trips</p>
          {[
            { r: 'Mumbai → Pune', v: 'Innova · Suresh', s: 'Confirmed', bg: '#ecf4de', fg: '#4d7c0f' },
            { r: 'Nashik → Shirdi', v: 'Dzire · Amit', s: 'On the way', bg: '#e4eafb', fg: '#2563eb' },
            { r: 'Pune → Lonavala', v: 'Ertiga · Vikas', s: 'Upcoming', bg: '#f7edd6', fg: '#c2860b' },
          ].map((t, i) => (
            <div key={i} className="flex items-center gap-3 py-3 border-b border-sand-border last:border-0">
              <div className="w-8 h-8 rounded-lg bg-clay-soft flex items-center justify-center text-clay flex-shrink-0">
                <Navigation size={14} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-[12px] font-medium text-ink truncate">{t.r}</p>
                <p className="text-[10px] text-ink-soft truncate">{t.v}</p>
              </div>
              <span className="text-[9px] px-2 py-0.5 rounded-full font-semibold" style={{ background: t.bg, color: t.fg }}>{t.s}</span>
            </div>
          ))}
        </div>

        {/* bottom tab */}
        <div className="absolute bottom-0 inset-x-0 bg-white border-t border-sand-border px-7 py-3 flex justify-between text-[9px]">
          {['Home', 'Trips', 'Fleet', 'Reports'].map((t, i) => (
            <span key={t} className={i === 0 ? 'text-clay font-semibold' : 'text-ink-soft'}>{t}</span>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function Hero() {
  return (
    <section id="home" className="relative px-6 pt-32 pb-20 lg:pt-36 lg:pb-28 overflow-hidden">
      <div className="max-w-6xl mx-auto">
        <div className="grid lg:grid-cols-[1.1fr_0.9fr] gap-16 items-center">

          {/* ── Left ── */}
          <div>
            <span className="eyebrow mb-6 animate-fadeUp anim-init d1">
              <span className="w-6 h-px bg-clay" /> For India's travel agencies
            </span>

            <h1 className="font-display text-5xl lg:text-[4.2rem] font-semibold text-ink leading-[1.02] tracking-tight mb-7 animate-fadeUp anim-init d2">
              Park the paperwork.<br />
              <span className="text-clay">Drive the profit.</span>
            </h1>

            <p className="text-lg text-ink-soft leading-relaxed max-w-xl mb-9 animate-fadeUp anim-init d3">
              Vego replaces the diary, the calculator and the payment register with one
              quiet app. Book a trip in under a minute, auto-price every kilometre, and
              know exactly who owes what — without ever opening a spreadsheet.
            </p>

            <div className="flex flex-wrap items-center gap-4 animate-fadeUp anim-init d4">
              <a href="#download" className="btn-primary inline-flex items-center gap-2 px-5 py-3 rounded-xl text-sm">
                Get the app <ArrowRight size={16} />
              </a>
              <a href="#how" className="link-clay text-sm inline-flex items-center gap-1.5">
                See how it works
              </a>
            </div>

            <div className="flex items-center gap-3 mt-9 animate-fadeUp anim-init d5">
              <div className="flex">{[...Array(5)].map((_, i) => <Star key={i} size={14} className="text-star" fill="currentColor" />)}</div>
              <p className="text-sm text-ink-soft">Loved by agency owners · <span className="text-ink font-medium">set up in 5 minutes</span></p>
            </div>
          </div>

          {/* ── Right – phone on a bold clay stage ── */}
          <div className="relative flex justify-center animate-fadeUp anim-init d3">
            {/* bold flat color block — energy without gradients */}
            <div className="absolute inset-x-0 lg:-inset-x-4 top-6 bottom-6 bg-clay rounded-[2.5rem]" />
            <div className="absolute right-6 -top-3 w-28 h-28 rounded-3xl bg-warning/90 hidden lg:block rotate-12" />
            <div className="absolute left-2 bottom-2 w-20 h-20 rounded-2xl bg-ink hidden lg:block -rotate-6" />

            <div className="relative z-10 py-10 animate-floaty">
              <PhoneMock />

              {/* one tasteful floating proof point */}
              <div className="absolute -left-5 top-20 bg-white rounded-2xl shadow-card px-4 py-3 flex items-center gap-3 hidden sm:flex">
                <div className="w-9 h-9 rounded-full bg-successSoft flex items-center justify-center" style={{ color: '#4d7c0f' }}>
                  <TrendingUp size={16} />
                </div>
                <div>
                  <p className="text-xs font-semibold text-ink leading-none">+18% this week</p>
                  <p className="text-[10px] text-ink-soft mt-1">vs. last week</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
