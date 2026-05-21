const testimonials = [
	{
		quote:
			"Apex placed our Head of Engineering in 19 days. She's still here three years later and has built out a team of 22. Easily the best agency we've worked with.",
		author: "Sarah Chen",
		role: "CEO, Lumen AI",
	},
	{
		quote:
			"They actually listened to what we needed. Every shortlist was tight, every candidate prepped. Zero wasted interview slots.",
		author: "Marcus Okafor",
		role: "VP People, Fieldwise",
	},
	{
		quote:
			"We've used five agencies. Apex is the only one we still use. Honest about candidates, fast on turnaround, and they push back when our brief is off.",
		author: "Priya Raman",
		role: "Director of Talent, NorthArc",
	},
];

export default function Testimonials() {
	return (
		<section id="testimonials" className="scroll-mt-20 bg-[var(--surface)]">
			<div className="mx-auto max-w-7xl px-6 py-24 md:py-32">
				<div className="max-w-2xl">
					<p className="text-sm font-medium text-[var(--brand)]">Testimonials</p>
					<h2 className="mt-3 text-3xl font-semibold tracking-tight text-[var(--foreground)] md:text-4xl">
						What our clients say
					</h2>
				</div>

				<div className="mt-14 grid gap-6 md:grid-cols-3">
					{testimonials.map((t) => (
						<figure
							key={t.author}
							className="flex flex-col rounded-2xl border border-[var(--border)] bg-white p-8"
						>
							<svg viewBox="0 0 24 24" fill="currentColor" className="h-7 w-7 text-[var(--brand)]/30">
								<path d="M9.4 7.5a4.5 4.5 0 00-4.4 4.5v5a1 1 0 001 1h4a1 1 0 001-1v-4a1 1 0 00-1-1H8a2.5 2.5 0 012.5-2.5 1 1 0 100-2zM18.4 7.5a4.5 4.5 0 00-4.4 4.5v5a1 1 0 001 1h4a1 1 0 001-1v-4a1 1 0 00-1-1H17a2.5 2.5 0 012.5-2.5 1 1 0 100-2z" />
							</svg>
							<blockquote className="mt-4 flex-1 text-base leading-relaxed text-[var(--foreground)]">
								&ldquo;{t.quote}&rdquo;
							</blockquote>
							<figcaption className="mt-6 border-t border-[var(--border)] pt-4">
								<div className="font-semibold tracking-tight">{t.author}</div>
								<div className="text-sm text-[var(--muted)]">{t.role}</div>
							</figcaption>
						</figure>
					))}
				</div>
			</div>
		</section>
	);
}
