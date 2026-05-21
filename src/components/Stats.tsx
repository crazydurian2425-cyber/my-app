const stats = [
	{ value: "92%", label: "12-month retention rate" },
	{ value: "21 days", label: "Average time-to-hire" },
	{ value: "1,400+", label: "Placements made" },
	{ value: "14", label: "Countries served" },
];

export default function Stats() {
	return (
		<section className="border-y border-[var(--border)] bg-[var(--surface)]">
			<div className="mx-auto max-w-7xl px-6 py-16 md:py-20">
				<div className="grid grid-cols-2 gap-8 md:grid-cols-4">
					{stats.map((stat) => (
						<div key={stat.label} className="text-center">
							<div className="text-4xl font-semibold tracking-tight text-[var(--foreground)] md:text-5xl">
								{stat.value}
							</div>
							<div className="mt-2 text-sm text-[var(--muted)]">{stat.label}</div>
						</div>
					))}
				</div>
			</div>
		</section>
	);
}
