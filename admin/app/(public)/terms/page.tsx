import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Terms of Service | TrustCare',
  description: 'TrustCare Terms of Service - Understand your rights and responsibilities when using our platform.',
};

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-sm p-8 sm:p-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-2">Terms of Service</h1>
        <p className="text-gray-600 mb-8">Last Updated: February 2026</p>

        <div className="prose prose-gray max-w-none">
          {/* Acceptance of Terms */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. Acceptance of Terms</h2>
            <p className="text-gray-700 leading-relaxed">
              Welcome to TrustCare. By accessing or using our mobile application and services (collectively, the "Service"), 
              you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not 
              use our Service.
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              These Terms constitute a legally binding agreement between you and TrustCare. We reserve the right to update 
              these Terms at any time. Your continued use of the Service after changes are posted constitutes acceptance of 
              the updated Terms.
            </p>
          </section>

          {/* User Accounts */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. User Accounts</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              To access certain features of TrustCare, you must create an account:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Accurate Information:</strong> You agree to provide accurate, current, and complete information 
                during registration and to update such information as needed.
              </li>
              <li>
                <strong>Account Security:</strong> You are responsible for maintaining the confidentiality of your account 
                credentials and for all activities that occur under your account.
              </li>
              <li>
                <strong>One Account Per Person:</strong> Each user may maintain only one account. Creating multiple accounts 
                to manipulate ratings or circumvent restrictions is prohibited.
              </li>
              <li>
                <strong>Age Requirement:</strong> You must be at least 16 years old to use TrustCare.
              </li>
              <li>
                <strong>Account Termination:</strong> We reserve the right to suspend or terminate accounts that violate 
                these Terms or engage in fraudulent or harmful behavior.
              </li>
            </ul>
          </section>

          {/* Reviews & Content */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. Reviews & User Content</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              TrustCare enables users to share reviews and feedback about healthcare providers:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Original Content:</strong> You represent that all reviews and content you submit are your own 
                original work based on genuine personal experiences.
              </li>
              <li>
                <strong>No Fake Reviews:</strong> Posting false, misleading, or fraudulent reviews is strictly prohibited. 
                This includes reviews written by providers about themselves, competitors, or solicited reviews.
              </li>
              <li>
                <strong>Honest and Constructive:</strong> Reviews should be honest, factual, and constructive. Avoid 
                profanity, hate speech, or personal attacks.
              </li>
              <li>
                <strong>Rights Granted:</strong> By submitting content, you grant TrustCare a non-exclusive, worldwide, 
                royalty-free license to use, display, reproduce, and distribute your content in connection with the Service.
              </li>
              <li>
                <strong>Content Moderation:</strong> We reserve the right to remove or edit content that violates these 
                Terms, is inappropriate, or is flagged by our AI verification system.
              </li>
              <li>
                <strong>Your Responsibility:</strong> You are solely responsible for the content you post. We do not endorse 
                user content and are not liable for any content posted by users.
              </li>
            </ul>
          </section>

          {/* Verification */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. Verification Process</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              TrustCare uses AI and human review to maintain platform integrity:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Review Verification:</strong> You may optionally submit supporting documentation (e.g., appointment 
                receipts, prescriptions) to verify your review. Documents are used solely for authenticity verification.
              </li>
              <li>
                <strong>Authorized Access:</strong> Verification documents are reviewed only by authorized TrustCare personnel 
                and our AI systems. Documents are stored securely and deleted after 90 days.
              </li>
              <li>
                <strong>Provider Claims:</strong> Healthcare providers may claim their profiles by submitting professional 
                credentials (e.g., medical licenses). We verify credentials before granting profile access.
              </li>
              <li>
                <strong>AI Analysis:</strong> We use artificial intelligence to detect patterns suggesting fake or manipulated 
                reviews. Flagged content may be removed or hidden pending manual review.
              </li>
              <li>
                <strong>No Guarantee:</strong> While we make reasonable efforts to detect fake content, we cannot guarantee 
                that all reviews are authentic. Use your judgment when making healthcare decisions.
              </li>
            </ul>
          </section>

          {/* Provider Information */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. Provider Information</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              TrustCare aggregates healthcare provider information from various sources:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>User-Submitted Data:</strong> Much of our provider data is submitted by users or providers themselves. 
                While we strive for accuracy, we do not independently verify all information unless marked as "Verified."
              </li>
              <li>
                <strong>No Medical Advice:</strong> Provider listings, reviews, and ratings are for informational purposes only 
                and do not constitute medical advice or recommendations.
              </li>
              <li>
                <strong>Accuracy:</strong> Provider information (addresses, phone numbers, services, hours) may be outdated or 
                incorrect. Always verify critical details directly with the provider before visiting.
              </li>
              <li>
                <strong>Verified Providers:</strong> Providers with a "Verified" badge have confirmed their identity and 
                credentials through our verification process.
              </li>
              <li>
                <strong>Updates:</strong> Providers may update their profile information at any time. We are not responsible 
                for outdated or incorrect provider data.
              </li>
            </ul>
          </section>

          {/* Prohibited Conduct */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. Prohibited Conduct</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              When using TrustCare, you agree NOT to:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>Post false, misleading, defamatory, or fraudulent content</li>
              <li>Harass, threaten, or intimidate other users or healthcare providers</li>
              <li>Submit spam, advertisements, or promotional content</li>
              <li>Manipulate ratings or reviews through fake accounts or coordinated campaigns</li>
              <li>Impersonate another person or entity</li>
              <li>Scrape, crawl, or use automated tools to extract data from the Service</li>
              <li>Attempt to gain unauthorized access to our systems or other users' accounts</li>
              <li>Distribute malware, viruses, or other harmful code</li>
              <li>Violate any applicable laws or regulations</li>
              <li>Use the Service for any illegal or unauthorized purpose</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              Violation of these prohibitions may result in immediate account suspension or termination, and we may 
              report illegal activities to law enforcement.
            </p>
          </section>

          {/* Limitation of Liability */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. Limitation of Liability</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              <strong>Not Medical Advice:</strong> TrustCare is an informational platform for finding and reviewing healthcare 
              providers. We do not provide medical advice, diagnosis, or treatment. The Service is not a substitute for 
              professional medical consultation.
            </p>
            <p className="text-gray-700 leading-relaxed mb-3">
              <strong>Consult Professionals:</strong> Always consult qualified healthcare professionals for medical concerns. 
              Do not rely solely on reviews or ratings when making healthcare decisions.
            </p>
            <p className="text-gray-700 leading-relaxed mb-3">
              <strong>Service "As Is":</strong> The Service is provided "as is" and "as available" without warranties of any kind, 
              either express or implied. We do not warrant that the Service will be uninterrupted, error-free, or free of viruses.
            </p>
            <p className="text-gray-700 leading-relaxed mb-3">
              <strong>No Liability:</strong> To the fullest extent permitted by law, TrustCare and its affiliates, officers, 
              employees, and partners shall not be liable for any indirect, incidental, special, consequential, or punitive 
              damages arising from your use of the Service, including but not limited to:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>Inaccurate or incomplete provider information</li>
              <li>User-generated content including reviews and ratings</li>
              <li>Decisions made based on information from the Service</li>
              <li>Loss of data or account access</li>
              <li>Third-party actions or content</li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              <strong>Maximum Liability:</strong> In any case, our total liability to you shall not exceed the amount you paid 
              to TrustCare in the 12 months preceding the claim (if any).
            </p>
          </section>

          {/* Intellectual Property */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. Intellectual Property</h2>
            <p className="text-gray-700 leading-relaxed">
              All content, features, and functionality of the Service, including but not limited to text, graphics, logos, 
              icons, images, audio clips, and software, are the exclusive property of TrustCare or its licensors and are 
              protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, 
              sell, or reverse engineer any part of the Service without our express written permission.
            </p>
          </section>

          {/* Changes to Terms */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. Changes to Terms</h2>
            <p className="text-gray-700 leading-relaxed">
              We may revise these Terms of Service at any time. When we make material changes, we will notify you through 
              the app or by email. The "Last Updated" date at the top indicates when these Terms were last revised. Your 
              continued use of the Service after changes are posted constitutes acceptance of the updated Terms. If you do 
              not agree to the updated Terms, you must stop using the Service.
            </p>
          </section>

          {/* Governing Law */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">10. Governing Law & Disputes</h2>
            <p className="text-gray-700 leading-relaxed">
              These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict 
              of law provisions. Any disputes arising from these Terms or your use of the Service shall be resolved through 
              binding arbitration, except where prohibited by law.
            </p>
          </section>

          {/* Contact */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">11. Contact Us</h2>
            <p className="text-gray-700 leading-relaxed">
              If you have any questions or concerns about these Terms of Service, please contact us at:
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              <strong>Email:</strong>{' '}
              <a href="mailto:support@trustcare.app" className="text-blue-600 hover:underline">
                support@trustcare.app
              </a>
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              We will respond to all inquiries within 30 days.
            </p>
          </section>

          {/* Severability */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">12. Severability</h2>
            <p className="text-gray-700 leading-relaxed">
              If any provision of these Terms is found to be invalid or unenforceable by a court of competent jurisdiction, 
              the remaining provisions shall continue in full force and effect. The invalid or unenforceable provision shall 
              be replaced with a valid provision that most closely reflects the intent of the original provision.
            </p>
          </section>

          {/* Entire Agreement */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">13. Entire Agreement</h2>
            <p className="text-gray-700 leading-relaxed">
              These Terms of Service, together with our Privacy Policy, constitute the entire agreement between you and 
              TrustCare regarding your use of the Service and supersede all prior agreements and understandings, whether 
              written or oral.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
