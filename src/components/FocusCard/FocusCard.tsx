import type { PlanTask } from '../../types'
import './FocusCard.css'

interface FocusCardProps {
  focusTask: PlanTask | null
  focusPlanTitle: string
  completedCount: number
  remainingCount: number
  sessionNote: string
  onSessionNoteChange: (value: string) => void
  onWrapUp: () => void
}

const FocusCard = ({
  focusTask,
  focusPlanTitle,
  completedCount,
  remainingCount,
  sessionNote,
  onSessionNoteChange,
  onWrapUp,
}: FocusCardProps) => (
  <section className="card focus-card">
    <header className="section-heading">
      <h2>Active Focus</h2>
      <p>Clarify the why before you press start to stay energised through the session.</p>
    </header>

    <div className="focus-summary">
      <div className="focus-task">
        <span className="focus-label">Current mission</span>
        <p className="focus-title">
          {focusTask ? focusTask.title : 'No task set. Choose one from any list.'}
        </p>
        <div className="focus-details">
          <span>{focusTask ? focusPlanTitle : 'Select a list task to focus'}</span>
          <span>Sessions won today: {completedCount} · Remaining: {remainingCount}</span>
        </div>
      </div>
      <button
        className="primary"
        onClick={onWrapUp}
        disabled={!focusTask || focusTask.completed}
      >
        Mark Focus Complete
      </button>
    </div>

    <label className="input-label" htmlFor="session-note">
      Intention note
    </label>
    <textarea
      id="session-note"
      value={sessionNote}
      onChange={(event) => onSessionNoteChange(event.target.value)}
      rows={3}
      placeholder="Define the outcome you are chasing in this sprint."
    />
  </section>
)

export default FocusCard
