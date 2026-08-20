export type UserRole = 'admin' | 'manager' | 'employee'

export type DocStatus = 'processing' | 'available' | 'failed'
export type DocVisibility = 'private' | 'org' | 'shared'
export type ExecutionStatus = 'running' | 'success' | 'failed'
export type ReportFormat = 'pdf' | 'docx' | 'markdown'

export interface Organization {
  id: string
  name: string
  slug: string
  created_at: string
}

export interface Profile {
  id: string
  org_id: string | null
  role: UserRole
  full_name: string | null
  created_at: string
}

export interface DocumentRow {
  id: string
  org_id: string
  owner_id: string
  title: string
  type: string
  storage_path: string
  status: DocStatus
  visibility: DocVisibility
  created_at: string
  updated_at: string
}

export interface DocumentChunk {
  id: string
  doc_id: string
  content: string
  chunk_index: number
  metadata: Record<string, unknown>
  created_at: string
}

export interface Conversation {
  id: string
  org_id: string
  user_id: string
  title: string
  created_at: string
}

export interface Message {
  id: string
  conversation_id: string
  role: string
  content: string
  agent: string | null
  sources: unknown[]
  created_at: string
}

export interface GitHubRepo {
  id: string
  org_id: string
  owner_id: string
  repo_owner: string
  repo_name: string
  token_ref: string | null
  last_synced_at: string | null
  created_at: string
}

export interface Report {
  id: string
  org_id: string
  owner_id: string
  type: string
  title: string
  format: ReportFormat
  storage_path: string | null
  created_at: string
}

export interface AgentExecution {
  id: string
  execution_id: string
  org_id: string
  user_id: string
  main_agent_status: ExecutionStatus
  specialist_agent: string | null
  tools_used: string[]
  status: ExecutionStatus
  duration_ms: number | null
  source_count: number | null
  created_at: string
}

export interface AuditLog {
  id: string
  org_id: string | null
  user_id: string | null
  action: string
  resource: string | null
  ip: string | null
  created_at: string
}

export interface AnalyticsEvent {
  id: string
  org_id: string
  user_id: string
  event_type: string
  payload: Record<string, unknown>
  created_at: string
}

export interface SearchLog {
  id: string
  org_id: string
  user_id: string
  query: string
  result_count: number
  created_at: string
}
