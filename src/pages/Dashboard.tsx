import { Link } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { LogoMark } from '../components/Logo'

const AGENTS = [
  { key: 'knowledge', name: 'Knowledge & RAG', desc: 'Semantic retrieval and permission-aware Q&A', color: 'text-primary-400', status: 'Ready' },
  { key: 'document', name: 'Document Intelligence', desc: 'Parse, analyze, compare, and summarize documents', color: 'text-accent-400', status: 'Ready' },
  { key: 'github', name: 'GitHub Intelligence', desc: 'Repository analysis and code understanding', color: 'text-amber-400', status: 'Ready' },
  { key: 'report', name: 'Report Generation', desc: 'Professional AI-powered reports with sources', color: 'text-sky-400', status: 'Ready' },
  { key: 'analytics', name: 'Analytics & Workflow', desc: 'Usage insights and workflow automation', color: 'text-violet-400', status: 'Ready' },
]

export function Dashboard() {
  const { profile, user } = useAuth()
  const firstName = profile?.full_name?.split(' ')[0] || 'there'

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 md:px-8 md:py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-2 text-sm text-neutral-500">
          <span className="status-dot bg-accent-500" />
          System operational
        </div>
        <h1 className="mt-2 text-2xl font-bold text-white md:text-3xl">
          Welcome back, {firstName}
        </h1>
        <p className="mt-1 text-sm text-neutral-400">
          Your enterprise AI operating system is ready. Ask the Main Agent anything, or explore a specialist agent below.
        </p>
      </div>

      {/* Main Agent hero */}
      <div className="card relative mb-8 overflow-hidden p-6 md:p-8">
        <div className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-primary-600/10 blur-3xl" />
        <div className="relative flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="flex items-start gap-4">
            <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-primary-600/15 text-primary-400">
              <LogoMark size={48} />
            </div>
            <div>
              <div className="text-xs font-semibold uppercase tracking-widest text-primary-400">Main Agent</div>
              <h2 className="mt-1 text-xl font-semibold text-white">AI Orchestrator</h2>
              <p className="mt-1 max-w-lg text-sm text-neutral-400">
                The central intelligence of EAIOS. It routes your request, coordinates specialist agents, verifies results, and returns a single grounded answer.
              </p>
            </div>
          </div>
          <Link to="/assistant" className="btn-primary shrink-0">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
            Open AI Assistant
          </Link>
        </div>
      </div>

      {/* Specialist agents */}
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-semibold uppercase tracking-widest text-neutral-500">Specialist Agents</h3>
        <Link to="/agents" className="text-sm text-primary-400 hover:text-primary-300">
          View Agent Center →
        </Link>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {AGENTS.map((agent) => (
          <Link
            key={agent.key}
            to="/agents"
            className="card group p-5 transition hover:border-neutral-700 hover:bg-neutral-900"
          >
            <div className="flex items-start justify-between">
              <div className={`flex h-10 w-10 items-center justify-center rounded-lg bg-neutral-800 ${agent.color}`}>
                <span className="text-sm font-bold">{agent.name[0]}</span>
              </div>
              <span className="flex items-center gap-1.5 text-xs text-neutral-500">
                <span className="status-dot bg-accent-500" />
                {agent.status}
              </span>
            </div>
            <h4 className="mt-3 font-semibold text-neutral-100 group-hover:text-white">{agent.name}</h4>
            <p className="mt-1 text-sm text-neutral-400">{agent.desc}</p>
          </Link>
        ))}
      </div>

      {/* Quick stats */}
      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: 'Documents', value: '—', hint: 'Knowledge base' },
          { label: 'Conversations', value: '—', hint: 'AI sessions' },
          { label: 'GitHub Repos', value: '—', hint: 'Connected' },
          { label: 'Reports', value: '—', hint: 'Generated' },
        ].map((stat) => (
          <div key={stat.label} className="card p-5">
            <div className="text-sm text-neutral-500">{stat.label}</div>
            <div className="mt-2 text-2xl font-bold text-white">{stat.value}</div>
            <div className="mt-1 text-xs text-neutral-600">{stat.hint}</div>
          </div>
        ))}
      </div>

      <div className="mt-8 text-xs text-neutral-600">
        Signed in as {user?.email} · Role: {profile?.role ?? 'employee'}
        {profile?.org_id ? '' : ' · Not assigned to an organization yet'}
      </div>
    </div>
  )
}
