const steps = [
	{
		n: "01",
		title: "Intake call",
		body: "30 minutes with a partner. We map the role, the team, comp band, and the must-haves vs nice-to-haves.",
	},
	{
		n: "02",
		title: "Shortlist in 7 days",
		body: "You get 4–6 vetted candidates with written submissions, salary expectations, and our notes.",
	},
	{
		n: "03",
		title: "Interview & decide",
		body: "We coordinate every interview, handle scheduling and feedback, and prep candidates so nothing falls through.",
	},
	{
		n: "04",
		title: "Offer & onboard",
		body: "We negotiate, close, and stay in touch for the first 90 days. Replacement guarantee if it doesn't work.",
	},
];

export default function Process() {
	return (
		<section id="process" className="scroll-mt-20 bg-[var(--surface)]">
			<div className="mx-auto max-w-7xl px-6 py-24 md:py-32">
				<div className="max-w-2xl">
					<p className="text-sm font-medium text-[var(--brand)]">Process</p>
					<h2 className="mt-3 text-3xl font-semibold tracking-tight text-[var(--foreground)] md:text-4xl">
						From kickoff to signed offer in under 30 days
					</h2>
					<p className="mt-4 text-lg text-[var(--muted)]">
						A focused process that respects your time. No mass-mailed CVs, no ghost candidates.
					</p>
				</div>

				<div className="mt-14 grid gap-px overflow-hidden rounded-2xl border border-[var(--border)] bg-[var(--border)] md:grid-cols-4">
					{steps.map((step) => (
						<div key={step.n} className="bg-white p-8">
							<div className="text-sm font-mono font-semibold text-[var(--brand)]">{step.n}</div>
							<h3 className="mt-4 text-lg font-semibold tracking-tight">{step.title}</h3>
							<p className="mt-2 text-sm leading-relaxed text-[var(--muted)]">{step.body}</p>
						</div>
					))}
				</div>
			</div>
		</section>
	);
}
