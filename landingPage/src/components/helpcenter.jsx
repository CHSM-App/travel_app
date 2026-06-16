import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import Logo from './Logo'
import {
  ArrowLeft, Search, Route, Calculator, Car, Users,
  Wallet, BarChart3, Bell, Settings, MessageCircle,
  ChevronDown, ChevronUp, HelpCircle, Mail,
} from 'lucide-react'

const CATEGORIES = [
  { icon: <Route size={15} />,      label: 'Trips & Booking', id: 'trips' },
  { icon: <Calculator size={15} />, label: 'Fares & Pricing', id: 'pricing' },
  { icon: <Car size={15} />,        label: 'Vehicles',        id: 'vehicles' },
  { icon: <Users size={15} />,      label: 'Drivers',         id: 'drivers' },
  { icon: <Wallet size={15} />,     label: 'Payments',        id: 'payments' },
  { icon: <BarChart3 size={15} />,  label: 'Reports',         id: 'reports' },
  { icon: <Bell size={15} />,       label: 'Notifications',   id: 'notifications' },
  { icon: <Settings size={15} />,   label: 'Account',         id: 'account' },
]

const FAQS = [
  { category: 'trips', q: 'How do I create a new trip booking?', a: 'Open the Trips screen and tap "+ New Booking". Enter the pickup and drop locations, select the customer, choose the trip date and time, then assign a vehicle and driver. Vego auto-fills the distance and calculates the fare based on the vehicle\'s per-km rate. Review the charges and tap "Confirm Booking".' },
  { category: 'trips', q: 'Can I log a trip that already happened?', a: 'Yes. When creating a booking you can back-date the trip date and mark it as Completed. This lets you record past trips along with their final fare, expenses, and payment status so your reports stay accurate.' },
  { category: 'trips', q: 'How do I filter trips by status?', a: 'On the Trips screen, use the filter tabs at the top — All, Active, Upcoming, Completed, and Cancelled. You can also filter by date range to find a specific booking quickly.' },
  { category: 'trips', q: 'How do round trips work?', a: 'When booking, toggle "Return Trip" on. For a round trip the fare is calculated for both legs; for a one-way trip Vego applies one-way pricing automatically. The breakdown is shown before you confirm so there are no surprises.' },
  { category: 'pricing', q: 'How is the trip fare calculated?', a: 'Vego pulls the distance between pickup and drop and multiplies it by the per-km rate set on the assigned vehicle. You can then add toll, driver, fuel, and repair charges. The total updates live as you edit each field.' },
  { category: 'pricing', q: 'Where do I set the per-km rate?', a: 'The per-km rate is set on each vehicle. Go to Fleet → Vehicles, open a vehicle, and edit its "Per-km charge". Every new trip using that vehicle will use this rate by default — you can still override the fare on an individual booking.' },
  { category: 'pricing', q: 'Can I add extra charges like tolls and fuel?', a: 'Yes. On the booking form you can add toll charges, driver charges, fuel charges, and repair charges separately. These are included in the trip total and itemised in your reports and exports.' },
  { category: 'vehicles', q: 'How do I add a vehicle to my fleet?', a: 'Go to Fleet → Vehicles and tap "+ Add Vehicle". Enter the name, registration number, type, fuel type, seating capacity, mileage, and per-km rate. You can also record PUC and insurance expiry dates so Vego can remind you before they lapse.' },
  { category: 'vehicles', q: 'Can I track vehicle service and maintenance?', a: 'Yes. Open a vehicle and add a service record with the date, type (service, repair, tyre change, etc.), and cost. These expenses feed into your vehicle and revenue reports so you always know the true running cost of each vehicle.' },
  { category: 'vehicles', q: 'How do I get reminders for PUC or insurance expiry?', a: 'When you enter PUC and insurance expiry dates on a vehicle, Vego tracks them and sends a push reminder before they expire. You can review all upcoming renewals from the dashboard.' },
  { category: 'drivers', q: 'How do I add a driver?', a: 'Go to Fleet → Drivers and tap "+ Add Driver". Enter the driver\'s name, phone number, address, licence number, and licence expiry date. Once added, the driver is available to assign to any trip.' },
  { category: 'drivers', q: 'Can I assign a driver to a vehicle?', a: 'Yes. You can link a default driver to a vehicle, and you can also pick any driver when creating a specific booking. This is useful when a vehicle is usually driven by one person but occasionally shared.' },
  { category: 'payments', q: 'How do I record a payment for a trip?', a: 'Open the trip and tap "Add Payment". Enter the amount received and the payment date and mode. Vego updates the trip\'s payment status to paid, partially paid, or pending, and adjusts the customer\'s outstanding balance automatically.' },
  { category: 'payments', q: 'How do I see how much a customer owes?', a: 'Open the Customers screen and select a customer to see their total pending balance across all non-cancelled trips. The dashboard also shows a count of unpaid trips so nothing slips through the cracks.' },
  { category: 'payments', q: 'Can I record partial payments?', a: 'Yes. You can add multiple payments against a single trip. Each payment reduces the pending amount until the trip is fully settled. The payment date is tracked separately from the booking date for accurate reporting.' },
  { category: 'reports', q: "How do I view today's revenue?", a: 'Open the dashboard to see today\'s revenue, expenses, and active, upcoming, and unpaid trip counts at a glance. For a deeper view, open Reports and choose the Today, Monthly, Yearly, or Custom date filter.' },
  { category: 'reports', q: 'What reports does Vego provide?', a: 'Vego offers Booking, Driver, Vehicle, Customer, and Revenue reports. Each can be filtered by date and shows totals, breakdowns, and trends to help you understand which trips, drivers, and vehicles are most profitable.' },
  { category: 'reports', q: 'Can I export reports to PDF or Excel?', a: 'Yes. From any report, tap the export icon and choose PDF or Excel. The export includes the selected date range with full detail — ideal for accounting, GST filing, or sharing with your team.' },
  { category: 'notifications', q: 'What notifications will I receive?', a: 'Vego sends push notifications for upcoming trips, pending payments, and document renewals (PUC, insurance, licence). You can also set a daily reminder to review your bookings and collections.' },
  { category: 'notifications', q: 'How do I turn notifications on or off?', a: 'Go to Settings → Notifications and toggle the reminders you want. Make sure notifications are also enabled for Vego in your device settings so alerts arrive even when the app is closed.' },
  { category: 'account', q: 'How do I sign up and log in?', a: 'Enter your mobile number to receive a WhatsApp OTP, verify it, and set a 4-digit PIN. After that you log in with your mobile number and PIN. If you forget your PIN, use "Forgot PIN" to reset it via a fresh OTP.' },
  { category: 'account', q: 'How do I update my agency profile?', a: 'Go to Profile to edit your name, agency name, city, email, and profile photo. Changes take effect immediately and appear on your exported reports.' },
  { category: 'account', q: 'I deleted a vehicle or customer by mistake — can I recover it?', a: 'Yes. Vego uses soft-delete. Go to Settings → Deleted Records to restore vehicles, drivers, or customers you removed, as long as they have not been permanently purged.' },
  { category: 'account', q: 'How do I delete my account?', a: 'You can request deletion from Settings in the app, or from the Delete Account page on our website. After verifying your phone number with an OTP, your account and all associated data are permanently deleted within 30 days. This action cannot be undone.' },
]

