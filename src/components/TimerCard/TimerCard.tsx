import type { PlanTask } from '../../types'
import './TimerCard.css'

const formatTime = (totalSeconds: number) => {
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60
  const h = hours.toString().padStart(2, '0')
  const m = minutes.toString().padStart(2, '0')
  const s = seconds.toString().padStart(2, '0')
  return `${h}:${m}:${s}`
}

const secondsToHms = (totalSeconds: number) => formatTime(totalSeconds)

const hmsToSeconds = (value: string): number | null => {
  const trimmed = value.trim()
  if (!trimmed) return null

  const parts = trimmed.split(':')
  if (parts.length > 3) return null

  const numeric = parts.map((p) => (p === '' ? NaN : Number(p)))
  if (numeric.some((n) => Number.isNaN(n))) return null

  if (parts.length === 3) {
    const [hh, mm, ss] = numeric
    if (mm < 0 || mm > 59 || ss < 0 || ss > 59 || hh < 0) return null
    return hh * 3600 + mm * 60 + ss
  }
  if (parts.length === 2) {
    const [mm, ss] = numeric
    if (mm < 0 || ss < 0 || mm > 59 || ss > 59) return null
    return mm * 60 + ss
  }
  // Single part: treat as seconds
  const [ss] = numeric
  if (ss < 0) return null
  return Math.floor(ss)
}

interface TimerCardProps {
  secondsRemaining: number
  timerSeconds: number
  isRunning: boolean
  progress: number
  focusTask: PlanTask | null
  onDurationChange: (value: string) => void
  onStartPause: () => void
  onReset: () => void
}

const TimerCard = ({
  secondsRemaining,
  timerSeconds,
  isRunning,
  progress,
  focusTask,
  onDurationChange,
  onStartPause,
  onReset,
}: TimerCardProps) => (
  <section className="card timer-card">
    <header className="section-heading">
      <h2>Focus Timer</h2>
      <p>Choose a sprint length, stay present, and let the timer mark the finish.</p>
    </header>

    <div className="timer-wrapper">
      <div className="timer-scene">
        <div
          className="timer-visual"
          style={{
            background: `conic-gradient(var(--brand-accent) ${progress}%, var(--card-muted) ${progress}% 100%)`,
          }}
        >
          <span className="timer-reading">{formatTime(secondsRemaining)}</span>
        </div>
        <div className="timer-shadow" />
      </div>
      <div className="timer-controls">
        <label className="input-label" htmlFor="timer-input">
          Duration (HH:MM:SS)
        </label>
        <input
          id="timer-input"
          type="text"
          inputMode="numeric"
          placeholder="HH:MM:SS"
          pattern="^\\d{1,2}(:\\d{2}){0,2}$"
          value={secondsToHms(timerSeconds)}
          onChange={(event) => {
            const next = hmsToSeconds(event.target.value)
            if (next === null || Number.isNaN(next) || next < 1) {
              return
            }
            onDurationChange(String(next))
          }}
        />
        <div className="timer-buttons">
          <button className="primary" onClick={onStartPause}>
            {isRunning ? 'Pause' : 'Start'}
          </button>
          <button className="ghost" onClick={onReset}>
            Reset
          </button>
        </div>
        <p className="timer-metadata">
          {focusTask
            ? `Locked on: ${focusTask.title}`
            : 'Assign a task to give this sprint a purpose.'}
        </p>
      </div>
    </div>
  </section>
)

export default TimerCard
