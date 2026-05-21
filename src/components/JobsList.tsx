"use client";

import { useState } from "react";

type Job = {
	title: string;
	company: string;
	location: string;
	salary: string;
	type: "Permanent" | "Contract" | "Contract-to-hire";
	category: "Engineering" | "Product" | "Design" | "Data & ML" | "Executive" | "Operations" | "Marketing";
	posted: string;
	tags: string[];
};

const jobs: Job[] = [
	{
		title: "Senior Backend Engineer",
		company: "Series B fintech · payments infra",
		location: "Remote (EU)",
		salary: "£110k – £140k + equity",
		type: "Permanent",
		category: "Engineering",
		posted: "3 days ago",
		tags: ["Go", "Kubernetes", "Postgres"],
	},
	{
		title: "Head of Product",
		company: "AI platform · Series C",
		location: "London or NYC",
		salary: "$180k – $220k + equity",
		type: "Permanent",
		category: "Product",
		posted: "1 week ago",
		tags: ["B2B SaaS", "0→1", "Enterprise"],
	},
	{
		title: "Staff ML Research Scientist",
		company: "Frontier AI lab (confidential)",
		location: "SF or London",
		salary: "$300k – $420k + equity",
		type: "Permanent",
		category: "Data & ML",
		posted: "5 days ago",
		tags: ["LLMs", "Pre-training", "PhD preferred"],
	},
	{
		title: "Senior Product Designer",
		company: "Healthtech scale-up · Series B",
		location: "Remote (UK)",
		salary: "£85k – £110k",
		type: "Permanent",
		category: "Design",
		posted: "2 weeks ago",
		tags: ["Figma", "Design systems", "Mobile"],
	},
	{
		title: "VP of Engineering",
		company: "Climate hardware · Series B",
		location: "Berlin",
		salary: "€180k – €230k + equity",
		type: "Permanent",
		category: "Executive",
		posted: "4 days ago",
		tags: ["Hardware", "Scaling 20→80", "Leadership"],
	},
	{
		title: "Growth Marketing Lead",
		company: "DTC consumer brand",
		location: "London (hybrid)",
		salary: "£75k – £95k",
		type: "Permanent",
		category: "Marketing",
		posted: "6 days ago",
		tags: ["Paid social", "CRO", "Lifecycle"],
	},
	{
		title: "Senior Quant Researcher",
		company: "Systematic hedge fund",
		location: "London",
		salary: "Confidential + significant bonus",
		type: "Permanent",
		category: "Data & ML",
		posted: "1 week ago",
		tags: ["Python", "Stats", "Alpha research"],
	},
	{
		title: "Engineering Manager",
		company: "Dev tools · Series A",
		location: "Remote (global)",
		salary: "$160k – $200k + equity",
		type: "Permanent",
		category: "Engineering",
		posted: "2 days ago",
		tags: ["TypeScript", "Open source", "DX"],
	},
	{
		title: "Lead Solutions Architect",
		company: "Enterprise SaaS · pre-IPO",
		location: "NYC or Remote (US)",
		salary: "$200k – $250k",
		type: "Contract-to-hire",
		category: "Engineering",
		posted: "1 week ago",
		tags: ["AWS", "Customer-facing", "Enterprise"],
	},
	{
		title: "Chief of Staff",
		company: "Growth-stage fintech",
		location: "London",
		salary: "£130k – £160k + equity",
		type: "Permanent",
		category: "Operations",
		posted: "3 days ago",
		tags: ["Strategy", "Ops", "Reports to CEO"],
	},
];

const categories: Array<Job["category"] | "All"> = [
	"All",
	"Engineering",
	"Product",
	"Design",
	"Data & ML",
	"Executive",
	"Operations",
	"Marketing",
];

