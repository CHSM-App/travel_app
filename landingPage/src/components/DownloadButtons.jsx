import React from 'react'
import { Play, Apple } from 'lucide-react'

/**
 * Store listings aren't live yet — Play & App Store show "Coming soon".
 * `onDark` flips the styles for use on the warm-charcoal CTA section.
 */
export function DownloadButtons({ size = 'md', onDark = false }) {
  const pad = size === 'lg' ? 'px-5 py-3.5' : 'px-4 py-3'
  const base = 'inline-flex items-center gap-2.5 rounded-xl transition-all cursor-pointer text-sm'
  const primary = onDark ? 'btn-on-dark' : 'btn-primary'
  const ghost = onDark
    ? 'border border-white/20 text-sand bg-transparent hover:bg-white/10'
    : 'btn-secondary'

  return (
    <div className="flex flex-wrap gap-3">
      <a href="#" onClick={e => e.preventDefault()} className={`${base} ${pad} ${primary}`}>
        <Play size={18} fill="currentColor" className="flex-shrink-0" />
        <span className="flex flex-col text-left leading-tight">
          <span className="text-[10px] opacity-70 font-normal -mb-0.5">Coming soon to</span>
          <span className="font-semibold">Google Play</span>
        </span>
      </a>

      <a href="#" onClick={e => e.preventDefault()} className={`${base} ${pad} ${ghost} transition-all`}>
        <Apple size={18} className="flex-shrink-0" />
        <span className="flex flex-col text-left leading-tight">
          <span className="text-[10px] opacity-60 font-normal -mb-0.5">Coming soon to</span>
          <span className="font-semibold">App Store</span>
        </span>
      </a>
    </div>
  )
}
