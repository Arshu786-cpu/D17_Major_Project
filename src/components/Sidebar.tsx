import { NavLink } from 'react-router-dom'
import { Logo } from './Logo'

interface NavItem {
  to: string
  label: string
  icon: string
  badge?: string
}

const NAV_SECTIONS: { title: string; items: NavItem[] }[] = [
  {
    title: 'Workspace',
    items: [
      { to: '/dashboard', label: 'Dashboard', icon: 'M' },
      { to: '/assistant', label: 'AI Assistant', icon: 'A' },
      { to: '/agents', label: 'Agent Center', icon: 'G' },
    ],
  },
  {
    title: 'Knowledge',
    items: [
      { to: '/knowledge', label: 'Knowledge', icon: 'K' },
      { to: '/documents', label: 'Documents', icon: 'D' },
      { to: '/search', label: 'Semantic Search', icon: 'S' },
    ],
  },
  {
    title: 'Intelligence',
    items: [
      { to: '/github', label: 'GitHub', icon: 'H' },
      { to: '/reports', label: 'Reports', icon: 'R' },
      { to: '/analytics', label: 'Analytics', icon: 'N' },
    ],
  },
  {
    title: 'System',
    items: [
      { to: '/activity', label: 'Activity', icon: 'L' },
      { to: '/settings', label: 'Settings', icon: 'E' },
      { to: '/admin', label: 'Admin', icon: 'X' },
    ],
  },
]

export function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <aside className="flex h-full w-64 flex-col border-r border-neutral-800 bg-neutral-950">
      <div className="flex h-16 items-center px-5">
        <NavLink to="/dashboard">
          <Logo size={36} />
        </NavLink>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-2">
        {NAV_SECTIONS.map((section) => (
          <div key={section.title} className="mb-4">
            <div className="mb-1 px-3 text-[10px] font-semibold uppercase tracking-widest text-neutral-600">
              {section.title}
            </div>
            {section.items.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={onNavigate}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition ${
                    isActive
                      ? 'bg-primary-600/15 text-primary-300'
                      : 'text-neutral-400 hover:bg-neutral-900 hover:text-neutral-200'
                  }`
                }
              >
                <span className="flex h-5 w-5 items-center justify-center rounded text-[10px] font-bold text-neutral-500">
                  {item.icon}
                </span>
                {item.label}
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      <div className="border-t border-neutral-800 p-3">
        <div className="rounded-lg bg-neutral-900 p-3 text-xs text-neutral-500">
          <div className="mb-1 font-medium text-neutral-400">EAIOS v0.1</div>
          Multi-agent orchestration platform
        </div>
      </div>
    </aside>
  )
}
