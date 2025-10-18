import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import AppHeader from './components/AppHeader/AppHeader'
import FocusCard from './components/FocusCard/FocusCard'
import PlanBoard from './components/PlanBoard/PlanBoard'
import TimerCard from './components/TimerCard/TimerCard'
import { PLAN_CONFIG, initialTasks } from './constants/planConfig'
import type { PlanTask, PlanType, ThemeMode } from './types'
import './App.css'

const resolvePreferredTheme = (): ThemeMode => {
  if (typeof window === 'undefined') {
    return 'dark'
  }

  try {
    const stored = window.localStorage.getItem('study-sprint-theme')
    if (stored === 'light' || stored === 'dark') {
      return stored
    }
  } catch (error) {
    console.warn('Unable to access stored theme preference', error)
  }

  const mediaQuery = window.matchMedia?.('(prefers-color-scheme: light)') ?? null
  return mediaQuery?.matches ? 'light' : 'dark'
}

function App() {
  const defaultFocusSeconds = PLAN_CONFIG.hour.defaultDurationMinutes * 60

  const [tasks, setTasks] = useState<PlanTask[]>(initialTasks)
  const [focusTaskId, setFocusTaskId] = useState<string | null>(null)
  const [timerSeconds, setTimerSeconds] = useState(defaultFocusSeconds)
  const [secondsRemaining, setSecondsRemaining] = useState(defaultFocusSeconds)
  const [isRunning, setIsRunning] = useState(false)
  const [sessionNote, setSessionNote] = useState('Define why this sprint matters to stay locked in.')
  const [theme, setTheme] = useState<ThemeMode>(() => {
    const initialTheme = resolvePreferredTheme()
    if (typeof document !== 'undefined') {
      document.documentElement.setAttribute('data-theme', initialTheme)
    }
    return initialTheme
  })
  const [now, setNow] = useState(() => new Date())
  const audioCtxRef = useRef<AudioContext | null>(null)

  const focusTask = useMemo(
    () => tasks.find((task) => task.id === focusTaskId) ?? null,
    [focusTaskId, tasks],
  )

  const focusPlanTitle = focusTask ? PLAN_CONFIG[focusTask.plan].title : ''

  const istFormatter = useMemo(
    () =>
      new Intl.DateTimeFormat('en-IN', {
        timeZone: 'Asia/Kolkata',
        weekday: 'long',
        day: '2-digit',
        month: 'long',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
      }),
    [],
  )

  const formattedIST = istFormatter.format(now)

  const totalPoints = useMemo(
    () =>
      tasks.reduce((sum, task) => (task.completed ? sum + task.points : sum), 0),
    [tasks],
  )

  useEffect(() => {
    if (!isRunning) {
      setSecondsRemaining(timerSeconds)
    }
  }, [timerSeconds, isRunning])

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme)
    if (typeof window !== 'undefined') {
      try {
        window.localStorage.setItem('study-sprint-theme', theme)
      } catch (error) {
        console.warn('Unable to persist theme preference', error)
      }
    }
  }, [theme])

  useEffect(() => {
    const intervalId = window.setInterval(() => setNow(new Date()), 1000)
    return () => window.clearInterval(intervalId)
  }, [])

  const ensureAudioContext = useCallback(() => {
    const existing = audioCtxRef.current
    if (existing) {
      if (existing.state === 'suspended') {
        existing.resume().catch(() => undefined)
      }
      return existing
    }

    try {
      const context = new AudioContext()
      audioCtxRef.current = context
      return context
    } catch (error) {
      console.warn('AudioContext unavailable', error)
      return null
    }
  }, [])

  const playAlarm = useCallback(() => {
    const context = ensureAudioContext()
    if (!context) {
      return
    }

    const playTone = () => {
      const now = context.currentTime
      const oscillator = context.createOscillator()
      const gain = context.createGain()

      oscillator.type = 'triangle'
      oscillator.frequency.setValueAtTime(880, now)
      oscillator.frequency.exponentialRampToValueAtTime(440, now + 1.6)

      gain.gain.setValueAtTime(0.0001, now)
      gain.gain.exponentialRampToValueAtTime(0.55, now + 0.08)
      gain.gain.exponentialRampToValueAtTime(0.0001, now + 1.8)

      oscillator.connect(gain)
      gain.connect(context.destination)

      oscillator.start(now)
      oscillator.stop(now + 1.8)
    }

    if (context.state === 'suspended') {
      context.resume().then(playTone).catch(() => undefined)
    } else {
      playTone()
    }
  }, [ensureAudioContext])

  const handleTimerComplete = useCallback(() => {
    setIsRunning(false)
    setSecondsRemaining(0)
    playAlarm()

    if (!focusTaskId) {
      return
    }

    setTasks((prev) => {
      const target = prev.find((task) => task.id === focusTaskId)
      if (!target || target.completed) {
        return prev
      }

      return prev.map((task) =>
        task.id === focusTaskId ? { ...task, completed: true } : task,
      )
    })
  }, [focusTaskId, playAlarm])

  useEffect(() => {
    if (!isRunning) {
      return
    }

    const intervalId = window.setInterval(() => {
      setSecondsRemaining((prev) => {
        if (prev <= 1) {
          window.clearInterval(intervalId)
          handleTimerComplete()
          return 0
        }
        return prev - 1
      })
    }, 1000)

    return () => window.clearInterval(intervalId)
  }, [isRunning, handleTimerComplete])

  const totalSeconds = Math.max(timerSeconds, 1)
  const progress = Math.min(
    100,
    Math.max(0, ((totalSeconds - secondsRemaining) / totalSeconds) * 100),
  )

  const completedCount = useMemo(
    () => tasks.filter((task) => task.completed).length,
    [tasks],
  )

  const remainingCount = tasks.length - completedCount

  const handleAddTask = (plan: PlanType, title: string) => {
    const id = `${plan}-${Date.now().toString(36)}-${Math.random()
      .toString(36)
      .slice(2, 6)}`

    setTasks((prev) => [
      ...prev,
      {
        id,
        title,
        plan,
        completed: false,
        points: PLAN_CONFIG[plan].points,
      },
    ])
  }

  const toggleTask = (taskId: string) => {
    setTasks((prev) =>
      prev.map((task) =>
        task.id === taskId ? { ...task, completed: !task.completed } : task,
      ),
    )
  }

  const assignFocusTask = (taskId: string, plan: PlanType) => {
    setFocusTaskId(taskId)
    if (!isRunning) {
      setTimerSeconds(PLAN_CONFIG[plan].defaultDurationMinutes * 60)
    }
  }

  const handleTimerInput = (value: string) => {
    const parsed = Number(value)
    if (Number.isNaN(parsed)) {
      return
    }
    const bounded = Math.max(1, Math.floor(parsed))
    setTimerSeconds(bounded)
  }

  const handleStartPause = () => {
    ensureAudioContext()

    if (isRunning) {
      setIsRunning(false)
      return
    }

    if (secondsRemaining === 0) {
      setSecondsRemaining(timerSeconds)
    }

    setIsRunning(true)
  }

  const handleReset = () => {
    setIsRunning(false)
    setSecondsRemaining(timerSeconds)
  }

  const wrapUpFocusTask = () => {
    if (!focusTaskId) {
      return
    }
    setTasks((prev) => {
      const target = prev.find((task) => task.id === focusTaskId)
      if (!target || target.completed) {
        return prev
      }

      return prev.map((task) =>
        task.id === focusTaskId ? { ...task, completed: true } : task,
      )
    })
  }

  const updateTaskPoints = (taskId: string, rawValue: string) => {
    setTasks((prev) => {
      const parsed = Number(rawValue)
      if (Number.isNaN(parsed)) {
        return prev
      }
      const bounded = Math.max(0, Math.min(999, Math.floor(parsed)))
      return prev.map((task) =>
        task.id === taskId ? { ...task, points: bounded } : task,
      )
    })
  }

  const toggleTheme = () => {
    setTheme((current) => (current === 'dark' ? 'light' : 'dark'))
  }

  return (
    <div className="app-shell">
      <div className="app-backdrop" aria-hidden />
      <AppHeader
        formattedIST={formattedIST}
        theme={theme}
        onToggleTheme={toggleTheme}
        totalPoints={totalPoints}
      />

      <main className="content-grid">
        <TimerCard
          secondsRemaining={secondsRemaining}
          timerSeconds={timerSeconds}
          isRunning={isRunning}
          progress={progress}
          focusTask={focusTask}
          onDurationChange={handleTimerInput}
          onStartPause={handleStartPause}
          onReset={handleReset}
        />

        <FocusCard
          focusTask={focusTask}
          focusPlanTitle={focusPlanTitle}
          completedCount={completedCount}
          remainingCount={remainingCount}
          sessionNote={sessionNote}
          onSessionNoteChange={setSessionNote}
          onWrapUp={wrapUpFocusTask}
        />

        <PlanBoard
          tasks={tasks}
          planConfig={PLAN_CONFIG}
          focusTaskId={focusTaskId}
          onToggleTask={toggleTask}
          onAssignFocusTask={assignFocusTask}
          onUpdateTaskPoints={updateTaskPoints}
          onAddTask={handleAddTask}
        />
      </main>
    </div>
  )
}

export default App
