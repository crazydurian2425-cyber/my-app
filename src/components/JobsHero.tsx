export default function JobsHero() {
	return (
		<section className="relative overflow-hidden">
			<div className="absolute inset-0 -z-10 bg-gradient-to-b from-indigo-50/60 via-white to-white" />

			<div className="mx-auto max-w-7xl px-6 pt-20 pb-14 md:pt-28 md:pb-16">
				<div className="max-w-3xl">
					<span className="inline-flex items-center gap-2 rounded-full border border-[var(--border)] bg-white px-3 py-1 text-xs font-medium text-[var(--muted)] shadow-sm">
						<span className="inline-block h-1.5 w-1.5 rounded-full bg-emerald-500" />
						Updated weekly
					</span>

					<h1 className="mt-6 text-4xl font-semibold tracking-tight text-[var(--foreground)] sm:text-5xl md:text-6xl">
						Open roles we&apos;re hiring for right now.
					</h1>

					<p className="mt-6 text-lg leading-relaxed text-[var(--muted)] md:text-xl">
						A live selection of roles across our client base. Most are exclusive to Apex — you won&apos;t find them on job boards.
					</p>
				</div>
			</div>
		</section>
	);
}
