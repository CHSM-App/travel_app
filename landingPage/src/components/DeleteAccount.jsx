import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import Logo from './Logo'
import { ArrowLeft, AlertTriangle, Phone, KeyRound, FileText, CheckCircle, XCircle, Loader2 } from 'lucide-react'

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'https://vego.vengurlatech.com'

async function apiPost(path, body) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })
  const raw = await res.text()
  let data = null
  try { data = raw ? JSON.parse(raw) : null } catch (_) { data = null }
  if (!res.ok) throw new Error(data?.error || data?.message || 'Something went wrong.')
  if (!data || typeof data !== 'object') throw new Error('Something went wrong.')
  return data
}

function StepDot({ n, active, done }) {
  return (
    <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold transition-all"
      style={done ? { background: '#b5651d', color: '#faf7f2' }
        : active ? { background: '#292420', color: '#faf7f2' }
        : { background: '#f6eee6', color: '#8a7f73' }}>
      {done ? '✓' : n}
    </div>
  )
}

function Steps({ current }) {
  const labels = ['Phone', 'Verify OTP', 'Confirm']
  return (
    <div className="flex items-center gap-0 mb-8">
      {labels.map((label, i) => (
        <React.Fragment key={i}>
          <div className="flex flex-col items-center gap-1.5 flex-shrink-0">
            <StepDot n={i + 1} active={current === i} done={current > i} />
            <span className="text-xs font-medium" style={{ color: current >= i ? '#292420' : '#8a7f73' }}>{label}</span>
          </div>
          {i < labels.length - 1 && (
            <div className="flex-1 h-0.5 mx-2 mb-4 rounded-full" style={{ background: current > i ? '#b5651d' : '#ece4d9' }} />
          )}
        </React.Fragment>
      ))}
    </div>
  )
}

