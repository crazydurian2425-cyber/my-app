export default function ContactCTA() {
	return (
		<section id="contact" className="scroll-mt-20">
			<div className="mx-auto max-w-7xl px-6 py-24 md:py-32">
				<div className="overflow-hidden rounded-3xl bg-[var(--foreground)] px-8 py-16 md:px-16 md:py-20">
					<div className="grid gap-12 lg:grid-cols-2 lg:gap-16">
						<div className="text-white">
							<p className="text-sm font-medium text-indigo-300">Let&apos;s talk</p>
							<h2 className="mt-3 text-3xl font-semibold tracking-tight md:text-4xl">
								Ready to make your next hire?
							</h2>
							<p className="mt-4 text-lg text-white/70">
								Tell us about the role. We&apos;ll come back within one business day with a quick read on
								feasibility, timeline, and salary band.
							</p>

							<div className="mt-10 space-y-4 text-white/80">
								<div className="flex items-center gap-3">
									<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 text-indigo-300">
										<path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z" />
										<polyline points="22,6 12,13 2,6" />
									</svg>
									<span>hello@apextalent.com</span>
								</div>
								<div className="flex items-center gap-3">
									<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 text-indigo-300">
										<path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.13.96.37 1.9.72 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.91.35 1.85.59 2.81.72A2 2 0 0122 16.92z" />
									</svg>
									<span>+44 20 7946 0000</span>
								</div>
							</div>
						</div>

						<form className="rounded-2xl bg-white p-6 md:p-8">
							<div className="space-y-4">
								<div className="grid gap-4 sm:grid-cols-2">
									<label className="block">
										<span className="text-sm font-medium">Full name</span>
										<input
											type="text"
											required
											className="mt-1.5 w-full rounded-lg border border-[var(--border)] px-3 py-2.5 text-sm outline-none transition focus:border-[var(--brand)] focus:ring-2 focus:ring-indigo-100"
											placeholder="Jane Doe"
										/>
									</label>
									<label className="block">
										<span className="text-sm font-medium">Company</span>
										<input
											type="text"
											required
											className="mt-1.5 w-full rounded-lg border border-[var(--border)] px-3 py-2.5 text-sm outline-none transition focus:border-[var(--brand)] focus:ring-2 focus:ring-indigo-100"
											placeholder="Acme Inc."
										/>
									</label>
								</div>
								<label className="block">
									<span className="text-sm font-medium">Work email</span>
									<input
										type="email"
										required
										className="mt-1.5 w-full rounded-lg border border-[var(--border)] px-3 py-2.5 text-sm outline-none transition focus:border-[var(--brand)] focus:ring-2 focus:ring-indigo-100"
										placeholder="jane@company.com"
									/>
								</label>
								<label className="block">
									<span className="text-sm font-medium">Role you&apos;re hiring for</span>
									<select
										required
										defaultValue=""
										className="mt-1.5 w-full rounded-lg border border-[var(--border)] bg-white px-3 py-2.5 text-sm outline-none transition focus:border-[var(--brand)] focus:ring-2 focus:ring-indigo-100"
									>
										<option value="" disabled>Select…</option>
										<option>Engineering</option>
										<option>Product</option>
										<option>Design</option>
										<option>Data / ML</option>
										<option>Executive (VP, C-suite)</option>
										<option>Other</option>
									</select>
								</label>
								<label className="block">
									<span className="text-sm font-medium">Tell us a bit more</span>
									<textarea
										rows={3}
										className="mt-1.5 w-full resize-none rounded-lg border border-[var(--border)] px-3 py-2.5 text-sm outline-none transition focus:border-[var(--brand)] focus:ring-2 focus:ring-indigo-100"
										placeholder="Seniority, location, timeline…"
									/>
								</label>
								<button
									type="submit"
									className="w-full rounded-full bg-[var(--brand)] px-6 py-3 text-sm font-medium text-white transition hover:bg-[var(--brand-dark)]"
								>
									Send brief
								</button>
								<p className="text-center text-xs text-[var(--muted)]">
									We reply within 1 business day. No spam, ever.
								</p>
							</div>
						</form>
					</div>
				</div>
			</div>
		</section>
	);
}
