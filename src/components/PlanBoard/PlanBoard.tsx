import { useMemo, useState, type FormEvent } from 'react'
import type { PlanDefinition, PlanTask, PlanType } from '../../types'
import './PlanBoard.css'

interface PlanBoardProps {
  tasks: PlanTask[]
  planConfig: Record<PlanType, PlanDefinition>
  focusTaskId: string | null
  onToggleTask: (taskId: string) => void
  onAssignFocusTask: (taskId: string, plan: PlanType) => void
  onUpdateTaskPoints: (taskId: string, rawValue: string) => void
  onAddTask: (plan: PlanType, title: string) => void
}

const PlanBoard = ({
  tasks,
  planConfig,
  focusTaskId,
  onToggleTask,
  onAssignFocusTask,
  onUpdateTaskPoints,
  onAddTask,
}: PlanBoardProps) => {
  const [inputs, setInputs] = useState<Record<PlanType, string>>({
    hour: '',
    day: '',
    todo: '',
  })

  const plans = useMemo(() => Object.keys(planConfig) as PlanType[], [planConfig])

  const handleSubmit = (plan: PlanType) => (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const value = inputs[plan].trim()
    if (!value) {
      return
    }

    onAddTask(plan, value)
    setInputs((prev) => ({ ...prev, [plan]: '' }))
  }

  return (
    <section className="plan-board">
      {plans.map((plan) => {
        const definition = planConfig[plan]
        const planTasks = tasks.filter((task) => task.plan === plan)

        return (
          <div key={plan} className="card plan-card">
            <header className="section-heading">
              <h3>{definition.title}</h3>
              <p>{definition.subtitle}</p>
            </header>

            <ul className="task-list">
              {planTasks.length === 0 ? (
                <li className="empty-state">
                  Nothing here yet. Set the pace with your next task.
                </li>
              ) : (
                planTasks.map((task) => (
                  <li key={task.id} className={`task-item ${task.completed ? 'completed' : ''}`}>
                    <label>
                      <input
                        type="checkbox"
                        checked={task.completed}
                        onChange={() => onToggleTask(task.id)}
                      />
                      <span>{task.title}</span>
                    </label>
                    <div className="task-actions">
                      <button
                        className="ghost"
                        onClick={() => onAssignFocusTask(task.id, task.plan)}
                        disabled={focusTaskId === task.id}
                      >
                        {focusTaskId === task.id ? 'In focus' : 'Focus next'}
                      </button>
                      <div className="points-editor" aria-label="Points for this task">
                        <span className="points-prefix">+</span>
                        <input
                          type="number"
                          min={0}
                          max={999}
                          value={task.points}
                          onChange={(event) => onUpdateTaskPoints(task.id, event.target.value)}
                        />
                        <span className="points-suffix">pts</span>
                      </div>
                    </div>
                  </li>
                ))
              )}
            </ul>

            <form className="task-form" onSubmit={handleSubmit(plan)}>
              <input
                type="text"
                value={inputs[plan]}
                onChange={(event) =>
                  setInputs((prev) => ({
                    ...prev,
                    [plan]: event.target.value,
                  }))
                }
                placeholder={definition.placeholder}
              />
              <button type="submit" className="primary">
                Add
              </button>
            </form>
          </div>
        )
      })}
    </section>
  )
}

export default PlanBoard