export default function DeleteAccount() {
  const [step, setStep]     = useState(0)
  const [phone, setPhone]   = useState('')
  const [otp, setOtp]       = useState('')
  const [reason, setReason] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError]   = useState('')
  const [scheduled, setScheduled] = useState(null)

  useEffect(() => { window.scrollTo(0, 0) }, [])
  const clearError = () => setError('')

  // Step 0 → request a WhatsApp OTP for deletion
  async function handleSendOtp(e) {
    e.preventDefault(); clearError()
    if (!/^\d{10}$/.test(phone)) return setError('Enter a valid 10-digit phone number.')
    setLoading(true)
    // The backend rejects (no OTP sent) if the number has no account or already
    // has a pending deletion request — those errors keep the user on this step.
    try { await apiPost('/login/sendOtp', { mobile: phone, purpose: 'delete_account' }); setStep(1) }
    catch (err) { setError(err.message) } finally { setLoading(false) }
  }

  // Step 1 → only validate the code locally; the OTP is single-use, so it is
  // verified server-side at the final delete step (handleConfirm).
  function handleVerifyOtp(e) {
    e.preventDefault(); clearError()
    if (!/^\d{6}$/.test(otp)) return setError('OTP must be exactly 6 digits.')
    setStep(2)
  }

  // Step 2 → verify OTP + record the deletion request (team deletes manually)
  async function handleConfirm(e) {
    e.preventDefault(); clearError(); setLoading(true)
    try {
      const data = await apiPost('/login/deleteAccount', { mobile: phone, otp, reason: reason.trim() || undefined })
      if (data.scheduled_for) setScheduled(new Date(data.scheduled_for))
      setStep(3)
    } catch (err) {
      if (err.message.toLowerCase().includes('otp')) { setStep(1); setOtp('') }
      setError(err.message)
    } finally { setLoading(false) }
  }

  const inputCls = 'w-full px-4 py-3 rounded-xl text-sm outline-none transition-all bg-white text-ink placeholder-ink-soft border border-sand-border focus:border-clay'
  const btnPrimary = (disabled) => ({ background: disabled ? '#ece4d9' : '#292420', color: disabled ? '#8a7f73' : '#faf7f2', cursor: disabled ? 'not-allowed' : 'pointer' })

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
        <div className="max-w-xl mx-auto px-6 py-14 text-center">
          <span className="eyebrow justify-center mb-4" style={{ color: '#b91c1c' }}><AlertTriangle size={13} /> Permanent action</span>
          <h1 className="font-display text-4xl font-semibold text-ink mb-3">Delete Account</h1>
          <p className="text-ink-soft text-sm leading-relaxed">
            Permanently delete your Vego account and all associated fleet, trip, and financial data.
            This cannot be undone after the 30-day grace period.
          </p>
        </div>
      </div>

      <div className="max-w-xl mx-auto px-6 py-12">
        {step === 3 && (
          <div className="card rounded-2xl p-8 text-center">
            <div className="w-14 h-14 rounded-full flex items-center justify-center mx-auto mb-4" style={{ background: '#f7e3e0' }}>
              <CheckCircle size={28} style={{ color: '#b91c1c' }} />
            </div>
            <h2 className="font-display font-semibold text-ink text-xl mb-2">Request Received</h2>
            <p className="text-sm text-ink-soft leading-relaxed mb-4">
              Your account deletion request has been submitted. Our team will review it and
              permanently delete your account and all associated data <strong className="text-ink">within 30 days</strong>.
            </p>
            {scheduled && (
              <div className="inline-flex items-center gap-2 rounded-full px-4 py-1.5 mb-5 text-xs font-semibold" style={{ background: '#f6eee6', color: '#92500f' }}>
                Scheduled for deletion by {scheduled.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' })}
              </div>
            )}
            <div className="rounded-xl p-4 text-left text-sm text-ink-soft leading-relaxed mb-6 border border-sand-border bg-sand-soft/50">
              <strong className="text-ink">Changed your mind?</strong> Contact support@vengurlatech.com before the 30-day window ends and we will keep your account active.
            </div>
            <Link to="/" className="btn-dark inline-block text-sm px-5 py-2.5 rounded-xl">Back to Home</Link>
          </div>
        )}

        {step < 3 && (
          <div className="card rounded-2xl overflow-hidden">
            <div className="px-6 py-4 flex items-start gap-3" style={{ background: '#f7e3e0', borderBottom: '1px solid #f0cfc9' }}>
              <AlertTriangle size={18} className="flex-shrink-0 mt-0.5" style={{ color: '#b91c1c' }} />
              <p className="text-xs leading-relaxed" style={{ color: '#7a1414' }}>
                <strong>This requests permanent deletion of all your data</strong> — trips, bookings, vehicles, drivers, customers, payments, and reports. Your account will be deleted within 30 days and cannot be recovered after that.
              </p>
            </div>

            <div className="p-6">
              <Steps current={step} />

              {error && (
                <div className="flex items-center gap-2 rounded-xl px-4 py-3 mb-5 text-sm" style={{ background: '#f7e3e0', color: '#b91c1c' }}>
                  <XCircle size={15} className="flex-shrink-0" /> {error}
                </div>
              )}

              {step === 0 && (
                <form onSubmit={handleSendOtp} className="space-y-4">
                  <label className="block text-xs font-semibold text-ink mb-1.5">Registered Phone Number</label>
                  <div className="relative">
                    <Phone size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-soft pointer-events-none" />
                    <input type="tel" inputMode="numeric" maxLength={10} placeholder="10-digit mobile number" value={phone}
                      onChange={e => setPhone(e.target.value.replace(/\D/g, '').slice(0, 10))} className={`${inputCls} pl-10`} required />
                  </div>
                  <p className="text-xs text-ink-soft">We'll send a one-time verification code to this number via WhatsApp.</p>
                  <button type="submit" disabled={loading || phone.length !== 10}
                    className="w-full py-3 rounded-xl text-sm font-bold flex items-center justify-center gap-2" style={btnPrimary(loading || phone.length !== 10)}>
                    {loading && <Loader2 size={15} className="animate-spin" />}{loading ? 'Sending OTP…' : 'Send Verification Code'}
                  </button>
                </form>
              )}

              {step === 1 && (
                <form onSubmit={handleVerifyOtp} className="space-y-4">
                  <label className="block text-xs font-semibold text-ink mb-1.5">Enter the 6-digit code sent to +91 {phone}</label>
                  <div className="relative">
                    <KeyRound size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-soft pointer-events-none" />
                    <input type="tel" inputMode="numeric" maxLength={6} placeholder="6-digit OTP" value={otp}
                      onChange={e => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} className={`${inputCls} pl-10 tracking-[0.4em] text-center font-mono text-lg`} autoFocus required />
                  </div>
                  <p className="text-xs text-ink-soft">The code expires in 10 minutes.{' '}
                    <button type="button" className="link-clay" onClick={() => { setOtp(''); setStep(0); clearError() }}>Change number</button>
                  </p>
                  <button type="submit" disabled={loading || otp.length !== 6}
                    className="w-full py-3 rounded-xl text-sm font-bold flex items-center justify-center gap-2" style={btnPrimary(loading || otp.length !== 6)}>
                    {loading && <Loader2 size={15} className="animate-spin" />}{loading ? 'Verifying…' : 'Verify & Continue'}
                  </button>
                </form>
              )}

              {step === 2 && (
                <form onSubmit={handleConfirm} className="space-y-5">
                  <div className="rounded-xl p-4 text-sm leading-relaxed" style={{ background: '#f7e3e0', border: '1px solid #f0cfc9' }}>
                    <p className="font-semibold mb-1" style={{ color: '#b91c1c' }}>You are requesting permanent deletion of:</p>
                    <ul className="text-ink-soft space-y-0.5 list-disc list-inside text-xs">
                      <li>All trips and booking history</li>
                      <li>All vehicles and service records</li>
                      <li>All drivers and customers</li>
                      <li>All payments, expenses, and reports</li>
                      <li>Your agency profile and settings</li>
                    </ul>
                    <p className="text-ink-soft text-xs mt-2">Our team will review your request and delete your account within 30 days.</p>
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-ink mb-1.5">Reason for leaving <span className="font-normal text-ink-soft">(optional)</span></label>
                    <div className="relative">
                      <FileText size={15} className="absolute left-3.5 top-3.5 text-ink-soft pointer-events-none" />
                      <textarea rows={3} placeholder="Help us improve Vego…" value={reason}
                        onChange={e => setReason(e.target.value.slice(0, 500))} className={`${inputCls} pl-10 resize-none`} />
                    </div>
                  </div>
                  <button type="submit" disabled={loading} className="w-full py-3 rounded-xl text-sm font-bold flex items-center justify-center gap-2 text-white"
                    style={{ background: loading ? '#d99' : '#b91c1c', cursor: loading ? 'not-allowed' : 'pointer' }}>
                    {loading && <Loader2 size={15} className="animate-spin" />}{loading ? 'Submitting…' : 'Request Account Deletion'}
                  </button>
                  <button type="button" className="w-full py-2.5 rounded-xl text-sm font-semibold btn-secondary"
                    onClick={() => { setStep(0); setOtp(''); setPhone(''); clearError() }}>
                    Cancel — Keep My Account
                  </button>
                </form>
              )}
            </div>
          </div>
        )}

        <div className="flex flex-wrap justify-center gap-6 mt-12 pt-8 border-t border-sand-border text-xs text-ink-soft">
          <Link to="/" className="hover:text-ink transition-colors">Home</Link>
          <Link to="/help" className="hover:text-ink transition-colors">Help Center</Link>
          <Link to="/privacy" className="hover:text-ink transition-colors">Privacy Policy</Link>
          <a href="mailto:support@vengurlatech.com" className="hover:text-ink transition-colors">Contact</a>
        </div>
      </div>
    </div>
  )
}
