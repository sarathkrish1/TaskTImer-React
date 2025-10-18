import type { ThemeMode } from '../../types'
import ThemeToggle from '../ThemeToggle/ThemeToggle'
import './AppHeader.css'

interface AppHeaderProps {
  formattedIST: string
  theme: ThemeMode
  onToggleTheme: () => void
  totalPoints: number
}

const AppHeader = ({ formattedIST, theme, onToggleTheme, totalPoints }: AppHeaderProps) => (
  <header className="app-header">
    <div className="hero-copy">
      <h1>Study Sprint Planner</h1>
      <p>Design your focus, execute with intent, and earn momentum points.</p>
    </div>
    <div className="header-utilities">
      <div className="ist-clock">
        <span className="clock-label">India Time</span>
        <span className="clock-value">{formattedIST}</span>
      </div>
      <ThemeToggle theme={theme} onToggle={onToggleTheme} />
      <div className="points-badge">
        <span className="points-label">Points</span>
        <span className="points-value">{totalPoints}</span>
        <span className="points-hint">Completed task score</span>
      </div>
    </div>
  </header>
)

export default AppHeader