function FAQItem({ q, a }) {
  const [open, setOpen] = useState(false)
  return (
    <div className={`card rounded-2xl overflow-hidden cursor-pointer ${open ? 'border-clay/40' : ''}`} onClick={() => setOpen(!open)}>
      <div className="flex items-center justify-between px-5 py-4 gap-4">
        <p className="text-sm font-medium text-ink leading-snug">{q}</p>
        {open ? <ChevronUp size={17} className="flex-shrink-0 text-clay" /> : <ChevronDown size={17} className="flex-shrink-0 text-ink-soft" />}
      </div>
      {open && (
        <div className="px-5 pb-5">
          <div className="h-px mb-4 bg-sand-border" />
          <p className="text-sm text-ink-soft leading-relaxed">{a}</p>
        </div>
      )}
    </div>
  )
}

export default function HelpCenter() {
  const [search, setSearch] = useState('')
  const [activeCategory, setActiveCategory] = useState('all')

  useEffect(() => { window.scrollTo(0, 0) }, [])

  const filtered = FAQS.filter(faq => {
    const matchCat = activeCategory === 'all' || faq.category === activeCategory
    const matchSearch = !search.trim() ||
      faq.q.toLowerCase().includes(search.toLowerCase()) ||
      faq.a.toLowerCase().includes(search.toLowerCase())
    return matchCat && matchSearch
  })

  return (
    <div className="min-h-screen">
      <div className="border-b border-sand-border">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/"><Logo size={30} /></Link>
          <Link to="/" className="flex items-center gap-2 text-sm text-ink-soft hover:text-ink transition-colors">
            <ArrowLeft size={15} /> Back to Home
          </Link>
        </div>
      </div>

      <div className="bg-sand-soft/40 border-b border-sand-border">
        <div className="max-w-2xl mx-auto px-6 py-16 text-center">
          <span className="eyebrow justify-center mb-4"><HelpCircle size={13} /> Help Center</span>
          <h1 className="font-display text-4xl lg:text-5xl font-semibold text-ink mb-3">How can we help?</h1>
          <p className="text-ink-soft mb-8">Search the knowledge base or browse by topic below.</p>
          <div className="relative">
            <Search size={17} className="absolute left-4 top-1/2 -translate-y-1/2 text-ink-soft pointer-events-none" />
            <input
              type="text"
              placeholder="Search… e.g. 'add vehicle', 'fare', 'payment'"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full pl-11 pr-4 py-3.5 rounded-xl text-sm text-ink bg-white border border-sand-border outline-none focus:border-clay placeholder-ink-soft"
            />
          </div>
        </div>
      </div>

      <div className="max-w-5xl mx-auto px-6 py-14">
        <div className="flex flex-wrap gap-2 mb-10">
          <button onClick={() => setActiveCategory('all')}
            className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all ${activeCategory === 'all' ? 'btn-primary' : 'btn-secondary'}`}>
            All Topics
          </button>
          {CATEGORIES.map(cat => (
            <button key={cat.id} onClick={() => setActiveCategory(cat.id)}
              className={`flex items-center gap-1.5 px-4 py-2 rounded-xl text-xs font-semibold transition-all ${activeCategory === cat.id ? 'btn-primary' : 'btn-secondary'}`}>
              {cat.icon}{cat.label}
            </button>
          ))}
        </div>

        {search && <p className="text-xs text-ink-soft mb-6">{filtered.length} result{filtered.length !== 1 ? 's' : ''} for "{search}"</p>}

        {filtered.length > 0 ? (
          <div className="space-y-3">{filtered.map((faq, i) => <FAQItem key={i} q={faq.q} a={faq.a} />)}</div>
        ) : (
          <div className="text-center py-16">
            <HelpCircle size={36} className="mx-auto mb-3 text-ink-soft/50" />
            <p className="font-semibold text-ink mb-1">No results found</p>
            <p className="text-sm text-ink-soft">Try different keywords or browse all topics</p>
            <button onClick={() => { setSearch(''); setActiveCategory('all') }} className="mt-4 link-clay text-sm">Clear search</button>
          </div>
        )}

        <div className="mt-16 grid md:grid-cols-3 gap-5">
          <div className="bg-ink rounded-2xl p-6 text-center">
            <MessageCircle size={24} className="mx-auto mb-3 text-clay-light" />
            <h3 className="font-display font-semibold text-sand text-base mb-1">WhatsApp Support</h3>
            <p className="text-sand/50 text-xs mb-4">Chat with us for quick help</p>
            <a href="https://wa.me/919422229951" target="_blank" rel="noopener noreferrer" className="btn-on-dark inline-block text-xs px-4 py-2.5 rounded-xl">Chat on WhatsApp</a>
          </div>
          <div className="card rounded-2xl p-6 text-center">
            <Mail size={24} className="mx-auto mb-3 text-clay" />
            <h3 className="font-display font-semibold text-ink text-base mb-1">Email Support</h3>
            <p className="text-ink-soft text-xs mb-4">We reply within 24 hours</p>
            <a href="mailto:support@vengurlatech.com" className="btn-primary inline-block text-xs px-4 py-2.5 rounded-xl">support@vengurlatech.com</a>
          </div>
          <div className="card rounded-2xl p-6 text-center">
            <Settings size={24} className="mx-auto mb-3 text-ink-soft" />
            <h3 className="font-display font-semibold text-ink text-base mb-1">Delete Account</h3>
            <p className="text-ink-soft text-xs mb-4">Request permanent data deletion</p>
            <Link to="/delete-account" className="inline-block text-xs font-semibold px-4 py-2.5 rounded-xl" style={{ background: '#f7e3e0', color: '#b91c1c' }}>Deletion Form</Link>
          </div>
        </div>

        <div className="flex flex-wrap justify-center gap-6 mt-12 pt-8 border-t border-sand-border text-xs text-ink-soft">
          <Link to="/" className="hover:text-ink transition-colors">Home</Link>
          <Link to="/privacy" className="hover:text-ink transition-colors">Privacy Policy</Link>
          <Link to="/delete-account" className="hover:text-ink transition-colors">Delete Account</Link>
          <a href="mailto:support@vengurlatech.com" className="hover:text-ink transition-colors">Contact</a>
        </div>
      </div>
    </div>
  )
}
