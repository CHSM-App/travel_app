import React, { useState } from 'react'

/**
 * Vego brand lockup: your logo mark + wordmark.
 * Save your uploaded logo to  landingPage/public/logo.png  — Vite copies the
 * public/ folder into the build. If absent, we show just the wordmark.
 * Pass tone="light" on dark (charcoal) backgrounds.
 */
export default function Logo({ size = 32, showWord = true, tone = 'dark' }) {
  const [ok, setOk] = useState(true)
  const word = tone === 'light' ? '#faf7f2' : '#292420'

  return (
    <div className="flex items-center gap-2.5 select-none">
      {ok && (
        <img
          src="/logo.png"
          onError={() => setOk(false)}
          alt="Vego"
          style={{ height: size, width: size }}
          className="object-contain"
          draggable={false}
        />
      )}
      {showWord && (
        <span
          className="font-display font-semibold tracking-tight leading-none"
          style={{ fontSize: Math.round(size * 0.74), color: word }}
        >
          Vego
        </span>
      )}
    </div>
  )
}
