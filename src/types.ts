export type PlanType = 'hour' | 'day' | 'todo'

export type ThemeMode = 'dark' | 'light'

export interface PlanDefinition {
  title: string
  subtitle: string
  placeholder: string
  points: number
  defaultDurationMinutes: number
}

export interface PlanTask {
  id: string
  title: string
  plan: PlanType
  completed: boolean
  points: number
}
