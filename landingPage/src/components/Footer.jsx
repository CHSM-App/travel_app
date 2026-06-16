import React from 'react'
import { Link } from 'react-router-dom'
import Logo from './Logo'

const LINKS = {
  Product: [
    { label: 'Features', href: '/#features' },
    { label: 'How it works', href: '/#how' },
    { label: 'App preview', href: '/#preview' },
    { label: 'Download', href: '/#download' },
  ],
  Support: [
    { label: 'Help Center', href: '/help' },
    { label: 'Contact', href: 'mailto:support@vengurlatech.com' },
    { label: 'WhatsApp', href: 'https://wa.me/919422229951' },
  ],
  Legal: [
    { label: 'Privacy Policy', href: '/privacy' },
    { label: 'Delete Account', href: '/delete-account' },
  ],
}

function FooterLink({ href, label }) {
  const cls = 'text-sand/55 hover:text-sand transition-colors'
  if (href.startsWith('/') && !href.startsWith('/#')) return <Link to={href} className={cls}>{label}</Link>
  const external = href.startsWith('http') || href.startsWith('mailto')
  return <a href={href} className={cls} {...(external ? { target: '_blank', rel: 'noopener noreferrer' } : {})}>{label}</a>
}

export default function Footer() {
  return (
    <footer className="bg-ink text-sand px-6 pt-16 pb-10">
      <div className="max-w-6xl mx-auto">
        <div className="grid md:grid-cols-[1.4fr_1fr_1fr_1fr] gap-10 pb-12 border-b border-white/10">
          <div className="max-w-xs">
            <Logo size={32} tone="light" />
            <p className="font-display text-xl leading-snug mt-5 text-sand">
              Park the paperwork.<br />
              <span className="text-clay-light">Drive the profit.</span>
            </p>
            <p className="text-sm text-sand/50 mt-4 leading-relaxed">
              Fleet & trip management for India's travel agencies, tour operators and cab services.
            </p>
          </div>

          {Object.entries(LINKS).map(([col, items]) => (
            <div key={col}>
              <p className="text-xs font-semibold uppercase tracking-wider text-sand/40 mb-4">{col}</p>
              <ul className="space-y-3 text-sm">
                {items.map(item => <li key={item.label}><FooterLink href={item.href} label={item.label} /></li>)}
              </ul>
            </div>
          ))}
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-7">
          <p className="text-xs text-sand/40">© 2026 Vego by VengurlaTech · Built in India.</p>
          <div className="flex items-center gap-2 text-xs text-sand/40">
            <span className="w-1.5 h-1.5 rounded-full bg-success inline-block" />
            All systems operational
          </div>
        </div>
      </div>
    </footer>
  )
}
