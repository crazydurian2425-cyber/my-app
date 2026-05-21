export default function Footer() {
	return (
		<footer className="border-t border-[var(--border)] bg-white">
			<div className="mx-auto max-w-7xl px-6 py-14">
				<div className="grid gap-10 md:grid-cols-4">
					<div className="md:col-span-2">
						<a href="#" className="flex items-center gap-2 text-lg font-semibold tracking-tight">
							<span className="inline-flex h-8 w-8 items-center justify-center rounded-lg bg-[var(--brand)] text-white">
								<svg viewBox="0 0 24 24" fill="none" className="h-5 w-5" stroke="currentColor" strokeWidth="2.5">
									<path d="M4 18L12 6L20 18" strokeLinecap="round" strokeLinejoin="round" />
								</svg>
							</span>
							Apex Talent
						</a>
						<p className="mt-4 max-w-sm text-sm text-[var(--muted)]">
							Connecting high-growth companies with exceptional talent. Permanent, contract, and executive search.
						</p>
					</div>

					<div>
						<h4 className="text-sm font-semibold tracking-tight">Company</h4>
						<ul className="mt-4 space-y-2 text-sm text-[var(--muted)]">
							<li><a href="/#services" className="hover:text-[var(--foreground)]">Services</a></li>
							<li><a href="/#process" className="hover:text-[var(--foreground)]">Process</a></li>
							<li><a href="/jobs" className="hover:text-[var(--foreground)]">Open roles</a></li>
							<li><a href="/#industries" className="hover:text-[var(--foreground)]">Industries</a></li>
							<li><a href="/#testimonials" className="hover:text-[var(--foreground)]">Testimonials</a></li>
						</ul>
					</div>

					<div>
						<h4 className="text-sm font-semibold tracking-tight">Get in touch</h4>
						<ul className="mt-4 space-y-2 text-sm text-[var(--muted)]">
							<li>hello@apextalent.com</li>
							<li>+44 20 7946 0000</li>
							<li>London · Singapore · NYC</li>
						</ul>
					</div>
				</div>

				<div className="mt-12 flex flex-col items-start justify-between gap-4 border-t border-[var(--border)] pt-6 text-xs text-[var(--muted)] sm:flex-row sm:items-center">
					<p>&copy; {new Date().getFullYear()} Apex Talent Ltd. All rights reserved.</p>
					<div className="flex gap-6">
						<a href="#" className="hover:text-[var(--foreground)]">Privacy</a>
						<a href="#" className="hover:text-[var(--foreground)]">Terms</a>
						<a href="#" className="hover:text-[var(--foreground)]">Cookies</a>
					</div>
				</div>
			</div>
		</footer>
	);
}