export default function JobsList() {
	const [active, setActive] = useState<(typeof categories)[number]>("All");

	const filtered = active === "All" ? jobs : jobs.filter((j) => j.category === active);

	return (
		<section className="scroll-mt-20">
			<div className="mx-auto max-w-7xl px-6 pb-24 md:pb-32">
				<div className="flex flex-wrap gap-2">
					{categories.map((cat) => {
						const count = cat === "All" ? jobs.length : jobs.filter((j) => j.category === cat).length;
						const isActive = active === cat;
						return (
							<button
								key={cat}
								type="button"
								onClick={() => setActive(cat)}
								className={
									"inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-medium transition " +
									(isActive
										? "border-[var(--foreground)] bg-[var(--foreground)] text-white"
										: "border-[var(--border)] bg-white text-[var(--muted)] hover:border-[var(--foreground)] hover:text-[var(--foreground)]")
								}
							>
								{cat}
								<span
									className={
										"rounded-full px-1.5 py-0.5 text-xs " +
										(isActive ? "bg-white/20 text-white" : "bg-[var(--surface)] text-[var(--muted)]")
									}
								>
									{count}
								</span>
							</button>
						);
					})}
				</div>

				<div className="mt-10 space-y-4">
					{filtered.length === 0 ? (
						<div className="rounded-2xl border border-dashed border-[var(--border)] bg-white p-12 text-center">
							<p className="text-[var(--muted)]">No open roles in this category right now.</p>
							<a
								href="/#contact"
								className="mt-4 inline-flex text-sm font-medium text-[var(--brand)] hover:underline"
							>
								Tell us what you&apos;re looking for →
							</a>
						</div>
					) : (
						filtered.map((job) => (
							<article
								key={job.title}
								className="group rounded-2xl border border-[var(--border)] bg-white p-6 transition hover:border-[var(--foreground)] hover:shadow-md md:p-8"
							>
								<div className="flex flex-col gap-6 md:flex-row md:items-start md:justify-between">
									<div className="min-w-0 flex-1">
										<div className="flex flex-wrap items-center gap-2">
											<span className="rounded-full bg-indigo-50 px-2.5 py-1 text-xs font-medium text-[var(--brand)]">
												{job.category}
											</span>
											<span className="rounded-full border border-[var(--border)] px-2.5 py-1 text-xs font-medium text-[var(--muted)]">
												{job.type}
											</span>
											<span className="text-xs text-[var(--muted)]">· {job.posted}</span>
										</div>

										<h3 className="mt-3 text-xl font-semibold tracking-tight text-[var(--foreground)]">
											{job.title}
										</h3>
										<p className="mt-1 text-sm text-[var(--muted)]">{job.company}</p>

										<div className="mt-4 flex flex-wrap items-center gap-x-5 gap-y-2 text-sm text-[var(--muted)]">
											<span className="inline-flex items-center gap-1.5">
												<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
													<path d="M12 22s-8-7.58-8-13a8 8 0 0116 0c0 5.42-8 13-8 13z" strokeLinecap="round" strokeLinejoin="round" />
													<circle cx="12" cy="9" r="3" />
												</svg>
												{job.location}
											</span>
											<span className="inline-flex items-center gap-1.5">
												<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
													<path d="M12 1v22M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6" strokeLinecap="round" strokeLinejoin="round" />
												</svg>
												{job.salary}
											</span>
										</div>

										<div className="mt-4 flex flex-wrap gap-1.5">
											{job.tags.map((tag) => (
												<span
													key={tag}
													className="rounded-md bg-[var(--surface)] px-2 py-1 text-xs text-[var(--muted)]"
												>
													{tag}
												</span>
											))}
										</div>
									</div>

									<div className="flex shrink-0 items-center gap-2">
										<a
											href="/#contact"
											className="inline-flex items-center justify-center gap-2 rounded-full bg-[var(--foreground)] px-5 py-2.5 text-sm font-medium text-white transition hover:bg-[var(--brand)]"
										>
											Apply
											<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
												<path d="M5 12h14M13 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
											</svg>
										</a>
									</div>
								</div>
							</article>
						))
					)}
				</div>

				<div className="mt-16 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-8 text-center md:p-12">
					<h3 className="text-2xl font-semibold tracking-tight">Don&apos;t see the right role?</h3>
					<p className="mt-3 text-[var(--muted)]">
						We place dozens of off-market roles every quarter. Send us your CV and we&apos;ll be in touch when something fits.
					</p>
					<a
						href="/#contact"
						className="mt-6 inline-flex items-center gap-2 rounded-full bg-[var(--foreground)] px-6 py-3 text-sm font-medium text-white transition hover:bg-[var(--brand)]"
					>
						Submit your CV
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
							<path d="M5 12h14M13 5l7 7-7 7" strokeLinecap="round" strokeLinejoin="round" />
						</svg>
					</a>
				</div>
			</div>
		</section>
	);
}
