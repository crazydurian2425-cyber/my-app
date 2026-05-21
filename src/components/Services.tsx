const services = [
	{
		title: "Permanent placement",
		description:
			"Full-time hires for engineering, product, and operations roles. Replacement guarantee if a candidate leaves within 90 days.",
		icon: (
			<path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2M22 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75M9 7a4 4 0 100 8 4 4 0 000-8z" strokeLinecap="round" strokeLinejoin="round" />
		),
	},
	{
		title: "Contract & contract-to-hire",
		description:
			"On-demand specialists for 3–12 month engagements. We handle compliance, payroll, and onboarding.",
		icon: (
			<path d="M12 8v8m-4-4h8M21 12a9 9 0 11-18 0 9 9 0 0118 0z" strokeLinecap="round" strokeLinejoin="round" />
		),
	},
	{
		title: "Executive search",
		description:
			"Discreet, retained search for VP, C-suite, and board roles. Deep network across high-growth scale-ups.",
		icon: (
			<path d="M11 19a8 8 0 100-16 8 8 0 000 16zM21 21l-4.35-4.35" strokeLinecap="round" strokeLinejoin="round" />
		),
	},
];

export default function Services() {
	return (
		<section id="services" className="scroll-mt-20">
			<div className="mx-auto max-w-7xl px-6 py-24 md:py-32">
				<div className="max-w-2xl">
					<p className="text-sm font-medium text-[var(--brand)]">Services</p>
					<h2 className="mt-3 text-3xl font-semibold tracking-tight text-[var(--foreground)] md:text-4xl">
						Three ways we place talent
					</h2>
					<p className="mt-4 text-lg text-[var(--muted)]">
						Whether you need a single senior hire or a full team — we&apos;ve got a model for it.
					</p>
				</div>

				<div className="mt-14 grid gap-6 md:grid-cols-3">
					{services.map((service) => (
						<div
							key={service.title}
							className="group rounded-2xl border border-[var(--border)] bg-white p-8 transition hover:border-[var(--foreground)] hover:shadow-lg"
						>
							<div className="inline-flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-50 text-[var(--brand)] transition group-hover:bg-[var(--brand)] group-hover:text-white">
								<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-6 w-6">
									{service.icon}
								</svg>
							</div>
							<h3 className="mt-6 text-xl font-semibold tracking-tight">{service.title}</h3>
							<p className="mt-3 text-[var(--muted)] leading-relaxed">{service.description}</p>
						</div>
					))}
				</div>
			</div>
		</section>
	);
}
