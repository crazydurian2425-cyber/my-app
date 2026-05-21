export default function Hero() {
	return (
		<section className="relative overflow-hidden">
			<div className="absolute inset-0 -z-10 bg-gradient-to-b from-indigo-50/60 via-white to-white" />
			<div className="absolute -top-24 left-1/2 -z-10 h-[600px] w-[900px] -translate-x-1/2 rounded-full bg-indigo-100/40 blur-3xl" />

			<div className="mx-auto max-w-7xl px-6 pt-20 pb-24 md:pt-28 md:pb-32">
				<div className="mx-auto max-w-3xl text-center">
					<span className="inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-white px-3 py-1 text-xs font-medium text-[var(--muted)] shadow-sm">
						<span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500" />
						Now placing in 14 countries
					</span>

					<h1 className="mt-6 text-4xl font-semibold tracking-tight text-[var(--foreground)] sm:text-5xl md:text-6xl">
						Recruitment that <span className="text-[var(--brand)]">actually fits.</span>
					</h1>

					<p className="mt-6 text-lg leading-relaxed text-[var(--muted)] md:text-xl">
						We connect high-growth companies with exceptional talent across tech, finance, and product —
						with a 92% retention rate after 12 months.
					</p>

					<div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
						<a
							href="#contact"
							className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-[var(--foreground)] px-6 py-3 text-sm font-medium text-white transition hover:bg-[var(--brand)] sm:w-auto"
						>
							Hire talent
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
								<path d="M5 12h14M13 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
							</svg>
						</a>
						<a
							href="#services"
							className="inline-flex w-full items-center justify-center rounded-full border border-[var(--border)] bg-white px-6 py-3 text-sm font-medium text-[var(--foreground)] transition hover:border-[var(--foreground)] sm:w-auto"
						>
							See how we work
						</a>
					</div>

					<div className="mt-14">
						<p className="text-xs font-medium uppercase tracking-widest text-[var(--muted)]">
							Trusted by teams at
						</p>
						<div className="mt-5 flex flex-wrap items-center justify-center gap-x-10 gap-y-4 text-[var(--muted)]">
							{["Stripe", "Linear", "Notion", "Figma", "Vercel", "Ramp"].map((name) => (
								<span key={name} className="text-base font-semibold tracking-tight opacity-60">
									{name}
								</span>
							))}
						</div>
					</div>
				</div>
			</div>
		</section>
	);
}
