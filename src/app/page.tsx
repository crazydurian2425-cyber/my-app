import Header from "@/components/Header";
import Hero from "@/components/Hero";
import Stats from "@/components/Stats";
import Services from "@/components/Services";
import Process from "@/components/Process";
import Industries from "@/components/Industries";
import Testimonials from "@/components/Testimonials";
import ContactCTA from "@/components/ContactCTA";
import Footer from "@/components/Footer";

export default function Home() {
	return (
		<main>
			<Header />
			<Hero />
			<Stats />
			<Services />
			<Process />
			<Industries />
			<Testimonials />
			<ContactCTA />
			<Footer />
		</main>
	);
}
