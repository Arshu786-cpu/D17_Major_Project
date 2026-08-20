export function Placeholder({ title, description }: { title: string; description: string }) {
  return (
    <div className="mx-auto max-w-4xl px-4 py-12 md:px-8">
      <div className="card p-10 text-center">
        <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary-600/15 text-primary-400">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </div>
        <h1 className="text-xl font-semibold text-white">{title}</h1>
        <p className="mx-auto mt-2 max-w-md text-sm text-neutral-400">{description}</p>
        <div className="mt-4 inline-flex items-center gap-2 rounded-full border border-neutral-800 bg-neutral-900 px-3 py-1 text-xs text-neutral-500">
          <span className="status-dot bg-amber-500" />
          Coming in a later phase
        </div>
      </div>
    </div>
  )
}
