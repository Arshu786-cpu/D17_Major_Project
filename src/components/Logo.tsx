export function LogoMark({ size = 40 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
      <g stroke="currentColor" strokeWidth="2" strokeLinecap="round" opacity="0.6">
        <path d="M32 18 L32 32" />
        <path d="M32 32 L44 24" />
        <path d="M32 32 L44 40" />
        <path d="M32 32 L20 40" />
        <path d="M32 32 L20 24" />
        <path d="M32 32 L32 46" />
      </g>
      <circle cx="32" cy="32" r="7" fill="currentColor" />
      <circle cx="32" cy="18" r="3" fill="currentColor" opacity="0.7" />
      <circle cx="44" cy="24" r="3" fill="currentColor" opacity="0.7" />
      <circle cx="44" cy="40" r="3" fill="currentColor" opacity="0.7" />
      <circle cx="32" cy="46" r="3" fill="currentColor" opacity="0.7" />
      <circle cx="20" cy="40" r="3" fill="currentColor" opacity="0.7" />
      <circle cx="20" cy="24" r="3" fill="currentColor" opacity="0.7" />
    </svg>
  )
}

export function Logo({ size = 40, withText = true }: { size?: number; withText?: boolean }) {
  return (
    <div className="flex items-center gap-3">
      <span className="text-primary-500">
        <LogoMark size={size} />
      </span>
      {withText && (
        <div className="leading-tight">
          <div className="text-lg font-bold tracking-tight text-neutral-900 dark:text-white">EAIOS</div>
          <div className="text-[10px] font-medium uppercase tracking-widest text-neutral-500">Enterprise AI OS</div>
        </div>
      )}
    </div>
  )
}
