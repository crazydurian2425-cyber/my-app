export default function Header() {
	return (
		<header className="sticky top-0 z-50 border-b border-[var(--border)] bg-white/80 backdrop-blur-md">
			<div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
				<a href="/" className="flex items-center gap-2 text-lg font-semibold tracking-tight">
					<span className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-[var(--brand)] text-white">
						<svg viewBox="0 0 24 24" fill="none" className="h-5 w-5" stroke="currentColor" strokeWidth="2.5">
							<path d="M4 18L12 6L20 18" strokeLinecap="round" strokeLinejoin="round" />
						</svg>
					</span>
					Apex Talent
				</a>

				<nav className="hidden items-center gap-8 text-sm text-[var(--muted)] md:flex">
					<a href="/#services" className="transition hover:text-[var(--foreground)]">Services</a>
					<a href="/#process" className="transition hover:text-[var(--foreground)]">Process</a>
					<a href="/jobs" className="transition hover:text-[var(--foreground)]">Open roles</a>
					<a href="/#industries" className="transition hover:text-[var(--foreground)]">Industries</a>
					<a href="/#testimonials" className="transition hover:text-[var(--foreground)]">Testimonials</a>
				</nav>

				<div className="flex items-center gap-3">
					<a href="/#contact" className="hidden text-sm font-medium text-[var(--foreground)] hover:text-[var(--brand)] md:block">
						Talk to us
					</a>
					<a
						href="/#contact"
						className="rounded-full bg-[var(--foreground)] px-4 py-2 text-sm font-medium text-white transition hover:bg-[var(--brand)]"
					>
						Hire talent
					</a>
				</div>
			</div>
		</header>
	);
}
