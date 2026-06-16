import React, { useState, useEffect } from 'react'
import { Menu, X } from 'lucide-react'
import Logo from './Logo'

const LINKS = [
  { label: 'Product',      href: '#features' },
  { label: 'How it works', href: '#how' },
  { label: 'Who it\'s for', href: '#who' },
  { label: 'Help',         href: '/help' },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [open, setOpen] = useState(false)

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 16)
    window.addEventListener('scroll', handler)
    return () => window.removeEventListener('scroll', handler)
  }, [])

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled ? 'bg-sand/90 backdrop-blur-md border-b border-sand-border' : 'border-b border-transparent'
      }`}
    >
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        <a href="#home"><Logo size={30} /></a>

        <nav className="hidden md:flex items-center gap-9">
          {LINKS.map(({ label, href }) => (
            <a key={label} href={href} className="text-sm font-medium text-ink-soft hover:text-ink transition-colors">
              {label}
            </a>
          ))}
        </nav>

        <div className="hidden md:flex items-center gap-3">
          <a href="#download" className="text-sm font-semibold text-ink hover:text-clay transition-colors">Sign in</a>
          <a href="#download" className="btn-primary text-sm px-4 py-2 rounded-xl">Get the app</a>
        </div>

        <button
          className="md:hidden p-2 -mr-2 text-ink"
          onClick={() => setOpen(!open)}
          aria-label="Toggle menu"
        >
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {open && (
        <div className="md:hidden bg-sand border-t border-sand-border px-6 py-4 space-y-1">
          {LINKS.map(({ label, href }) => (
            <a key={label} href={href} onClick={() => setOpen(false)}
              className="block text-sm font-medium text-ink py-2.5">
              {label}
            </a>
          ))}
          <a href="#download" onClick={() => setOpen(false)} className="block btn-primary text-center text-sm mt-2 px-4 py-3 rounded-xl">
            Get the app
          </a>
        </div>
      )}
    </header>
  )
}
