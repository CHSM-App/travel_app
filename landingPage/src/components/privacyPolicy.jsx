import React, { useEffect } from 'react'
import { Link } from 'react-router-dom'
import Logo from './Logo'
import { ArrowLeft, Shield } from 'lucide-react'

const SECTIONS = [
  {
    title: '1. Information We Collect',
    content: [
      { subtitle: '1.1 Account Information', text: 'When you create a Vego account, we collect your name, phone number, email address (optional), travel agency name, and city. We use a WhatsApp one-time PIN/OTP to verify your phone number. This information is required to set up your agency profile and provide you with our trip-booking and fleet-management services.' },
      { subtitle: '1.2 Operational & Transaction Data', text: 'We collect data you enter into the app, including trips and bookings (pickup and drop locations, distance, dates, fares), vehicles (registration number, type, capacity, per-km rate, PUC and insurance details), drivers (name, phone, licence details), customers (name, phone, address, pending balances), payments, and expenses. This data belongs entirely to you and is stored to deliver the core booking, fleet, payment, and reporting features of Vego.' },
      { subtitle: '1.3 Device & Usage Information', text: 'We automatically collect certain technical information when you use our app, including device model, operating system version, app version, push-notification token (for reminders and alerts), and general usage patterns. This helps us diagnose issues, ensure stability, and improve the Vego experience over time.' },
      { subtitle: '1.4 Personal Data You Provide About Other People', text: 'To run your agency, Vego lets you add personal data about individuals other than yourself — including your customers (name, phone number, address, pending balances) and your drivers and staff (name, phone number, address, licence details). For this third-party information, your travel agency is the data controller and VengurlaTech acts only as a data processor on your behalf — we store and process it solely to deliver the Vego service to you and never use it for our own purposes. You are responsible for ensuring you have a lawful basis and, where required by applicable law, the consent of these individuals before adding their information to Vego, and for informing them about how their data is used. Any customer, driver, or staff member can exercise their rights (access, correction, or deletion) by contacting the agency that added them, or by writing to us at support@vengurlatech.com — we will forward such requests to the relevant agency and assist as needed.' },
    ],
  },
  {
    title: '2. How We Use Your Information',
    content: [
      { subtitle: '2.1 Providing the Service', text: 'Your data is used to operate Vego — to create bookings, calculate fares and distances, manage your vehicles and drivers, track payments and expenses, generate reports, and sync your data across devices. Your agency profile is used to personalise your experience and to label exported reports and documents.' },
      { subtitle: '2.2 Customer Support', text: 'When you contact us for help, we may access your account and operational data to diagnose and resolve the issue you are facing. We only access this data with your consent and only to the extent needed to assist you.' },
      { subtitle: '2.3 Service Improvements', text: 'Aggregated and anonymised usage data helps us understand how Vego is being used, identify common pain points, and prioritise new features. We do not use individual-level data for this purpose.' },
      { subtitle: '2.4 Communication', text: 'We may contact you via SMS, WhatsApp, push notification, or email to send important service announcements, security alerts, trip and payment reminders, or information about app updates. We do not send promotional messages without your explicit consent.' },
    ],
  },
  {
    title: '3. Data Storage & Security',
    content: [
      { subtitle: '3.1 Data Storage', text: 'Your data is stored on secure servers operated by VengurlaTech. Vego is a mobile app for Android (and, where available, iOS). Data you create is synced to our servers so it is available across your devices and protected against device loss.' },
      { subtitle: '3.2 Security Measures', text: 'We implement industry-standard security measures including encrypted data transmission (HTTPS/TLS), PIN-based authentication, short-lived access tokens with rotating refresh tokens, and strict access controls. OTPs are hashed and never stored in plain text. However, no system is completely secure, and we encourage you to keep your account PIN confidential.' },
      { subtitle: '3.3 Data Retention', text: 'We retain your data for as long as your account remains active. If you request deletion of your account, we will delete your personal data and operational records within 30 days of the request, except where retention is required by applicable law (such as tax or GST record-keeping requirements).' },
    ],
  },
  {
    title: '4. Sharing of Information',
    content: [
      { subtitle: '4.1 We Do Not Sell Your Data', text: 'Vego does not sell, rent, or trade your personal information or operational data to third parties for their marketing or any other purposes. Your business data is yours — we are custodians of it, not owners.' },
      { subtitle: '4.2 Service Providers', text: 'We share data with trusted third-party service providers who help us operate Vego — such as cloud hosting, push-notification delivery (Firebase Cloud Messaging), WhatsApp/SMS OTP delivery, mapping and distance services, and payment processors. These providers are contractually bound to protect your data and may only use it to provide services on our behalf.' },
      { subtitle: '4.3 Legal Requirements', text: 'We may disclose your information if required to do so by law, court order, or government authority, or if we believe disclosure is necessary to protect the rights, property, or safety of Vego, our users, or the public.' },
    ],
  },
  {
    title: '5. Your Rights',
    content: [
      { subtitle: '5.1 Access & Correction', text: 'You may access and update your account information at any time through the Profile and Settings sections of the Vego app. You can edit your agency details, contact information, vehicles, drivers, and customers directly without contacting support.' },
      { subtitle: '5.2 Data Export', text: 'You may export your operational data — bookings, revenue, vehicle, driver, and customer reports — directly from within the app as PDF or Excel files. You can also request a full export by contacting our support team at support@vengurlatech.com.' },
      { subtitle: '5.3 Account Deletion', text: 'You have the right to request deletion of your Vego account and all associated data at any time. You can submit a deletion request directly from the in-app Settings, via the Delete Account page on our website, or by contacting us at support@vengurlatech.com. Deletion is processed within 30 days of a verified request.' },
    ],
  },
  {
    title: "6. Children's Privacy",
    content: [{ subtitle: '', text: 'Vego is a business management tool intended for adults operating travel and transport businesses. We do not knowingly collect personal information from individuals under the age of 18. If you believe a minor has provided us with personal information, please contact us immediately and we will promptly delete it.' }],
  },
  {
    title: '7. Changes to This Policy',
    content: [{ subtitle: '', text: 'We may update this Privacy Policy from time to time to reflect changes in our practices, features, or applicable laws. When we make significant changes, we will notify you through the app or via your registered contact method. Continued use of Vego after changes are published constitutes your acceptance of the updated policy.' }],
  },
  {
    title: '8. Contact Us',
    content: [{ subtitle: '', text: 'If you have questions, concerns, or requests relating to this Privacy Policy or your data, please contact us at support@vengurlatech.com or through the Help Center. We aim to respond to all privacy-related inquiries within 48 hours.' }],
  },
]

