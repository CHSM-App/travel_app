import React from 'react'

const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.vengurlatech.vego&pcampaignid=web_share'

function PlayStoreIcon({ size = 18 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" className="flex-shrink-0">
      {/* blue — top-left sliver */}
      <path d="M3 2.5 L3 12 L7.8 12 Z" fill="#4FC3F7" />
      {/* green — upper-right large triangle */}
      <path d="M3 2.5 L7.8 12 L21 12 Z" fill="#56C22B" />
      {/* red — bottom-left sliver */}
      <path d="M3 12 L7.8 12 L3 21.5 Z" fill="#F04C3E" />
      {/* yellow — lower-right large triangle */}
      <path d="M7.8 12 L21 12 L3 21.5 Z" fill="#FFCA28" />
    </svg>
  )
}

export function DownloadButtons({ size = 'md', onDark = false }) {
  const pad = size === 'lg' ? 'px-5 py-3.5' : 'px-4 py-3'
  const base = 'inline-flex items-center gap-2.5 rounded-xl transition-all text-sm'
  const primary = onDark ? 'btn-on-dark' : 'btn-primary'

  return (
    <div className="flex flex-wrap gap-3">
      <a
        href={PLAY_STORE_URL}
        target="_blank"
        rel="noopener noreferrer"
        className={`${base} ${pad} ${primary}`}
      >
        <PlayStoreIcon size={18} />
        <span className="flex flex-col text-left leading-tight">
          <span className="text-[10px] opacity-70 font-normal -mb-0.5">Get it on</span>
          <span className="font-semibold">Google Play</span>
        </span>
      </a>
    </div>
  )
}
