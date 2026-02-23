import { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Privacy Policy | TrustCare',
  description: 'TrustCare Privacy Policy - Learn how we collect, use, and protect your personal information.',
};

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow-sm p-8 sm:p-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-2">Privacy Policy</h1>
        <p className="text-gray-600 mb-8">Last Updated: February 2026</p>

        <div className="prose prose-gray max-w-none">
          {/* Introduction */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Introduction</h2>
            <p className="text-gray-700 leading-relaxed">
              TrustCare ("we", "our", "us") is committed to protecting your privacy. This policy explains 
              how we collect, use, and safeguard your personal information when you use our healthcare 
              review platform and services.
            </p>
          </section>

          {/* Information We Collect */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Information We Collect</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              We collect the following types of information to provide and improve our services:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Account Information:</strong> When you create an account, we collect your name, 
                email address, and authentication information (through Apple Sign-In or other providers).
              </li>
              <li>
                <strong>Review Content:</strong> Reviews, ratings, comments, and feedback you submit about 
                healthcare providers.
              </li>
              <li>
                <strong>Verification Documents:</strong> If you claim a provider profile or verify a review, 
                we may collect supporting documentation (e.g., medical licenses, appointment receipts).
              </li>
              <li>
                <strong>Device Information:</strong> Device type, operating system, app version, and unique 
                identifiers for analytics and security purposes.
              </li>
              <li>
                <strong>Location Data:</strong> With your permission, we collect location information to show 
                nearby healthcare providers and personalize search results.
              </li>
              <li>
                <strong>Usage Data:</strong> How you interact with the app, including searches, filters, and 
                features used.
              </li>
            </ul>
          </section>

          {/* How We Use Your Information */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">How We Use Your Information</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              We use the information we collect for the following purposes:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Provide Services:</strong> Enable core functionality including provider search, reviews, 
                and AI health guidance (Rehber).
              </li>
              <li>
                <strong>Improve Services:</strong> Analyze usage patterns to enhance user experience, fix bugs, 
                and develop new features.
              </li>
              <li>
                <strong>Verify Authenticity:</strong> Use AI and human review to detect fake reviews and verify 
                provider credentials.
              </li>
              <li>
                <strong>Communicate:</strong> Send important updates about your account, reviews, and service changes.
              </li>
              <li>
                <strong>Detect Fraud:</strong> Identify and prevent abuse, spam, and manipulation of our platform.
              </li>
              <li>
                <strong>Legal Compliance:</strong> Meet legal obligations and protect our rights and the safety of our users.
              </li>
            </ul>
          </section>

          {/* Data Storage & Security */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Data Storage & Security</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              We take data security seriously and implement industry-standard measures to protect your information:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Infrastructure:</strong> We use Supabase, a secure cloud platform with encryption at rest 
                and in transit (TLS/SSL).
              </li>
              <li>
                <strong>Access Controls:</strong> Role-based access with row-level security policies ensure users 
                can only access their own data.
              </li>
              <li>
                <strong>Verification Documents:</strong> Stored in private, authenticated storage buckets with 
                restricted access limited to authorized personnel.
              </li>
              <li>
                <strong>No Data Sales:</strong> We do not sell, rent, or trade your personal information to third parties.
              </li>
              <li>
                <strong>Regular Audits:</strong> We regularly review our security practices and update them as needed.
              </li>
            </ul>
          </section>

          {/* Your Rights */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Your Rights</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              You have the following rights regarding your personal data:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Access:</strong> View all personal data we have collected about you through the app's 
                Profile → Privacy & Data section.
              </li>
              <li>
                <strong>Correction:</strong> Update or correct your account information and profile details at any time.
              </li>
              <li>
                <strong>Deletion:</strong> Request deletion of your account and associated data. You can delete 
                your account directly from the app settings.
              </li>
              <li>
                <strong>Data Portability:</strong> Export your data in a machine-readable format (JSON) through 
                the app or by contacting support.
              </li>
              <li>
                <strong>Withdraw Consent:</strong> Revoke location permissions or other consents at any time through 
                device settings or app preferences.
              </li>
            </ul>
          </section>

          {/* Data Retention */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Data Retention</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              We retain your data according to the following policies:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Active Accounts:</strong> Your account data and reviews are retained while your account exists.
              </li>
              <li>
                <strong>Deleted Accounts:</strong> When you delete your account, all personal data is permanently 
                removed within 30 days. Published reviews may be anonymized rather than deleted to maintain platform integrity.
              </li>
              <li>
                <strong>Verification Documents:</strong> Documents submitted for review verification are retained for 
                90 days after verification, then automatically deleted.
              </li>
              <li>
                <strong>Provider Claims:</strong> Documents submitted for provider profile claims are retained as long 
                as the claim is active or under review.
              </li>
              <li>
                <strong>Legal Requirements:</strong> We may retain certain data longer if required by law or to resolve disputes.
              </li>
            </ul>
          </section>

          {/* Third-Party Services */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Third-Party Services</h2>
            <p className="text-gray-700 leading-relaxed mb-3">
              We use the following trusted third-party services to operate TrustCare:
            </p>
            <ul className="list-disc pl-6 space-y-2 text-gray-700">
              <li>
                <strong>Supabase:</strong> Database hosting, authentication, and file storage. 
                <a href="https://supabase.com/privacy" className="text-blue-600 hover:underline ml-1" target="_blank" rel="noopener noreferrer">
                  View Supabase Privacy Policy
                </a>
              </li>
              <li>
                <strong>OpenAI:</strong> AI-powered review verification and health guidance (Rehber). 
                Review content may be processed to detect fake reviews. 
                <a href="https://openai.com/privacy" className="text-blue-600 hover:underline ml-1" target="_blank" rel="noopener noreferrer">
                  View OpenAI Privacy Policy
                </a>
              </li>
              <li>
                <strong>Apple:</strong> Authentication through Apple Sign-In. 
                <a href="https://www.apple.com/legal/privacy/" className="text-blue-600 hover:underline ml-1" target="_blank" rel="noopener noreferrer">
                  View Apple Privacy Policy
                </a>
              </li>
            </ul>
            <p className="text-gray-700 leading-relaxed mt-3">
              Each third-party service has its own privacy policy. We carefully select partners who maintain 
              high security and privacy standards.
            </p>
          </section>

          {/* Children's Privacy */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Children's Privacy</h2>
            <p className="text-gray-700 leading-relaxed">
              TrustCare is not intended for use by individuals under 16 years of age. We do not knowingly collect 
              personal information from children under 16. If we become aware that a child under 16 has provided us 
              with personal information, we will take steps to delete such information promptly. If you believe we 
              have collected information from a child under 16, please contact us at support@trustcare.app.
            </p>
          </section>

          {/* Changes to Privacy Policy */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Changes to This Privacy Policy</h2>
            <p className="text-gray-700 leading-relaxed">
              We may update this Privacy Policy from time to time to reflect changes in our practices or for legal, 
              operational, or regulatory reasons. When we make material changes, we will notify you through the app 
              or by email. The "Last Updated" date at the top of this policy indicates when it was last revised. 
              Your continued use of TrustCare after changes are posted constitutes your acceptance of the updated policy.
            </p>
          </section>

          {/* Contact */}
          <section className="mb-8">
            <h2 className="text-2xl font-semibold text-gray-900 mb-4">Contact Us</h2>
            <p className="text-gray-700 leading-relaxed">
              If you have any questions, concerns, or requests regarding this Privacy Policy or how we handle your 
              personal information, please contact us at:
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              <strong>Email:</strong>{' '}
              <a href="mailto:support@trustcare.app" className="text-blue-600 hover:underline">
                support@trustcare.app
              </a>
            </p>
            <p className="text-gray-700 leading-relaxed mt-3">
              We will respond to all requests within 30 days.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
