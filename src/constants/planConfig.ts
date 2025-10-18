import type { PlanDefinition, PlanTask, PlanType } from '../types'

export const PLAN_CONFIG: Record<PlanType, PlanDefinition> = {
  hour: {
    title: '1-Hour Plan',
    subtitle: 'Pick the mission that deserves your next deep-focus sprint.',
    placeholder: 'Outline remaining study milestones for this hour',
    points: 15,
    defaultDurationMinutes: 50,
  },
  day: {
    title: '1-Day Plan',
    subtitle: 'Map the wins you want by tonight to keep the day intentional.',
    placeholder: 'Capture the outcomes to secure before the day ends',
    points: 12,
    defaultDurationMinutes: 40,
  },
  todo: {
    title: 'To-Do Stack',
    subtitle: 'Quick actions that keep momentum without derailing focus.',
    placeholder: 'Log small tasks, reviews, or follow-ups',
    points: 8,
    defaultDurationMinutes: 15,
  },
}

export const initialTasks: PlanTask[] = [
  {
    id: 'hour-1',
    title: 'Deep review: Algorithms chapter 3 problem set',
    plan: 'hour',
    completed: false,
    points: PLAN_CONFIG.hour.points,
  },
  {
    id: 'day-1',
    title: 'Summarize lecture notes into spaced-repetition cards',
    plan: 'day',
    completed: false,
    points: PLAN_CONFIG.day.points,
  },
  {
    id: 'todo-1',
    title: 'Send a quick progress update to study partner',
    plan: 'todo',
    completed: false,
    points: PLAN_CONFIG.todo.points,
  },
]
