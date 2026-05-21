const industries = [
	{ name: "SaaS & Tech", roles: "Engineering, Product, Design" },
	{ name: "Fintech", roles: "Quant, Risk, Compliance" },
	{ name: "AI & ML", roles: "Research, MLOps, Applied AI" },
	{ name: "Healthcare", roles: "Clinical Tech, Data, Ops" },
	{ name: "E-commerce", roles: "Growth, Performance, CX" },
	{ name: "Climate & Energy", roles: "Hardware, Policy, GTM" },
];

export default function Industries() {
	return (
		<section id="industries" className="scroll-mt-20">
			<div className="mx-auto max-w-7xl px-6 py-24 md:py-32">
				<div className="flex flex-col items-start justify-between gap-6 md:flex-row md:items-end">
					<div className="max-w-2xl">
						<p className="text-sm font-medium text-[var(--brand)]">Industries</p>
						<h2 className="mt-3 text-3xl font-semibold tracking-tight text-[var(--foreground)] md:text-4xl">
							Where we have depth
						</h2>
					</div>
					<p className="max-w-md text-[var(--muted)]">
						We don&apos;t pretend to know every sector. We focus where our network is strongest.
					</p>
				</div>

				<div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
					{industries.map((industry) => (
						<div
							key={industry.name}
							className="flex items-center justify-between rounded-xl border border-[var(--border)] bg-white p-6 transition hover:border-[var(--foreground)]"
						>
							<div>
								<div className="font-semibold tracking-tight">{industry.name}</div>
								<div className="mt-1 text-sm text-[var(--muted)]">{industry.roles}</div>
							</div>
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 text-[var(--muted)]">
								<path d="M5 12h14M13 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
							</svg>
						</div>
					))}
				</div>
			</div>
		</section>
	);
}
