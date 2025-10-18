import type { ThemeMode } from '../../types'
import './ThemeToggle.css'

interface ThemeToggleProps {
  theme: ThemeMode
  onToggle: () => void
}

const ThemeToggle = ({ theme, onToggle }: ThemeToggleProps) => {
  const isLight = theme === 'light'

  return (
    <button
      type="button"
      className={`theme-toggle ${isLight ? 'is-light' : 'is-dark'}`}
      onClick={onToggle}
      aria-label={`Switch to ${isLight ? 'dark' : 'light'} mode`}
    >
      <span className="theme-toggle__track" aria-hidden>
        <span className="theme-toggle__icon theme-toggle__icon--moon">🌙</span>
        <span className="theme-toggle__icon theme-toggle__icon--sun">☀️</span>
      </span>
      <span className="theme-toggle__thumb" aria-hidden />
      <span className="theme-toggle__sr-text">
        {isLight ? 'Light mode active' : 'Dark mode active'}
      </span>
    </button>
  )
}

export default ThemeToggle