export default function PrivacyPolicy() {
  useEffect(() => { window.scrollTo(0, 0) }, [])

  return (
    <div className="min-h-screen">
      <div className="border-b border-sand-border">
        <div className="max-w-4xl mx-auto px-6 h-16 flex items-center justify-between">
          <Link to="/"><Logo size={30} /></Link>
          <Link to="/" className="flex items-center gap-2 text-sm text-ink-soft hover:text-ink transition-colors">
            <ArrowLeft size={15} /> Back to Home
          </Link>
        </div>
      </div>

      <div className="bg-sand-soft/40 border-b border-sand-border">
        <div className="max-w-4xl mx-auto px-6 py-16">
          <span className="eyebrow mb-4"><Shield size={13} /> Legal document</span>
          <h1 className="font-display text-4xl lg:text-5xl font-semibold text-ink mb-3">Privacy Policy</h1>
          <p className="text-ink-soft max-w-xl leading-relaxed">
            How Vego collects, uses, and protects the information you provide when using our app and services.
          </p>
          <p className="text-ink-soft text-xs mt-4 font-mono">Last updated: June 2026 · Effective: June 2026</p>
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-6 py-16">
        <div className="card rounded-2xl p-6 mb-12">
          <p className="text-sm text-ink-soft leading-relaxed">
            <span className="font-semibold text-ink">Summary:</span> Vego ("we", "our", "us"), a product of
            VengurlaTech, is a trip-booking and fleet-management app for travel agencies, tour operators, and
            cab services across India. We collect only what's needed to run the app, we do not sell your data,
            and you can request deletion at any time.
          </p>
        </div>

        <div className="space-y-12">
          {SECTIONS.map((section, si) => (
            <div key={si}>
              <h2 className="font-display text-2xl font-semibold text-ink mb-5 pb-3 border-b border-sand-border">{section.title}</h2>
              <div className="space-y-5">
                {section.content.map((block, bi) => (
                  <div key={bi}>
                    {block.subtitle && <h3 className="font-semibold text-ink text-sm mb-1.5">{block.subtitle}</h3>}
                    <p className="text-sm text-ink-soft leading-relaxed">{block.text}</p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-14 bg-ink rounded-2xl p-8 text-center">
          <h3 className="font-display text-xl font-semibold text-sand mb-2">Questions about your privacy?</h3>
          <p className="text-sand/55 text-sm mb-5">We're here to help. Reach out and we'll respond within 48 hours.</p>
          <a href="mailto:support@vengurlatech.com" className="btn-on-dark inline-block px-5 py-2.5 rounded-xl text-sm">support@vengurlatech.com</a>
        </div>

        <div className="flex flex-wrap justify-center gap-6 mt-10 pt-8 border-t border-sand-border text-xs text-ink-soft">
          <Link to="/" className="hover:text-ink transition-colors">Home</Link>
          <Link to="/help" className="hover:text-ink transition-colors">Help Center</Link>
          <Link to="/delete-account" className="hover:text-ink transition-colors">Delete Account</Link>
          <a href="mailto:support@vengurlatech.com" className="hover:text-ink transition-colors">Contact</a>
        </div>
      </div>
    </div>
  )
}
