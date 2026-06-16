import React from 'react'
import { DownloadButtons } from '../components/DownloadButtons'

export default function CTA() {
  return (
    <section id="download" className="px-6 py-24">
      <div className="max-w-6xl mx-auto">
        <div className="bg-clay rounded-4xl px-8 py-20 md:px-16 md:py-24 text-center relative overflow-hidden">
          {/* flat decorative rings — no gradient */}
          <div className="absolute -top-20 -right-16 w-72 h-72 rounded-full border border-white/20" />
          <div className="absolute -bottom-24 -left-16 w-80 h-80 rounded-full border border-white/20" />
          <div className="absolute top-10 left-10 w-16 h-16 rounded-2xl bg-white/10 rotate-12 hidden md:block" />

          <div className="relative z-10">
            <p className="text-xs font-semibold uppercase tracking-[0.18em] text-white/80 mb-5">
              Set up in 5 minutes · run forever
            </p>
            <h2 className="font-display text-4xl md:text-6xl font-semibold text-white leading-[1.05] mb-6">
              Park the paperwork.<br />Drive the profit.
            </h2>
            <p className="text-white/85 text-lg max-w-xl mx-auto mb-10">
              Join the travel agencies trading registers and spreadsheets for one app.
              Your whole fleet, in your pocket.
            </p>
            <div className="flex justify-center">
              <DownloadButtons size="lg" onDark />
            </div>
            <p className="text-white/70 text-xs mt-8">
              Coming soon to Google Play & the App Store · No credit card required
            </p>
          </div>
        </div>
      </div>
    </section>
  )
}
