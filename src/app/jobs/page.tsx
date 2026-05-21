import type { Metadata } from "next";
import Header from "@/components/Header";
import JobsHero from "@/components/JobsHero";
import JobsList from "@/components/JobsList";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
	title: "Open roles — Apex Talent",
	description:
		"Live selection of permanent, contract, and executive roles across tech, finance, and product. Most are exclusive to Apex Talent.",
};

export default function JobsPage() {
	return (
		<main>
			<Header />
			<JobsHero />
			<JobsList />
			<Footer />
		</main>
	);
}
