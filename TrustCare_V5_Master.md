# TrustCare — V5 Master Specification
## Complete Product Map & Software Architecture
### Incorporating All Requirements, Phased Feature Roadmap, and Production Architecture

---

## PART A: REQUIREMENTS SUMMARY

### Confirmed Decisions

| Decision | Answer |
|----------|--------|
| Provider data source | User-submitted (crowdsourced) + providers can "claim" profiles (Google Maps model) |
| Review verification | AI-powered auto-verification from Day 1 |
| Timeline | Ship-ready in a few weeks |
| Monetization | Free for users. Revenue from: provider subscriptions, provider ads, marketplace commissions (V2) |
| Geographic scope | Multi-country from start |
| Languages | English (primary/default), German, Dutch, Polish, Turkish, Arabic at launch |
| Admin dashboard | Web-based admin panel required from Day 1 |
| V1 scope | Everything specified unless explicitly deferred |

### Feature Phasing

**V1 — MVP Launch (Ship in weeks)**
- Full iOS app: onboarding, auth, search/discovery, provider detail, review submission, profile
- Crowdsourced price indicator on reviews ($/$$/$$$/$$$$)
- Product/service catalog with prices (for claimed/paying providers)
- Provider claim flow (request to claim a profile)
- Provider subscription tiers (Free, Basic, Premium)
- AI-powered review verification via Edge Function
- Multi-language support (6 languages)
- Multi-country phone auth
- Web-based admin panel (review moderation, provider claims, user management)

**V2 — Post-Launch Growth**
- AI Health Chat assistant (helps users find the right specialty/provider)
- Sales campaigns & promotional codes for providers
- Referral code system (provider-to-patient, patient-to-patient)
- Health packages marketplace (standard commission)
- Health insurance marketplace (standard commission)
- Provider ads system (featured listings, banner ads)

**V3 — Platform Expansion**
- In-app appointment booking with calendar integration
- Contact forms / direct messaging to providers
- Provider dashboard (web portal for claimed providers to manage their profile)
- Video reviews
- Community forums

---

## PART B: TECH STACK (Locked)

| Layer | Choice | Rationale |
|-------|--------|-----------|
| iOS App | SwiftUI, iOS 17.0+ | NavigationStack, PhotosPicker, Charts native |
| Architecture | MVVM | Standard for SwiftUI, no unnecessary complexity |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions + Realtime) | All-in-one BaaS, Swift SDK, generous free tier |
| Maps | Apple MapKit | Native, free, no API key |
| Image Loading | SDWebImageSwiftUI 3.x | Async loading + disk/memory cache |
| AI Verification | Supabase Edge Function + OpenAI Vision API | Day 1 auto-verification |
| AI Chat (V2) | Anthropic Claude API via Edge Function | Health guidance chatbot |
| Admin Panel | Next.js + Supabase Auth + Tailwind CSS | Fast to build, shares same Supabase backend |
| Localization | Apple String Catalogs (.xcstrings) | Native iOS 17 localization system |
| Analytics | PostHog (self-hostable, GDPR-friendly) | Multi-country compliance |

### Swift Package Manager Dependencies
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "3.0.0"),
]
```

> Only 2 dependencies. SwiftUI provides ProgressView, PhotosPicker, Charts, and NavigationStack natively. Localization uses native String Catalogs.

### Supabase CLI — Local Development & Deployment

The project uses the Supabase CLI for database management, Edge Function deployment, and local development. This replaces manual use of the Supabase Dashboard for all development tasks.

**Prerequisites:**
- Docker Desktop (Supabase CLI runs PostgreSQL, Auth, Storage, etc. in Docker containers)
- Supabase CLI: `brew install supabase/tap/supabase`

**Project structure (supabase/ directory):**
```
supabase/
├── config.toml              ← Local config + storage bucket definitions
├── migrations/
│   ├── 00001_schema.sql     ← Full schema (22 tables, indexes, triggers, RLS)
│   └── 00002_verification_webhook.sql  ← pg_net trigger for AI verification
├── seed.sql                 ← Specialties, sample providers, feature flags
└── functions/
    ├── verify-review/index.ts        ← AI verification Edge Function
    └── export-user-data/index.ts     ← GDPR data export Edge Function
```

**Development workflow:**
```bash
supabase start                        # Start local Supabase stack (Postgres, Auth, Storage, etc.)
supabase db reset                     # Wipe local DB + re-apply migrations + seed
supabase functions serve              # Hot-reload Edge Functions locally
# → Local dashboard at http://localhost:54323
# → Local API at http://127.0.0.1:54321
```

**Production deployment:**
```bash
supabase link --project-ref <ref-id>  # Link to remote project (one-time)
supabase db push                      # Push migrations to remote
supabase functions deploy verify-review
supabase functions deploy export-user-data
supabase secrets set OPENAI_API_KEY=sk-...
```

**Supabase keys management:**
- Keys stored in `Config/Supabase.xcconfig` (git-ignored, never committed)
- Reads into app via `Config/SupabaseConfig.swift` → `Bundle.main.infoDictionary` → xcconfig
- Development: local URL + local anon key from `supabase status`
- Production: remote project URL + remote anon key from Supabase Dashboard → Settings → API

**Steps that still require the Supabase web Dashboard:**
1. Creating the cloud project (one-time)
2. Enabling Apple OAuth provider (Authentication → Providers → Apple)
3. Upgrading to paid plan before launch
4. Configuring custom SMTP for emails (optional)

---

## PART C: DESIGN SYSTEM

### C.1 Color Palette
```swift
import SwiftUI

enum AppColor {
    // Primary
    static let trustBlue = Color(hex: "#0055FF")
    static let trustBlueLight = Color(hex: "#4D88FF")
    static let trustBlueDark = Color(hex: "#0044CC")

    // Backgrounds (adaptive light/dark)
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let border = Color(.separator)

    // Semantic
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")

    // Verification Status
    static let verified = Color(hex: "#34C759")
    static let pending = Color(hex: "#FF9500")
    static let unverified = Color(.secondaryLabel)

    // Ratings
    static let starFilled = Color(hex: "#FFCC00")
    static let starEmpty = Color(.systemGray5)

    // Price Level
    static let priceActive = Color(hex: "#34C759")   // active $ signs
    static let priceInactive = Color(.systemGray4)    // inactive $ signs

    // Ads / Premium
    static let premiumGold = Color(hex: "#FFD700")
    static let featuredBorder = Color(hex: "#0055FF").opacity(0.3)
}
```

### C.2 Typography
```swift
enum AppFont {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1     = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2     = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3     = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline   = Font.system(size: 17, weight: .semibold)
    static let body       = Font.system(size: 17, weight: .regular)
    static let callout    = Font.system(size: 16, weight: .regular)
    static let caption    = Font.system(size: 15, weight: .regular)
    static let footnote   = Font.system(size: 13, weight: .regular)
}
```

### C.3 Component Tokens
| Token | Value |
|-------|-------|
| Corner Radius (standard) | 12 |
| Corner Radius (cards) | 16 |
| Corner Radius (buttons) | 12 |
| Shadow | color: .black.opacity(0.08), radius: 8, y: 2 |
| Standard padding | 16 |
| Spacing scale | 4, 8, 12, 16, 20, 24, 32 |
| Animation duration | 0.25s |
| Min tap target | 44×44 |
| Price indicator | $ symbols (1-4), priceActive/priceInactive colors |

---

## PART D: COMPLETE SCREEN ARCHITECTURE

### D.1 Navigation Flow
```
App Launch
  → SplashView (2s, check auth session)
  → OnboardingView (3-page carousel, shown once per install)
  → AuthView (Login / Sign Up — email, Apple, phone)
  → MainTabView
       ├── Tab 1: HomeView (Search & Discovery)
       │     ├── ProviderDetailView
       │     │     ├── ServicesCatalogView (prices for claimed providers)
       │     │     ├── ReviewListView (full list)
       │     │     └── ClaimProviderView (for unclaimed profiles)
       │     └── ProviderMapView
       ├── Tab 2: SubmitReviewView (Multi-step form with price indicator)
       │     └── ReviewConfirmationView
       ├── Tab 3: ProfileView
       │     ├── MyReviewsView
       │     └── SettingsView (includes language picker)
       │
       ├── [V2] Tab 4: AI Health Chat
       └── [V3] AppointmentBookingView (from ProviderDetail)
```

### D.2 Screen-by-Screen Specifications

---

#### A1. SplashView
- Background: `LinearGradient(colors: [trustBlue, trustBlueLight])`
- Center: App icon (SF Symbol `cross.case.fill`, 80pt, white)
- "TrustCare" (title1, white)
- "Healthcare, Verified." (body, white.opacity(0.9))
- Auto-navigate after 2s: check `Supabase.auth.session`
  - Valid session → MainTabView
  - No session + first launch → OnboardingView
  - No session + returning → AuthView

#### A2. OnboardingView (3-Page Carousel)
- `TabView` with `.tabViewStyle(.page)`
- Page 1: Icon `stethoscope` | "Find Trusted Care" | "Discover verified doctors based on real patient experiences"
- Page 2: Icon `checkmark.shield.fill` | "Verified Reviews" | "Upload visit proof for AI-verified trusted recommendations"
- Page 3: Icon `person.3.fill` | "Help Others" | "Your reviews guide others to better healthcare"
- "Next" button: trustBlue, full width, height 50, cornerRadius 12
- "Skip" text button: caption, trustBlue, top-right
- Page indicator dots at bottom
- `@AppStorage("hasSeenOnboarding")` — show only once

#### A3. AuthView
**Login Mode:**
- Logo (60×60)
- "Welcome Back" (title2)
- Email TextField (SF icon: `envelope`, keyboard: `.emailAddress`, autocapitalization: `.never`)
- Password SecureField (SF icon: `lock`)
- "Log In" button (trustBlue, full width)
- Divider with "OR"
- "Continue with Apple" (SignInWithAppleButton, black)
- "Continue with Phone" button (outlined) → PhoneAuthSheet
- "Don't have an account? Sign Up" link

**Sign Up Mode:**
- Same as login plus: Full Name TextField
- Country picker (flag + name, affects phone format)
- "I agree to Terms & Privacy" toggle
- "Create Account" button

**Phone Auth Sheet:**
- Country code picker (auto-detect from locale)
- Phone number TextField
- "Send Code" → OTP input (6 digits)
- Verify button

**Validation:** Real-time red borders + error caption. Buttons disabled until valid.

---

#### B1. HomeView (Tab 1 — "Find")
- **Tab icon:** `house.fill`
- **Header:** "Good [Morning/Afternoon], [Name]!" (title3) + current city with pin icon (caption)
- **Search Bar:** TextField with magnifyingglass, 44pt, cardBackground, cornerRadius 12. Debounce 300ms.
- **Specialty Chips (horizontal ScrollView):**
  `["All", "Dentist", "Cardiologist", "Dermatologist", "Pediatrician", "General", "Orthopedic", "Gynecologist", "Psychiatrist", "ENT", "Ophthalmologist"]`
  - Selected: trustBlue fill, white text
  - Unselected: cardBackground, primary text, border
- **Filter Chips (second row, horizontal ScrollView):**
  `["Near Me", "Highest Rated", "Verified Only", "$ Budget", "$$ Mid", "$$$ Premium"]`
- **View Toggle:** Segmented Picker: "List" | "Map"
- **List Mode:**
  - `LazyVStack` of `ProviderCardView`
  - Pull-to-refresh (`.refreshable`)
  - Infinite scroll pagination
  - Featured/promoted providers shown with subtle `featuredBorder` and small "Sponsored" label (footnote, secondary)
- **Map Mode:**
  - `Map` with `Annotation` markers for each provider
  - Tap marker → bottom sheet with ProviderCardView → tap → ProviderDetailView
  - Cluster annotations when zoomed out
- **Empty State:** Illustration + "No providers found" + "Try a different search or add a provider"
- **Loading:** `ProgressView` centered

#### B2. ProviderCardView (Reusable Component)
```
┌───────────────────────────────────────────┐
│  ┌──────┐                                 │
│  │ Photo│  Dr. Jane Smith            →    │
│  │ 64×64│  Cardiologist • Heart Center    │
│  │circle│  ★★★★★ 4.8 (120 reviews)       │
│  └──────┘  ✓ 95% Verified  ·  $$$        │
│            1.2 km away                    │
│            [Sponsored]  ← only if ad      │
└───────────────────────────────────────────┘
```
- Card: cardBackground, cornerRadius 16, shadow
- Photo: `WebImage(url:)` via SDWebImageSwiftUI, placeholder: `person.crop.circle.fill`
- Name: headline, primary
- Specialty + Clinic: caption, secondary
- Rating: starFilled, body
- Verified badge: success, `checkmark.seal.fill`
- **Price Level:** `PriceLevelView` — shows $$$ with 3 active, 1 inactive (crowdsourced average)
- Distance: footnote, secondary
- "Sponsored" label: only for ad-boosted providers, footnote, secondary, italic
- Tap → `NavigationLink` to `ProviderDetailView`
- If provider `is_claimed` and has subscription: subtle verified business checkmark near name

#### B3. ProviderDetailView
**Hero Section:**
- Cover image (250pt, AsyncImage, blurhash placeholder) — or gradient if no cover
- Profile photo (100×100, circle, white border, overlapping bottom of cover)
- Back button (top-left), Share button (top-right)
- If unclaimed: "Is this your practice? Claim it" banner (trustBlue, tappable)

**Info Section:**
- Name (title1) + claimed badge (if claimed: blue checkmark)
- Specialty (body, secondary)
- Clinic name (if present, caption)
- **Rating Row:** `★ 4.8` · `120 Reviews` · `95% Verified` (caption chips)
- **Price Level:** `$$$ · Mid-Range` (crowdsourced from reviews)
- Address (tappable → Apple Maps)
- Phone (tappable → `tel://`)
- Website (tappable → SFSafariViewController)
- Languages spoken (if provided by claimed provider)

**Quick Actions (HStack):**
- "Call" (trustBlue, `phone.fill`)
- "Directions" (outlined, `map.fill`)
- [V3] "Book" (success, `calendar`)
- [V3] "Message" (outlined, `envelope.fill`)

**Statistics Grid (LazyVGrid 2×2):**
- Wait Time: X.X/5 (`clock` icon)
- Bedside Manner: X.X/5 (`heart` icon)
- Treatment: X.X/5 (`cross.case` icon)
- Cleanliness: X.X/5 (`sparkles` icon)

**Services & Prices Section (only for claimed providers with active subscription):**
- Section header: "Services & Prices" + "View All" link
- List of `ServiceItemView`:
  ```
  ┌─────────────────────────────────────┐
  │ General Consultation        €50-80  │
  │ Dental Cleaning            €80-120  │
  │ Root Canal                €200-400  │
  │ ...                                 │
  └─────────────────────────────────────┘
  ```
- Each item: service name (body) + price range (headline, trustBlue)
- "View All Services" → `ServicesCatalogView` (full scrollable list)
- If not claimed: section absent

**Reviews Section:**
- Header: "Reviews" (title3) + Sort picker (Recent, Highest, Lowest, Most Helpful)
- First 5 reviews as `ReviewItemView`
- "See All Reviews" button if > 5
- "Write a Review" button (trustBlue, full width) → SubmitReviewView with provider pre-selected

#### B4. ReviewItemView (Reusable Component)
```
┌───────────────────────────────────────┐
│ [Avatar] John D. · ✓ Verified        │
│ ★★★★☆  ·  Jan 15, 2026  ·  $$$      │
│ "Great doctor, very thorough..."      │
│ 👍 12 helpful                         │
└───────────────────────────────────────┘
```
- Verified badge if `is_verified == true` (success, `checkmark.seal.fill`)
- Pending badge if proof uploaded but not yet verified (warning)
- **Price level indicator** shown on each review
- Expandable text (3-line limit, "Read more" toggle)
- Helpful button (thumb up + count)
- Report button (flag icon, footnote)

#### B5. ClaimProviderView (Sheet/Modal)
- Triggered from "Claim this profile" banner on unclaimed provider detail
- Title: "Claim This Practice" (title2)
- Form fields:
  - Your role: Picker ["Owner", "Manager", "Authorized Representative"]
  - Business email (must match clinic domain ideally)
  - Phone number
  - License/registration number (optional, helps fast-track)
  - Upload proof: business registration, medical license, utility bill
- "Submit Claim" button
- Note: "Claims are reviewed within 48 hours."
- Logic: inserts into `provider_claims` table with status `pending`

#### B6. ServicesCatalogView
- Full list of services for a claimed provider
- Grouped by category (e.g., "Consultations", "Procedures", "Diagnostic")
- Each item: name, description (optional), price or price range, duration (optional)
- If provider has active Premium subscription: full catalog visible
- If Basic: limited to 10 services
- Contact CTA at bottom: "Interested? Call or book an appointment."

---

#### C1. SubmitReviewView (Tab 2 — "Review")
- **Tab icon:** `plus.circle.fill`
- Multi-step form. Progress bar at top (Step X of 6).
- Back/Next buttons at bottom. Next disabled until step valid.

**Step 1 — Find Provider:**
- "Who are you reviewing?" (title2)
- Search bar (same style as HomeView)
- Results list (compact ProviderCardView)
- "Can't find them? Add a new provider" link → AddProviderSheet
- Selected provider shown as confirmed card with ✓

**Step 1b — Add Provider (Sheet, if not found):**
- Provider/Doctor name (required)
- Specialty picker (required)
- Clinic/Hospital name (optional)
- Address (required, with autocomplete if possible)
- Phone (optional)
- "Submit" → creates provider row with `is_claimed = false`

**Step 2 — Visit Details:**
- Date picker: "When was your visit?" (default: today, max: today)
- Visit type picker: Consultation, Procedure, Checkup, Emergency

**Step 3 — Ratings:**
- For each criterion, a custom `RatingSliderView` (1–10 scale):
  1. Waiting Time (`clock` icon)
  2. Bedside Manner (`heart` icon)
  3. Treatment Efficacy (`cross.case` icon)
  4. Facility Cleanliness (`sparkles` icon)
- Each shows: "Poor" ← slider → "Excellent", value/10, star equivalent (value/2)

**Step 4 — Price Level:**
- "How expensive was your visit?" (title3)
- **4-option selector (tap to select):**
  - `$` — Budget-friendly
  - `$$` — Moderate
  - `$$$` — Above average
  - `$$$$` — Premium/Expensive
- Each option is a large tappable card with the $ symbols and a one-line description
- Selected card: trustBlue border + fill, white text
- This is crowdsourced — shown as average on provider cards

**Step 5 — Written Review:**
- Title TextField (optional, max 100 chars)
- Comment TextEditor (min 50, max 1000 chars)
- Character counter: "52 / 1000" (turns error color if < 50)
- "Would you recommend?" Yes/No toggle

**Step 6 — Verification Upload:**
- "Verify Your Visit" (title2)
- "Upload proof: receipt, prescription, or appointment confirmation." (body)
- PhotosPicker button (camera/gallery)
- Selected image preview (thumbnail, removable ×)
- Privacy note: "Only visible to our AI verification system and moderators." (footnote)
- "Skip Verification" text button → review marked as unverified
- **Note:** Uploaded proof triggers AI verification Edge Function automatically

**Confirmation (after submit):**
- Checkmark animation (`checkmark.circle.fill`, success, scale)
- "Review Submitted!" (title1)
- Status: "AI Verification in Progress" (pending) or "Review Published" (if no proof)
- "Back to Home" button

---

#### D1. ProfileView (Tab 3 — "Profile")
- **Tab icon:** `person.circle.fill`
- **Header:** Avatar (80×80, editable via PhotosPicker), Name (title2), member since (caption)
- **Stats Row (HStack):** Reviews count | Verified % | Helpful votes given
- **Menu List:**
  - My Reviews → MyReviewsView
  - Settings → SettingsView
  - Help & Support → mailto or web link
  - Privacy Policy → SFSafariViewController
  - Terms of Service → SFSafariViewController
  - Log Out → confirmation → sign out

#### D2. MyReviewsView
- Segmented filter: All | Verified | Pending | Unverified
- List of reviews: provider name, date, rating, price level, status badge
- Swipe to delete (confirmation alert)
- Empty state: "No reviews yet. Share your first experience!"

#### D3. SettingsView
- **Account:** Email (read-only), Phone, Change Password
- **Language:** Picker with flag + name:
  - 🇬🇧 English (default)
  - 🇩🇪 Deutsch
  - 🇳🇱 Nederlands
  - 🇵🇱 Polski
  - 🇹🇷 Türkçe
  - 🇸🇦 العربية
  - Changing language: sets `@AppStorage("appLanguage")` + updates Supabase profile
  - For Arabic: RTL layout support
- **Country/Region:** Picker (affects currency symbol for price display)
- **Preferences:** Theme (System/Light/Dark), Notifications toggle
- **About:** Version, Terms, Privacy Policy
- **Danger Zone:** Delete Account (double confirmation → Supabase delete)

---

#### [V2] E1. AI Health Chat (Tab 4 — "Ask AI")
- **Tab icon:** `bubble.left.and.text.bubble.right.fill`
- **Purpose:** User describes symptoms/concerns → AI suggests which specialty to seek, what to expect, and optionally recommends high-rated providers from the database
- **UI:**
  - Chat interface: message bubbles (user = right/trustBlue, AI = left/cardBackground)
  - Text input bar at bottom with send button
  - Typing indicator while AI responds
  - Disclaimer banner at top: "This is not medical advice. Always consult a healthcare professional."
- **Backend:** Supabase Edge Function → Anthropic Claude API
  - System prompt enforces medical safety guardrails
  - Can query providers table to suggest nearby options
  - Never diagnoses — only suggests specialties and general guidance
- **Conversation starters (chips above input on empty state):**
  - "I have a persistent headache"
  - "My child has a fever"
  - "I need a dental checkup"
  - "Recommend a cardiologist near me"

#### [V2] E2. Campaign & Referral System
- **Provider Campaigns:**
  - Claimed providers can purchase promotional campaigns from admin panel
  - Campaign types: "Featured Listing" (appears at top of search), "Promoted Card" (subtle border + "Sponsored" label)
  - Duration-based (7/14/30 days)
  - Stored in `provider_campaigns` table
- **Referral Codes:**
  - Provider-generated: "SMITH20" → patients who use this code get highlighted as referred
  - Patient-generated: share app with unique code → both get gamification points
  - Stored in `referral_codes` table

#### [V3] F1. Appointment Booking & Contact
- **Book Appointment button** on ProviderDetailView (only for claimed providers with booking enabled)
- **BookingRequestView (Sheet):**
  - Date picker (available dates from provider calendar)
  - Time slot picker
  - Reason for visit (text field)
  - Insurance info (optional)
  - "Request Appointment" → inserts into `appointments` table
  - Provider notified via email/push
  - Status tracking: Requested → Confirmed → Completed → Cancelled
- **Contact Form (alternative for providers without booking):**
  - Name, email, phone, message
  - "Send" → inserts into `contact_requests`
  - Provider notified
- **Contact Info display:** Always visible — phone, email, website, address with map

---

### D.3 Admin Panel (Web — Next.js)

> Required from Day 1. Shares the same Supabase backend as the iOS app.

**Tech:** Next.js 14 (App Router) + Supabase Auth (email/password) + Tailwind CSS + shadcn/ui

**Screens:**

1. **Dashboard (Home)**
   - Key metrics cards: Total Users, Total Reviews, Pending Verifications, Pending Claims, Active Providers
   - Charts: Reviews per day (last 30 days), New users per week
   - Recent activity feed

2. **Review Moderation**
   - Table: Review ID, Provider, User, Rating, Status, Proof Image, Created Date
   - Filters: Pending Verification, Flagged, All
   - Actions per row: View proof image, Verify (mark verified), Reject, Flag
   - Bulk actions: Verify selected, Reject selected
   - AI verification result shown (confidence score + reason)

3. **Provider Management**
   - Table: Provider Name, Specialty, Rating, Reviews, Claimed?, Status
   - Filters: Active, Inactive, Claimed, Unclaimed
   - Actions: Edit, Deactivate, View Details
   - Add Provider manually

4. **Provider Claims**
   - Table: Claim ID, Provider, Claimant, Role, Status, Submitted Date
   - Actions: View proof documents, Approve Claim, Reject Claim
   - On approve: sets `providers.is_claimed = true`, creates `provider_subscriptions` entry

5. **User Management**
   - Table: User ID, Name, Email, Reviews Count, Verification Score, Status
   - Actions: View profile, Suspend, Ban, Delete
   - View user's reviews

6. **Subscriptions & Revenue** (V2 expansion)
   - Active subscriptions list
   - Revenue overview
   - Campaign management

7. **Settings**
   - Admin user management (invite/remove admins)
   - App configuration (feature flags)
   - Localization management

**Auth:** Only users with `role = 'admin'` in `user_roles` table can access. Login page with email/password, redirects to dashboard.

---

## PART E: COMPLETE BACKEND ARCHITECTURE (Supabase)

### E.1 Database Schema — Full SQL

```sql
-- ================================================================
-- TrustCare V5 — Complete Database Schema
-- Multi-country, multi-language, monetization-ready
-- ================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================================
-- TABLE: profiles
-- ================================================================
CREATE TABLE profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    full_name TEXT,
    avatar_url TEXT,
    phone TEXT,
    country_code TEXT DEFAULT 'GB',          -- ISO 3166-1 alpha-2
    preferred_language TEXT DEFAULT 'en',     -- en, de, nl, pl, tr, ar
    preferred_currency TEXT DEFAULT 'EUR',    -- EUR, GBP, PLN, TRY, etc.
    referral_code TEXT UNIQUE,               -- auto-generated unique code
    referred_by TEXT,                         -- referral code used at signup
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, avatar_url, referral_code)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        -- Generate unique referral code: first 4 chars of UUID + random 4 digits
        UPPER(SUBSTRING(NEW.id::TEXT FROM 1 FOR 4)) || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ================================================================
-- TABLE: user_roles
-- ================================================================
CREATE TABLE user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'moderator', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, role)
);

-- Helper: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE user_id = auth.uid() AND role IN ('admin', 'moderator')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ================================================================
-- TABLE: specialties
-- ================================================================
CREATE TABLE specialties (
    id SERIAL PRIMARY KEY,
    name_key TEXT UNIQUE NOT NULL,    -- localization key: "specialty.dentist"
    name_en TEXT NOT NULL,            -- English fallback
    name_de TEXT,
    name_nl TEXT,
    name_pl TEXT,
    name_tr TEXT,
    name_ar TEXT,
    icon_name TEXT NOT NULL,          -- SF Symbol name
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

-- ================================================================
-- TABLE: providers
-- ================================================================
CREATE TABLE providers (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    clinic_name TEXT,
    address TEXT NOT NULL,
    city TEXT,
    country_code TEXT DEFAULT 'GB',       -- ISO 3166-1 alpha-2
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    phone TEXT,
    email TEXT,
    website TEXT,
    photo_url TEXT,
    cover_url TEXT,

    -- Languages spoken by provider
    languages_spoken TEXT[] DEFAULT '{English}',

    -- Aggregated ratings (maintained by trigger)
    rating_overall NUMERIC(3,2) DEFAULT 0.00,
    rating_wait_time NUMERIC(3,2) DEFAULT 0.00,
    rating_bedside NUMERIC(3,2) DEFAULT 0.00,
    rating_efficacy NUMERIC(3,2) DEFAULT 0.00,
    rating_cleanliness NUMERIC(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    verified_review_count INTEGER DEFAULT 0,

    -- Crowdsourced price level (1-4, avg from reviews)
    price_level_avg NUMERIC(2,1) DEFAULT 0.0,

    -- Claim & subscription status
    is_claimed BOOLEAN DEFAULT FALSE,
    claimed_by UUID REFERENCES auth.users(id),
    claimed_at TIMESTAMPTZ,
    subscription_tier TEXT DEFAULT 'free'
        CHECK (subscription_tier IN ('free', 'basic', 'premium')),

    -- Visibility
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,       -- admin can feature
    created_by UUID REFERENCES auth.users(id),  -- who added this provider

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_coords CHECK (
        latitude BETWEEN -90 AND 90 AND
        longitude BETWEEN -180 AND 180
    ),
    CONSTRAINT valid_ratings CHECK (rating_overall BETWEEN 0 AND 5)
);

-- ================================================================
-- TABLE: provider_claims
-- ================================================================
CREATE TABLE provider_claims (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    claimant_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    claimant_role TEXT NOT NULL CHECK (claimant_role IN ('owner', 'manager', 'representative')),
    business_email TEXT NOT NULL,
    phone TEXT,
    license_number TEXT,
    proof_document_url TEXT,           -- uploaded business registration/license
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- TABLE: provider_subscriptions
-- ================================================================
CREATE TABLE provider_subscriptions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tier TEXT NOT NULL CHECK (tier IN ('basic', 'premium')),
    status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'cancelled', 'expired', 'trial')),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    auto_renew BOOLEAN DEFAULT TRUE,
    -- Payment tracking (external payment processor reference)
    payment_provider TEXT,             -- 'stripe', 'apple_iap', etc.
    payment_reference TEXT,
    monthly_price_cents INTEGER,       -- price in smallest currency unit
    currency TEXT DEFAULT 'EUR',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- TABLE: provider_services (product/service catalog)
-- ================================================================
CREATE TABLE provider_services (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    category TEXT,                      -- "Consultations", "Procedures", "Diagnostic"
    name TEXT NOT NULL,
    description TEXT,
    price_min NUMERIC(10,2),           -- minimum price
    price_max NUMERIC(10,2),           -- maximum price (NULL if fixed price)
    currency TEXT DEFAULT 'EUR',
    duration_minutes INTEGER,          -- estimated duration
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- TABLE: reviews
-- ================================================================
CREATE TABLE reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,

    -- Visit details
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    visit_type TEXT NOT NULL DEFAULT 'consultation'
        CHECK (visit_type IN ('consultation', 'procedure', 'checkup', 'emergency')),

    -- Individual ratings (1-5 scale)
    rating_wait_time INTEGER NOT NULL CHECK (rating_wait_time BETWEEN 1 AND 5),
    rating_bedside INTEGER NOT NULL CHECK (rating_bedside BETWEEN 1 AND 5),
    rating_efficacy INTEGER NOT NULL CHECK (rating_efficacy BETWEEN 1 AND 5),
    rating_cleanliness INTEGER NOT NULL CHECK (rating_cleanliness BETWEEN 1 AND 5),

    -- Computed by trigger
    rating_overall NUMERIC(2,1) NOT NULL CHECK (rating_overall BETWEEN 1.0 AND 5.0),

    -- Price level (crowdsourced)
    price_level INTEGER NOT NULL CHECK (price_level BETWEEN 1 AND 4),
    -- 1 = $, 2 = $$, 3 = $$$, 4 = $$$$

    -- Review content
    title TEXT,
    comment TEXT NOT NULL CHECK (length(comment) >= 50 AND length(comment) <= 1000),
    would_recommend BOOLEAN DEFAULT TRUE,

    -- Verification
    proof_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verification_confidence INTEGER,    -- AI confidence score 0-100
    verification_reason TEXT,           -- AI explanation
    verified_at TIMESTAMPTZ,

    -- Status
    status TEXT DEFAULT 'active'
        CHECK (status IN ('active', 'pending_verification', 'flagged', 'removed')),

    -- Metadata
    helpful_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One review per provider per day per user
    UNIQUE(user_id, provider_id, visit_date)
);

-- ================================================================
-- TABLE: review_votes
-- ================================================================
CREATE TABLE review_votes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    is_helpful BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(review_id, user_id)
);

-- ================================================================
-- TABLE: reported_reviews
-- ================================================================
CREATE TABLE reported_reviews (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    review_id UUID NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL CHECK (reason IN ('inaccurate', 'offensive', 'spam', 'other')),
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(review_id, reporter_id)
);

-- ================================================================
-- [V2] TABLE: provider_campaigns (ads & promotions)
-- ================================================================
CREATE TABLE provider_campaigns (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    campaign_type TEXT NOT NULL
        CHECK (campaign_type IN ('featured_listing', 'promoted_card', 'banner_ad')),
    title TEXT,
    description TEXT,
    budget_cents INTEGER,              -- total budget in smallest currency unit
    spent_cents INTEGER DEFAULT 0,
    currency TEXT DEFAULT 'EUR',
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'pending'
        CHECK (status IN ('pending', 'active', 'paused', 'completed', 'cancelled')),
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- [V2] TABLE: referral_codes
-- ================================================================
CREATE TABLE referral_codes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    owner_type TEXT NOT NULL CHECK (owner_type IN ('provider', 'user')),
    owner_provider_id UUID REFERENCES providers(id) ON DELETE CASCADE,
    owner_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    description TEXT,                  -- "20% off first visit"
    usage_count INTEGER DEFAULT 0,
    max_uses INTEGER,                  -- NULL = unlimited
    is_active BOOLEAN DEFAULT TRUE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Must belong to either a provider or user
    CONSTRAINT owner_check CHECK (
        (owner_type = 'provider' AND owner_provider_id IS NOT NULL) OR
        (owner_type = 'user' AND owner_user_id IS NOT NULL)
    )
);

-- ================================================================
-- [V3] TABLE: appointments
-- ================================================================
CREATE TABLE appointments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    requested_date DATE NOT NULL,
    requested_time TIME,
    reason TEXT,
    insurance_info TEXT,
    status TEXT DEFAULT 'requested'
        CHECK (status IN ('requested', 'confirmed', 'cancelled_by_user',
                          'cancelled_by_provider', 'completed', 'no_show')),
    provider_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- [V3] TABLE: contact_requests
-- ================================================================
CREATE TABLE contact_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    provider_id UUID NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- [V2] TABLE: ai_chat_sessions (for AI Health Chat)
-- ================================================================
CREATE TABLE ai_chat_sessions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT,                         -- auto-generated summary
    messages JSONB DEFAULT '[]'::JSONB, -- full conversation history
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### E.2 Indexes

```sql
-- Providers
CREATE INDEX idx_providers_specialty ON providers(specialty);
CREATE INDEX idx_providers_rating ON providers(rating_overall DESC);
CREATE INDEX idx_providers_active ON providers(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_providers_lat_lng ON providers(latitude, longitude);
CREATE INDEX idx_providers_country ON providers(country_code);
CREATE INDEX idx_providers_claimed ON providers(is_claimed);
CREATE INDEX idx_providers_featured ON providers(is_featured) WHERE is_featured = TRUE;

-- Reviews
CREATE INDEX idx_reviews_provider ON reviews(provider_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_created ON reviews(created_at DESC);
CREATE INDEX idx_reviews_verified ON reviews(provider_id) WHERE is_verified = TRUE;
CREATE INDEX idx_reviews_pending ON reviews(status) WHERE status = 'pending_verification';

-- Supporting tables
CREATE INDEX idx_review_votes_review ON review_votes(review_id);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_provider_claims_status ON provider_claims(status);
CREATE INDEX idx_provider_services_provider ON provider_services(provider_id);
CREATE INDEX idx_provider_campaigns_active ON provider_campaigns(status, starts_at, ends_at)
    WHERE status = 'active';
CREATE INDEX idx_referral_codes_code ON referral_codes(code) WHERE is_active = TRUE;
CREATE INDEX idx_appointments_provider ON appointments(provider_id, requested_date);
CREATE INDEX idx_appointments_user ON appointments(user_id);
CREATE INDEX idx_chat_sessions_user ON ai_chat_sessions(user_id);
```

### E.3 Triggers

```sql
-- ================================================================
-- TRIGGER: Compute review rating_overall + set status
-- ================================================================
CREATE OR REPLACE FUNCTION compute_review_overall()
RETURNS TRIGGER AS $$
BEGIN
    -- Average of 4 criteria
    NEW.rating_overall := ROUND(
        (NEW.rating_wait_time + NEW.rating_bedside +
         NEW.rating_efficacy + NEW.rating_cleanliness) / 4.0, 1
    );

    -- Set status based on proof upload (only on INSERT)
    IF TG_OP = 'INSERT' THEN
        IF NEW.proof_image_url IS NOT NULL AND NEW.proof_image_url != '' THEN
            NEW.status := 'pending_verification';
        ELSE
            NEW.status := 'active';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_compute_review_overall
BEFORE INSERT OR UPDATE ON reviews
FOR EACH ROW EXECUTE FUNCTION compute_review_overall();

-- ================================================================
-- TRIGGER: Update provider aggregates (ratings + price level)
-- ================================================================
CREATE OR REPLACE FUNCTION update_provider_aggregates()
RETURNS TRIGGER AS $$
DECLARE
    target_id UUID;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_id := OLD.provider_id;
    ELSE
        target_id := NEW.provider_id;
    END IF;

    -- Also update if provider changed (edge case: review moved)
    IF TG_OP = 'UPDATE' AND OLD.provider_id != NEW.provider_id THEN
        -- Update old provider too
        PERFORM update_single_provider_aggregates(OLD.provider_id);
    END IF;

    PERFORM update_single_provider_aggregates(target_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_single_provider_aggregates(target_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE providers SET
        rating_overall = COALESCE(sub.avg_overall, 0),
        rating_wait_time = COALESCE(sub.avg_wait, 0),
        rating_bedside = COALESCE(sub.avg_bedside, 0),
        rating_efficacy = COALESCE(sub.avg_efficacy, 0),
        rating_cleanliness = COALESCE(sub.avg_clean, 0),
        review_count = COALESCE(sub.total, 0),
        verified_review_count = COALESCE(sub.verified, 0),
        price_level_avg = COALESCE(sub.avg_price, 0),
        updated_at = NOW()
    FROM (
        SELECT
            AVG(rating_overall)::NUMERIC(3,2) AS avg_overall,
            AVG(rating_wait_time)::NUMERIC(3,2) AS avg_wait,
            AVG(rating_bedside)::NUMERIC(3,2) AS avg_bedside,
            AVG(rating_efficacy)::NUMERIC(3,2) AS avg_efficacy,
            AVG(rating_cleanliness)::NUMERIC(3,2) AS avg_clean,
            AVG(price_level)::NUMERIC(2,1) AS avg_price,
            COUNT(*) AS total,
            COUNT(*) FILTER (WHERE is_verified = TRUE) AS verified
        FROM reviews
        WHERE provider_id = target_id
          AND status IN ('active', 'pending_verification')
    ) sub
    WHERE providers.id = target_id;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_provider_aggregates
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW EXECUTE FUNCTION update_provider_aggregates();

-- ================================================================
-- TRIGGER: Auto-update updated_at
-- ================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_providers_updated_at BEFORE UPDATE ON providers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_subscriptions_updated_at BEFORE UPDATE ON provider_subscriptions
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER set_services_updated_at BEFORE UPDATE ON provider_services
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### E.4 Row Level Security

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;

-- ---- PROFILES ----
CREATE POLICY "profiles_select" ON profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON profiles FOR UPDATE USING (auth.uid() = id);

-- ---- PROVIDERS ----
CREATE POLICY "providers_select" ON providers FOR SELECT USING (is_active = TRUE);
CREATE POLICY "providers_insert" ON providers FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
-- Anyone logged in can add a provider (crowdsourced)
CREATE POLICY "providers_admin" ON providers FOR ALL USING (is_admin());
-- Claimed owners can update their own provider
CREATE POLICY "providers_owner_update" ON providers FOR UPDATE
    USING (claimed_by = auth.uid() AND is_claimed = TRUE);

-- ---- SPECIALTIES ----
CREATE POLICY "specialties_select" ON specialties FOR SELECT USING (true);

-- ---- REVIEWS ----
CREATE POLICY "reviews_select" ON reviews FOR SELECT
    USING (status IN ('active', 'pending_verification') OR user_id = auth.uid());
CREATE POLICY "reviews_insert" ON reviews FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews_update_own" ON reviews FOR UPDATE
    USING (auth.uid() = user_id);
CREATE POLICY "reviews_delete_own" ON reviews FOR DELETE
    USING (auth.uid() = user_id);
CREATE POLICY "reviews_admin" ON reviews FOR ALL USING (is_admin());

-- ---- REVIEW VOTES ----
CREATE POLICY "votes_select" ON review_votes FOR SELECT USING (true);
CREATE POLICY "votes_insert" ON review_votes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "votes_update" ON review_votes FOR UPDATE USING (auth.uid() = user_id);

-- ---- REPORTED REVIEWS ----
CREATE POLICY "reports_insert" ON reported_reviews FOR INSERT
    WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "reports_admin" ON reported_reviews FOR ALL USING (is_admin());

-- ---- USER ROLES ----
CREATE POLICY "roles_self_read" ON user_roles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "roles_admin" ON user_roles FOR ALL USING (is_admin());

-- ---- PROVIDER CLAIMS ----
CREATE POLICY "claims_insert" ON provider_claims FOR INSERT
    WITH CHECK (auth.uid() = claimant_user_id);
CREATE POLICY "claims_own_select" ON provider_claims FOR SELECT
    USING (auth.uid() = claimant_user_id);
CREATE POLICY "claims_admin" ON provider_claims FOR ALL USING (is_admin());

-- ---- PROVIDER SUBSCRIPTIONS ----
CREATE POLICY "subscriptions_own" ON provider_subscriptions FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "subscriptions_admin" ON provider_subscriptions FOR ALL USING (is_admin());

-- ---- PROVIDER SERVICES ----
CREATE POLICY "services_select" ON provider_services FOR SELECT USING (true);
-- Claimed owners can manage their services
CREATE POLICY "services_owner" ON provider_services FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM providers
            WHERE providers.id = provider_services.provider_id
            AND providers.claimed_by = auth.uid()
        )
    );
CREATE POLICY "services_admin" ON provider_services FOR ALL USING (is_admin());

-- ---- CAMPAIGNS (V2) ----
CREATE POLICY "campaigns_select_active" ON provider_campaigns FOR SELECT
    USING (status = 'active');
CREATE POLICY "campaigns_admin" ON provider_campaigns FOR ALL USING (is_admin());

-- ---- REFERRAL CODES (V2) ----
CREATE POLICY "referrals_select_active" ON referral_codes FOR SELECT
    USING (is_active = TRUE);
CREATE POLICY "referrals_own" ON referral_codes FOR ALL
    USING (owner_user_id = auth.uid());
CREATE POLICY "referrals_admin" ON referral_codes FOR ALL USING (is_admin());

-- ---- APPOINTMENTS (V3) ----
CREATE POLICY "appointments_own_user" ON appointments FOR ALL
    USING (auth.uid() = user_id);
CREATE POLICY "appointments_provider_owner" ON appointments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM providers
            WHERE providers.id = appointments.provider_id
            AND providers.claimed_by = auth.uid()
        )
    );
CREATE POLICY "appointments_admin" ON appointments FOR ALL USING (is_admin());

-- ---- CONTACT REQUESTS (V3) ----
CREATE POLICY "contact_insert" ON contact_requests FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "contact_admin" ON contact_requests FOR ALL USING (is_admin());

-- ---- AI CHAT SESSIONS (V2) ----
CREATE POLICY "chat_own" ON ai_chat_sessions FOR ALL
    USING (auth.uid() = user_id);
```

### E.5 Storage Buckets

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('verification-proofs', 'verification-proofs', false, 10485760,
     ARRAY['image/jpeg', 'image/png', 'image/heic']),
    ('avatars', 'avatars', true, 5242880,
     ARRAY['image/jpeg', 'image/png']),
    ('provider-photos', 'provider-photos', true, 10485760,
     ARRAY['image/jpeg', 'image/png']),
    ('claim-documents', 'claim-documents', false, 10485760,
     ARRAY['image/jpeg', 'image/png', 'application/pdf']);

-- Verification proofs: user uploads own, only owner + admins read
CREATE POLICY "proof_upload" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'verification-proofs' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "proof_read" ON storage.objects FOR SELECT
    USING (bucket_id = 'verification-proofs' AND
           (auth.uid()::text = (storage.foldername(name))[1] OR is_admin()));

-- Avatars: user uploads own, public read
CREATE POLICY "avatar_upload" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "avatar_read" ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

-- Provider photos: public read, admin + claimed owner upload
CREATE POLICY "provider_photo_read" ON storage.objects FOR SELECT
    USING (bucket_id = 'provider-photos');
CREATE POLICY "provider_photo_admin" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'provider-photos' AND is_admin());

-- Claim documents: claimant uploads, only admin reads
CREATE POLICY "claim_doc_upload" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'claim-documents' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "claim_doc_read" ON storage.objects FOR SELECT
    USING (bucket_id = 'claim-documents' AND is_admin());
```

### E.6 Seed Data

```sql
-- Specialties (with multi-language names)
INSERT INTO specialties (name_key, name_en, name_de, name_nl, name_pl, name_tr, name_ar, icon_name, display_order) VALUES
    ('general', 'General Practice', 'Allgemeinmedizin', 'Huisartsgeneeskunde', 'Medycyna ogólna', 'Genel Pratisyen', 'طب عام', 'stethoscope', 1),
    ('dentist', 'Dentist', 'Zahnarzt', 'Tandarts', 'Dentysta', 'Diş Hekimi', 'طبيب أسنان', 'mouth.fill', 2),
    ('cardiologist', 'Cardiologist', 'Kardiologe', 'Cardioloog', 'Kardiolog', 'Kardiyolog', 'طبيب قلب', 'heart.fill', 3),
    ('dermatologist', 'Dermatologist', 'Dermatologe', 'Dermatoloog', 'Dermatolog', 'Dermatolog', 'طبيب جلدية', 'hand.raised.fill', 4),
    ('pediatrician', 'Pediatrician', 'Kinderarzt', 'Kinderarts', 'Pediatra', 'Çocuk Doktoru', 'طبيب أطفال', 'figure.and.child.holdinghands', 5),
    ('orthopedic', 'Orthopedic', 'Orthopäde', 'Orthopeed', 'Ortopeda', 'Ortopedist', 'طبيب عظام', 'figure.walk', 6),
    ('gynecologist', 'Gynecologist', 'Gynäkologe', 'Gynaecoloog', 'Ginekolog', 'Jinekolog', 'طبيب نسائية', 'person.fill', 7),
    ('psychiatrist', 'Psychiatrist', 'Psychiater', 'Psychiater', 'Psychiatra', 'Psikiyatrist', 'طبيب نفسي', 'brain.head.profile', 8),
    ('ophthalmologist', 'Ophthalmologist', 'Augenarzt', 'Oogarts', 'Okulista', 'Göz Doktoru', 'طبيب عيون', 'eye.fill', 9),
    ('ent', 'ENT Specialist', 'HNO-Arzt', 'KNO-arts', 'Laryngolog', 'KBB Uzmanı', 'طبيب أنف وأذن', 'ear.fill', 10);

-- Sample providers (multi-country)
INSERT INTO providers (name, specialty, clinic_name, address, city, country_code, latitude, longitude, phone) VALUES
    ('Dr. Sarah Mitchell', 'Cardiologist', 'London Heart Centre', '123 Harley St', 'London', 'GB', 51.5194, -0.1483, '+44 20 7000 0001'),
    ('Dr. Hans Weber', 'Dentist', 'Zahnarztpraxis Weber', 'Friedrichstr. 100', 'Berlin', 'DE', 52.5200, 13.3880, '+49 30 000 0002'),
    ('Dr. Jan de Vries', 'General Practice', 'Huisartsenpraktijk de Vries', 'Keizersgracht 200', 'Amsterdam', 'NL', 52.3676, 4.8936, '+31 20 000 0003'),
    ('Dr. Anna Kowalska', 'Dermatologist', 'Klinika Skóry', 'ul. Marszałkowska 50', 'Warsaw', 'PL', 52.2297, 21.0122, '+48 22 000 0004'),
    ('Dr. Ayşe Yılmaz', 'Pediatrician', 'Çocuk Sağlığı Merkezi', 'Seyhan, Adana', 'Adana', 'TR', 36.9914, 35.3308, '+90 322 000 0005');
```

### E.7 Database Functions

```sql
-- Search providers with Haversine distance (no PostGIS)
CREATE OR REPLACE FUNCTION search_providers(
    search_text TEXT DEFAULT NULL,
    specialty_filter TEXT DEFAULT NULL,
    country_filter TEXT DEFAULT NULL,
    price_level_filter INTEGER DEFAULT NULL,
    min_rating NUMERIC DEFAULT 0,
    verified_only BOOLEAN DEFAULT FALSE,
    user_lat DOUBLE PRECISION DEFAULT NULL,
    user_lng DOUBLE PRECISION DEFAULT NULL,
    max_distance_km INTEGER DEFAULT 50,
    include_featured BOOLEAN DEFAULT TRUE,
    result_limit INTEGER DEFAULT 20,
    result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    specialty TEXT,
    clinic_name TEXT,
    address TEXT,
    city TEXT,
    country_code TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    phone TEXT,
    photo_url TEXT,
    rating_overall NUMERIC(3,2),
    review_count INTEGER,
    verified_review_count INTEGER,
    price_level_avg NUMERIC(2,1),
    is_claimed BOOLEAN,
    subscription_tier TEXT,
    is_featured BOOLEAN,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id, p.name, p.specialty, p.clinic_name,
        p.address, p.city, p.country_code,
        p.latitude, p.longitude, p.phone,
        p.photo_url, p.rating_overall, p.review_count,
        p.verified_review_count, p.price_level_avg,
        p.is_claimed, p.subscription_tier, p.is_featured,
        CASE WHEN user_lat IS NOT NULL AND user_lng IS NOT NULL THEN
            6371 * ACOS(LEAST(1.0,
                COS(RADIANS(user_lat)) * COS(RADIANS(p.latitude)) *
                COS(RADIANS(p.longitude) - RADIANS(user_lng)) +
                SIN(RADIANS(user_lat)) * SIN(RADIANS(p.latitude))))
        ELSE NULL END AS distance_km
    FROM providers p
    WHERE p.is_active = TRUE
        AND p.rating_overall >= min_rating
        AND (specialty_filter IS NULL OR p.specialty = specialty_filter)
        AND (country_filter IS NULL OR p.country_code = country_filter)
        AND (price_level_filter IS NULL OR ROUND(p.price_level_avg) = price_level_filter)
        AND (NOT verified_only OR p.verified_review_count > 0)
        AND (search_text IS NULL OR
             p.name ILIKE '%' || search_text || '%' OR
             p.clinic_name ILIKE '%' || search_text || '%' OR
             p.specialty ILIKE '%' || search_text || '%' OR
             p.city ILIKE '%' || search_text || '%')
        AND (user_lat IS NULL OR user_lng IS NULL OR
             p.latitude BETWEEN user_lat - (max_distance_km / 111.0)
                            AND user_lat + (max_distance_km / 111.0)
             AND p.longitude BETWEEN user_lng - (max_distance_km / (111.0 * COS(RADIANS(user_lat))))
                                AND user_lng + (max_distance_km / (111.0 * COS(RADIANS(user_lat)))))
    ORDER BY
        -- Featured providers first (if enabled)
        CASE WHEN include_featured AND p.is_featured THEN 0 ELSE 1 END,
        -- Then by distance if location provided
        CASE WHEN user_lat IS NOT NULL THEN
            6371 * ACOS(LEAST(1.0,
                COS(RADIANS(user_lat)) * COS(RADIANS(p.latitude)) *
                COS(RADIANS(p.longitude) - RADIANS(user_lng)) +
                SIN(RADIANS(user_lat)) * SIN(RADIANS(p.latitude))))
        ELSE 0 END ASC,
        p.rating_overall DESC
    LIMIT result_limit OFFSET result_offset;
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## PART F: EDGE FUNCTIONS

### F.1 AI Review Verification (Day 1)

```typescript
// supabase/functions/verify-review/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

serve(async (req) => {
    const { review_id } = await req.json()

    const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // 1. Fetch review with provider name
    const { data: review, error } = await supabase
        .from("reviews")
        .select("*, providers(name, clinic_name)")
        .eq("id", review_id)
        .single()

    if (error || !review?.proof_image_url) {
        return new Response(JSON.stringify({ error: "No proof found" }), { status: 400 })
    }

    // 2. Download proof image from storage
    const storagePath = review.proof_image_url.replace(/^.*verification-proofs\//, '')
    const { data: imageBlob, error: dlError } = await supabase.storage
        .from("verification-proofs")
        .download(storagePath)

    if (dlError || !imageBlob) {
        return new Response(JSON.stringify({ error: "Image download failed" }), { status: 500 })
    }

    const arrayBuffer = await imageBlob.arrayBuffer()
    const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))

    // 3. Send to OpenAI Vision for analysis
    const providerName = review.providers?.name || "Unknown"
    const clinicName = review.providers?.clinic_name || ""

    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${Deno.env.get("OPENAI_API_KEY")}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            model: "gpt-4o-mini",
            messages: [{
                role: "system",
                content: "You are a document verification assistant. Analyze medical documents to verify healthcare visits. Respond ONLY with valid JSON."
            }, {
                role: "user",
                content: [
                    {
                        type: "text",
                        text: `Analyze this image. Is it a legitimate medical/healthcare document (receipt, prescription, appointment confirmation, medical report)?

The review claims a visit to provider "${providerName}" at "${clinicName}".

Respond with JSON only:
{
    "is_legitimate": true/false,
    "confidence": 0-100,
    "document_type": "receipt|prescription|appointment|report|unknown",
    "mentions_provider": true/false,
    "has_date": true/false,
    "reason": "brief explanation"
}`
                    },
                    {
                        type: "image_url",
                        image_url: { url: `data:image/jpeg;base64,${base64}` }
                    }
                ]
            }],
            max_tokens: 300,
            temperature: 0.1
        })
    })

    const aiResult = await aiResponse.json()
    let analysis
    try {
        const content = aiResult.choices[0].message.content
        analysis = JSON.parse(content.replace(/```json|```/g, '').trim())
    } catch {
        analysis = { is_legitimate: false, confidence: 0, reason: "Failed to parse AI response" }
    }

    // 4. Update review based on AI analysis
    const isVerified = analysis.is_legitimate && analysis.confidence >= 70
    const updateData: any = {
        verification_confidence: analysis.confidence,
        verification_reason: analysis.reason,
    }

    if (isVerified) {
        updateData.is_verified = true
        updateData.verified_at = new Date().toISOString()
        updateData.status = 'active'
    }
    // If confidence is low, leave as pending_verification for manual review

    await supabase
        .from("reviews")
        .update(updateData)
        .eq("id", review_id)

    return new Response(JSON.stringify({
        review_id,
        is_verified: isVerified,
        confidence: analysis.confidence,
        reason: analysis.reason
    }), {
        headers: { "Content-Type": "application/json" }
    })
})
```

**Trigger mechanism:** This Edge Function is triggered via a `pg_net` database trigger on INSERT to `reviews` table WHERE `proof_image_url IS NOT NULL`. The trigger is defined in `supabase/migrations/00002_verification_webhook.sql` and deployed via `supabase db push`. It uses `net.http_post()` to call the Edge Function URL with the review_id.

### F.2 AI Health Chat (V2)

```typescript
// supabase/functions/health-chat/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const SYSTEM_PROMPT = `You are TrustCare Health Assistant, a helpful AI that guides users toward appropriate healthcare.

CRITICAL RULES:
1. You are NOT a doctor. NEVER diagnose conditions.
2. NEVER prescribe medication or specific treatments.
3. ALWAYS recommend consulting a healthcare professional.
4. Suggest which SPECIALTY of doctor to visit based on symptoms.
5. Provide general health education only.
6. If symptoms sound urgent (chest pain, difficulty breathing, severe bleeding), immediately recommend emergency services.
7. Be empathetic, clear, and concise.
8. When appropriate, suggest the user search for providers on TrustCare.
9. Respond in the user's language if they write in a non-English language.

FORMAT:
- Keep responses under 200 words
- Use simple language
- End with a clear recommendation (specialty to visit, or call emergency services)
`

serve(async (req) => {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
        return new Response("Unauthorized", { status: 401 })
    }

    const { message, session_id, conversation_history } = await req.json()

    const supabase = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    // Verify user
    const { data: { user }, error: authError } = await supabase.auth.getUser(
        authHeader.replace("Bearer ", "")
    )
    if (authError || !user) {
        return new Response("Unauthorized", { status: 401 })
    }

    // Build messages array
    const messages = [
        { role: "system", content: SYSTEM_PROMPT },
        ...(conversation_history || []),
        { role: "user", content: message }
    ]

    // Call Anthropic Claude API
    const aiResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
            "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            model: "claude-sonnet-4-20250514",
            max_tokens: 500,
            system: SYSTEM_PROMPT,
            messages: messages.filter(m => m.role !== 'system').map(m => ({
                role: m.role,
                content: m.content
            }))
        })
    })

    const result = await aiResponse.json()
    const assistantMessage = result.content[0].text

    // Save to chat session
    const updatedHistory = [
        ...(conversation_history || []),
        { role: "user", content: message },
        { role: "assistant", content: assistantMessage }
    ]

    if (session_id) {
        await supabase.from("ai_chat_sessions").update({
            messages: updatedHistory,
            updated_at: new Date().toISOString()
        }).eq("id", session_id)
    } else {
        const { data: session } = await supabase.from("ai_chat_sessions").insert({
            user_id: user.id,
            title: message.substring(0, 100),
            messages: updatedHistory
        }).select().single()
    }

    return new Response(JSON.stringify({
        message: assistantMessage,
        session_id: session_id
    }), {
        headers: { "Content-Type": "application/json" }
    })
})
```

---

## PART G: iOS APPLICATION ARCHITECTURE

### G.1 Project Structure
```
TrustCare/
├── TrustCareApp.swift
├── Core/
│   ├── Theme.swift                     // AppColor, AppFont, tokens
│   ├── SupabaseManager.swift           // Singleton client
│   ├── LocationManager.swift           // CLLocationManager wrapper
│   ├── LocalizationManager.swift       // Language switching
│   └── Extensions/
│       ├── Color+Hex.swift
│       ├── View+Extensions.swift
│       └── String+Localized.swift
├── Models/
│   ├── Provider.swift
│   ├── Review.swift
│   ├── UserProfile.swift
│   ├── ProviderService.swift           // service catalog item model
│   ├── ProviderClaim.swift
│   ├── Enums.swift
│   └── [V2] ChatMessage.swift
├── Services/
│   ├── AuthService.swift
│   ├── ProviderService.swift
│   ├── ReviewService.swift
│   ├── ImageService.swift
│   ├── ClaimService.swift
│   └── [V2] ChatService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── HomeViewModel.swift
│   ├── ProviderDetailViewModel.swift
│   ├── ReviewSubmissionViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── ClaimViewModel.swift
│   └── [V2] ChatViewModel.swift
├── Views/
│   ├── Onboarding/
│   │   ├── SplashView.swift
│   │   ├── OnboardingView.swift
│   │   └── AuthView.swift
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── ProviderCardView.swift
│   │   ├── ProviderDetailView.swift
│   │   ├── ProviderMapView.swift
│   │   ├── ServicesCatalogView.swift
│   │   └── ClaimProviderView.swift
│   ├── Review/
│   │   ├── SubmitReviewView.swift
│   │   ├── RatingSliderView.swift
│   │   ├── PriceLevelPicker.swift
│   │   ├── AddProviderSheet.swift
│   │   └── ReviewConfirmationView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   ├── MyReviewsView.swift
│   │   └── SettingsView.swift
│   ├── [V2] Chat/
│   │   └── HealthChatView.swift
│   └── Components/
│       ├── SearchBarView.swift
│       ├── SpecialtyChipView.swift
│       ├── StarRatingView.swift
│       ├── PriceLevelView.swift
│       ├── VerifiedBadge.swift
│       ├── ClaimedBadge.swift
│       └── ReviewItemView.swift
├── Localization/
│   └── Localizable.xcstrings          // iOS 17 String Catalogs
└── Resources/
    └── Assets.xcassets
```

### G.2 Localization Strategy

Using iOS 17 **String Catalogs** (`.xcstrings`):

```swift
// LocalizationManager.swift
import SwiftUI

class LocalizationManager: ObservableObject {
    @AppStorage("appLanguage") var appLanguage: String = "en" {
        didSet { Bundle.setLanguage(appLanguage) }
    }

    static let supportedLanguages: [(code: String, name: String, flag: String)] = [
        ("en", "English", "🇬🇧"),
        ("de", "Deutsch", "🇩🇪"),
        ("nl", "Nederlands", "🇳🇱"),
        ("pl", "Polski", "🇵🇱"),
        ("tr", "Türkçe", "🇹🇷"),
        ("ar", "العربية", "🇸🇦"),
    ]

    var layoutDirection: LayoutDirection {
        appLanguage == "ar" ? .rightToLeft : .leftToRight
    }
}

// Usage in views:
Text("find_care_title", comment: "Home screen header")
// String Catalog entry: "find_care_title" = "Find Care" (en), "Pflege finden" (de), etc.
```

For Arabic: apply `.environment(\.layoutDirection, .rightToLeft)` on the root view when `ar` is selected.

### G.3 Key Swift Enums
```swift
enum VisitType: String, Codable, CaseIterable {
    case consultation, procedure, checkup, emergency
    var displayName: LocalizedStringKey {
        switch self {
        case .consultation: return "visit_type_consultation"
        case .procedure:    return "visit_type_procedure"
        case .checkup:      return "visit_type_checkup"
        case .emergency:    return "visit_type_emergency"
        }
    }
}

enum PriceLevel: Int, Codable, CaseIterable {
    case budget = 1, moderate = 2, aboveAverage = 3, premium = 4
    var symbol: String {
        String(repeating: "$", count: rawValue)
    }
    var label: LocalizedStringKey {
        switch self {
        case .budget:       return "price_budget"
        case .moderate:     return "price_moderate"
        case .aboveAverage: return "price_above_average"
        case .premium:      return "price_premium"
        }
    }
}

enum ReviewStatus: String, Codable {
    case active
    case pendingVerification = "pending_verification"
    case flagged, removed
}

enum SubscriptionTier: String, Codable {
    case free, basic, premium
}

enum ClaimStatus: String, Codable {
    case pending, approved, rejected
}

enum AppError: Error, LocalizedError {
    case networkError(String)
    case authError(String)
    case validationError(String)
    case uploadFailed
    case notFound
    case unknown
    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return msg
        case .authError(let msg):    return msg
        case .validationError(let msg): return msg
        case .uploadFailed: return String(localized: "error_upload_failed")
        case .notFound:     return String(localized: "error_not_found")
        case .unknown:      return String(localized: "error_unknown")
        }
    }
}
```

---

## PART H: VIBE CODING PROMPTS (5 Prompts for V1)

> **Strategy:** 5 self-contained prompts. Each carries forward all context needed. Execute in order.

---

### PROMPT 1: Project Setup + Backend + Core Models

```
I am building a native iOS app called "TrustCare" using SwiftUI (iOS 17+) and
Supabase. It lets users find healthcare providers and leave verified reviews.
Multi-country, multi-language (en, de, nl, pl, tr, ar). Monetized via provider
subscriptions and ads.

STEP 1 — Create the Xcode project:
- Target: iOS 17.0, SwiftUI lifecycle
- SPM: supabase-swift (^2.0.0), SDWebImageSwiftUI (^3.0.0)
- Folder structure:
  Core/, Models/, Services/, ViewModels/,
  Views/Onboarding/, Views/Home/, Views/Review/, Views/Profile/, Views/Components/,
  Localization/, Resources/

STEP 2 — Core/Theme.swift:
- AppColor: trustBlue (#0055FF), trustBlueLight (#4D88FF), trustBlueDark (#0044CC),
  background (.systemGroupedBackground), cardBackground (.secondarySystemGroupedBackground),
  success (#34C759), warning (#FF9500), error (#FF3B30), starFilled (#FFCC00),
  starEmpty (.systemGray5), priceActive (#34C759), priceInactive (.systemGray4)
- AppFont: largeTitle(34,bold,rounded), title1(28,bold,rounded), title2(22,semibold,rounded),
  title3(20,semibold,rounded), headline(17,semibold), body(17,regular),
  caption(15,regular), footnote(13,regular)
- Color+Hex.swift extension

STEP 3 — Config/Supabase.xcconfig + Config/SupabaseConfig.swift:
- Supabase.xcconfig: SUPABASE_URL and SUPABASE_ANON_KEY values (git-ignored)
- SupabaseConfig.swift: reads from Bundle.main.infoDictionary (populated via xcconfig)
- Info.plist entries: $(SUPABASE_URL) and $(SUPABASE_ANON_KEY) — resolved from xcconfig at build time
- For development: use local values from `supabase status` (http://127.0.0.1:54321)
- For production: swap to remote project URL/key

STEP 4 — Core/SupabaseManager.swift:
- Singleton, lazy SupabaseClient
- Reads URL and key from SupabaseConfig (which reads from xcconfig via Info.plist)

STEP 5 — Core/LocationManager.swift:
- ObservableObject wrapping CLLocationManager
- @Published userLocation, authorizationStatus
- requestPermission(), startUpdating()

STEP 6 — Core/LocalizationManager.swift:
- @AppStorage("appLanguage") with supported languages list
- layoutDirection computed property (RTL for Arabic)

STEP 7 — Create Localizable.xcstrings (String Catalog) with keys for:
- All screen titles, button labels, specialty names, error messages
- 6 language columns: en (filled), de/nl/pl/tr/ar (placeholders)

STEP 8 — Models/ (all Codable, CodingKeys mapping to snake_case):
- Provider.swift: id, name, specialty, clinicName, address, city, countryCode,
  latitude, longitude, phone, email, website, photoUrl, coverUrl,
  ratingOverall, ratingWaitTime, ratingBedside, ratingEfficacy, ratingCleanliness,
  reviewCount, verifiedReviewCount, priceLevelAvg, isClaimed, subscriptionTier,
  isFeatured, distanceKm (optional). Computed: verifiedPercentage.
- Review.swift: id, userId, providerId, visitDate, visitType, ratingWaitTime(Int),
  ratingBedside(Int), ratingEfficacy(Int), ratingCleanliness(Int),
  ratingOverall(Double), priceLevel(Int), title, comment, wouldRecommend,
  proofImageUrl, isVerified, verificationConfidence, status, helpfulCount,
  createdAt. Joined fields: reviewerName, reviewerAvatar.
- UserProfile.swift: id, fullName, avatarUrl, phone, countryCode,
  preferredLanguage, preferredCurrency, referralCode, createdAt.
- ProviderServiceItem.swift: id, providerId, category, name, description,
  priceMin, priceMax, currency, durationMinutes.
- ProviderClaim.swift: id, providerId, claimantRole, businessEmail,
  phone, licenseNumber, proofDocumentUrl, status, createdAt.
- Enums.swift: VisitType, PriceLevel, ReviewStatus, SubscriptionTier,
  ClaimStatus, AppError (all as shown in spec).

STEP 9 — SQL migration file (supabase/migrations/00001_schema.sql):
[The ENTIRE SQL from Part E sections E.1 through E.7]
After creating: run `supabase db reset` to apply locally.
For production: run `supabase db push` to deploy to remote.

STEP 10 — Seed data (supabase/seed.sql):
[Specialties, sample providers, feature flags from Part E.7]
Automatically applied by `supabase db reset`.

STEP 11 — Storage config (supabase/config.toml):
Add [storage.buckets] section for all 5 buckets with public/private flags and mime types.
Applied on `supabase start` / `supabase stop && supabase start`.

STEP 12 — Info.plist:
- NSLocationWhenInUseUsageDescription
- NSPhotoLibraryUsageDescription
- NSCameraUsageDescription
- $(SUPABASE_URL) and $(SUPABASE_ANON_KEY) — resolved from xcconfig

STEP 13 — .gitignore:
- Config/Supabase.xcconfig (never commit Supabase keys)
- *.xcuserdata, build/, DerivedData/, .DS_Store

Use MVVM. NavigationStack with NavigationPath. No Coordinator pattern.
```

---

### PROMPT 2: Authentication + Onboarding

```
Continue TrustCare. We have Theme.swift, SupabaseManager, LocalizationManager,
LocationManager, all Models, and the SQL schema.

STEP 1 — Services/AuthService.swift:
- signUp(email:password:fullName:referralCode:) → create account, profile auto-created by trigger.
  If referralCode provided, update profiles.referred_by.
- signIn(email:password:), signInWithApple(idToken:nonce:)
- signOut(), currentSession, onAuthStateChange listener
- All async throws

STEP 2 — ViewModels/AuthViewModel.swift:
- @Published: email, password, fullName, referralCode, isLoading, errorMessage, isAuthenticated
- Validation: email format, password min 8, fullName not empty
- login(), signUp(), signInWithApple(), signOut()
- Auth state listener on init

STEP 3 — Views/Onboarding/SplashView.swift:
- Blue gradient, centered icon + "TrustCare" + "Healthcare, Verified."
- After 2s: check session → MainTabView or OnboardingView
- Use .task {}

STEP 4 — Views/Onboarding/OnboardingView.swift:
- 3-page TabView(.page):
  1. stethoscope / "Find Trusted Care" / "Discover verified doctors..."
  2. checkmark.shield.fill / "Verified Reviews" / "AI-verified recommendations..."
  3. person.3.fill / "Help Others" / "Your reviews guide others..."
- Next/Skip, page indicators. @AppStorage("hasSeenOnboarding")

STEP 5 — Views/Onboarding/AuthView.swift:
- Toggle login/signup. Email + password fields with SF icons.
- SignInWithAppleButton. "Continue with Phone" → PhoneAuthSheet.
- Phone auth: country code picker + phone field + OTP verification.
- Referral code field on signup (optional, caption: "Have a referral code?")
- Loading overlay, error display, validation borders.
- Country auto-detection from locale for phone format.

STEP 6 — TrustCareApp.swift (@main):
- Init SupabaseManager
- Root: SplashView → OnboardingView/AuthView → MainTabView
- @StateObject AuthViewModel as environmentObject
- Apply .environment(\.layoutDirection) from LocalizationManager

Design: trustBlue buttons, cornerRadius 12, 44pt min fields, body font.
All text uses localization keys from String Catalog.
```

---

### PROMPT 3: Home Tab + Provider Detail + Services + Claims

```
Continue TrustCare. Auth is complete. MainTabView has 3 tabs:
"Find" (house.fill), "Review" (plus.circle.fill), "Profile" (person.circle.fill).

STEP 1 — Services/ProviderService.swift:
- searchProviders(text:specialty:country:priceLevel:minRating:verifiedOnly:lat:lng:) →
  calls Supabase RPC "search_providers", returns [Provider]
- fetchProviderById(id:) → Provider
- fetchReviewsForProvider(id:sort:limit:offset:) → reviews joined with profiles
- fetchServicesForProvider(id:) → [ProviderServiceItem]
- addProvider(name:specialty:address:lat:lng:phone:) → Provider (crowdsourced add)

STEP 2 — ViewModels/HomeViewModel.swift:
- @Published: providers, searchText, selectedSpecialty, selectedPriceFilter,
  isLoading, viewMode (list/map), errorMessage
- Debounced search (.task(id:)), specialty/price filter, pull-to-refresh
- Location-based sorting via LocationManager

STEP 3 — Reusable Components:
- SearchBarView.swift: magnifyingglass, clear button, 44pt, cardBackground, cornerRadius 12
- SpecialtyChipView.swift: capsule, selected=trustBlue/white, unselected=cardBackground/primary
- StarRatingView.swift: star.fill/star HStack, accepts Double
- PriceLevelView.swift: shows $ symbols (1-4), active=priceActive, inactive=priceInactive
- VerifiedBadge.swift: checkmark.seal.fill + "Verified", success color
- ClaimedBadge.swift: checkmark.circle.fill + "Claimed", trustBlue (for business profiles)
- ReviewItemView.swift: avatar, name, date, stars, price level, verification badge,
  comment (3 line truncated, "Read more"), helpful button

STEP 4 — ProviderCardView.swift:
- HStack: photo(64x64 circle) + VStack(name, specialty+clinic, rating, verified badge,
  price level, distance). Card style. NavigationLink.
- If is_featured: subtle featuredBorder + "Sponsored" footnote label
- If is_claimed: ClaimedBadge near name

STEP 5 — HomeView.swift:
- Greeting + location header
- SearchBarView
- Horizontal specialty chips ScrollView
- Second row: price filter chips + "Verified Only" toggle chip
- Segmented: List | Map
- List: LazyVStack of ProviderCardView, .refreshable, pagination
- Map: Map with Annotation markers, tap → sheet → detail
- Empty state + loading state

STEP 6 — ProviderDetailViewModel.swift:
- @Published: provider, reviews, services, isLoading
- fetchDetails(id:) → parallel load provider + reviews + services
- submitHelpfulVote(reviewId:isHelpful:)

STEP 7 — ProviderDetailView.swift:
- Hero cover + profile photo overlay, back/share buttons
- If unclaimed: "Is this your practice? Claim it" banner → ClaimProviderView sheet
- Info: name + ClaimedBadge (if claimed), specialty, clinic, rating row,
  price level, address, phone, website, languages
- Quick actions: Call (tel://), Directions (maps://)
- Statistics grid 2×2 (wait, bedside, efficacy, cleanliness)
- Services section (only for claimed+subscribed): ServiceItemView list, "View All" →
  ServicesCatalogView. If not claimed, section hidden.
- Reviews section: sort picker, ReviewItemView list, "See All", "Write a Review"

STEP 8 — ServicesCatalogView.swift:
- Grouped by category. Each: name, description, price (range or fixed), duration.
- Contact CTA at bottom.

STEP 9 — ClaimProviderView.swift (Sheet):
- Title: "Claim This Practice"
- Fields: role picker, business email, phone, license number, proof upload (PhotosPicker)
- "Submit Claim" → ClaimService.submitClaim() → inserts provider_claims row
- Success: "Claim submitted. We'll review within 48 hours."

STEP 10 — Services/ClaimService.swift:
- submitClaim(providerId:role:email:phone:license:proofImage:) → async throws
- Uploads proof to "claim-documents" bucket, inserts claim row

All text localized. Images via SDWebImageSwiftUI WebImage with placeholder.
```

---

### PROMPT 4: Review Submission with Price Level + AI Verification

```
Continue TrustCare. Home tab complete. SubmitReview is Tab 2.
If navigated from ProviderDetailView, provider is pre-selected.

STEP 1 — Services/ReviewService.swift:
- submitReview(providerId:visitDate:visitType:ratings:priceLevel:title:comment:
  wouldRecommend:proofImage:) → async throws → Review
  - If proofImage: upload to "verification-proofs/{userId}/{UUID}.jpg"
  - Insert review row
  - If proof uploaded: trigger AI verification (invoke Edge Function "verify-review"
    with review_id — or rely on database webhook trigger)
  - Return created review
- Services/ImageService.swift:
  - uploadImage(bucket:path:image:) → compress JPEG 0.7, upload, return URL

STEP 2 — ViewModels/ReviewSubmissionViewModel.swift:
- @Published: currentStep (1-6), selectedProvider, visitDate, visitType,
  ratingWaitTime(5), ratingBedside(5), ratingEfficacy(5), ratingCleanliness(5),
  priceLevel (PriceLevel.moderate), title, comment, proofImage (UIImage?),
  wouldRecommend(true), isSubmitting, errorMessage, isComplete
- Computed: canAdvance (validates current step), overallRating (avg/2)
- nextStep(), previousStep(), submit()
- Validation per step:
  1: provider selected
  2: date not future
  3: always valid (defaults ok)
  4: always valid (default selection ok)
  5: comment.count >= 50
  6: always valid (proof optional)

STEP 3 — Views/Components/RatingSliderView.swift:
- Icon + criterion name label
- Slider 1...10 step 1, value display
- "Poor" ← → "Excellent" labels
- Star equivalent below: value/2 as StarRatingView

STEP 4 — Views/Components/PriceLevelPicker.swift:
- "How expensive was your visit?" (title3)
- 4 large tappable cards in 2×2 grid:
  $ "Budget" | $$ "Moderate" | $$$ "Above Average" | $$$$ "Premium"
- Selected: trustBlue border+fill, white text
- Unselected: cardBackground, primary text, border

STEP 5 — Views/Review/AddProviderSheet.swift:
- For when user can't find their provider
- Fields: name (required), specialty picker (required), clinic name, address (required),
  phone (optional)
- "Add Provider" → ProviderService.addProvider() → auto-selects as review target
- Provider created with is_claimed=false, created_by=current user

STEP 6 — Views/Review/SubmitReviewView.swift:
- Progress bar (currentStep / 6)
- Step 1: search + results + "Can't find? Add new" link → AddProviderSheet
- Step 2: DatePicker + visit type Picker
- Step 3: 4× RatingSliderView
- Step 4: PriceLevelPicker
- Step 5: title TextField + comment TextEditor + char counter (red if <50)
         + "Would you recommend?" toggle
- Step 6: PhotosPicker + image preview + privacy note + "Skip Verification"
- Bottom: Back (if step>1) + Next/Submit. Next disabled if !canAdvance.
- Submit: ProgressView overlay during submission.

STEP 7 — Views/Review/ReviewConfirmationView.swift:
- checkmark.circle.fill animation (success, scale)
- "Review Submitted!" (title1)
- Status badge: "AI Verification in Progress" (pending) or "Published" (no proof)
- "Back to Home" button

Error handling: alert on failure, preserve form data.
Image compression: max 1MB. All text localized.
```

---

### PROMPT 5: Profile + Settings + Polish + Admin Panel Setup

```
Continue TrustCare. Home and Review tabs complete. Profile is Tab 3.

STEP 1 — ViewModels/ProfileViewModel.swift:
- @Published: profile, myReviews, selectedFilter, isLoading
- loadProfile(), loadReviews(filter:), deleteReview(id:), signOut()

STEP 2 — Views/Profile/ProfileView.swift:
- Header: avatar (80×80, PhotosPicker to change), name (title2), member since
- Referral code display: "Your code: XXXX1234" (tappable to copy/share)
- Stats row: reviews count, verified %, helpful votes
- Menu: My Reviews, Settings, Help, Privacy, Terms, Log Out (confirmation)

STEP 3 — Views/Profile/MyReviewsView.swift:
- Segmented: All | Verified | Pending | Unverified
- Each: provider name, date, rating, price level, status badge
- Swipe delete with confirmation
- Empty state

STEP 4 — Views/Profile/SettingsView.swift:
- Account: email, phone, change password
- Language: picker with flag+name (6 options). Changes @AppStorage + Supabase profile.
  Arabic → RTL layout.
- Country/Region: picker (affects currency display)
- Theme: System/Light/Dark
- Notifications: toggle
- About: version, terms link, privacy link
- Delete Account: double confirmation → Supabase delete

STEP 5 — MainTabView.swift:
- TabView: house.fill "Find", plus.circle.fill "Review", person.circle.fill "Profile"
- Each tab in NavigationStack. Selected color: trustBlue.

STEP 6 — Final polish across ALL views:
- Dark mode: verify all AppColors adapt (use semantic colors)
- Loading: ProgressView on all async ops
- Errors: .alert on all views with error binding
- Empty states: all lists
- Accessibility: .accessibilityLabel on interactive elements, Dynamic Type
- Haptics: UIImpactFeedbackGenerator on buttons
- Pull-to-refresh: all list views
- Keyboard: .scrollDismissesKeyboard(.interactively)
- RTL: tested with Arabic language setting
- Localization: all visible text uses String Catalog keys

STEP 7 — Admin Panel (separate Next.js project):
Create a new Next.js 14 project "trustcare-admin" with:
- Supabase Auth (email/password, restricted to admin role)
- Tailwind CSS + shadcn/ui components
- Pages:
  1. /dashboard — metrics cards (users, reviews, pending verifications, claims) + charts
  2. /reviews — table with filters (pending, flagged, all). Actions: verify, reject, flag.
     Shows AI confidence score + reason. View proof image in modal.
  3. /providers — table with filters. Actions: edit, deactivate, feature/unfeature.
  4. /claims — table of pending claims. View proof docs. Approve → sets is_claimed=true
     on provider + creates subscription entry. Reject with reason.
  5. /users — table. Actions: view, suspend, ban.
  6. /settings — admin management, feature flags.
- Auth middleware: check user_roles for admin/moderator role on every route.
- Use @supabase/supabase-js for all data fetching.
- Responsive design (works on tablet for on-the-go moderation).

STEP 8 — Edge Functions (via Supabase CLI):
- Create supabase/functions/verify-review/index.ts (AI verification with 3-tier confidence)
- Create supabase/functions/export-user-data/index.ts (GDPR data export)
- Create supabase/migrations/00002_verification_webhook.sql (pg_net trigger for auto-verification)
- Test locally: supabase functions serve
- Deploy to remote:
  supabase functions deploy verify-review
  supabase functions deploy export-user-data
  supabase secrets set OPENAI_API_KEY=sk-your-key
  supabase db push

Test complete flow: Sign up with referral code → Browse providers → View detail
with services → Submit review with price level + photo → AI verification triggers →
View in My Reviews → Check admin panel shows pending → Verify in admin → Status
updates. Also test: add new provider, claim provider flow, language switching.
```

---

## PART I: PRODUCTION CHECKLIST

### App Store
- [ ] App icon 1024×1024 + all sizes
- [ ] Launch screen storyboard
- [ ] Screenshots: iPhone 15 Pro Max (6.7") + iPhone SE (4.7")
- [ ] App Store description + keywords in all 6 languages
- [ ] Privacy policy URL (required for Medical category)
- [ ] Support URL + support email
- [ ] Age rating: 12+ (Medical/Treatment Information)
- [ ] Category: Medical (primary), Health & Fitness (secondary)

### Supabase Production
- [ ] Upgrade to paid plan before launch
- [ ] Push schema to remote: `supabase db push`
- [ ] Deploy Edge Functions: `supabase functions deploy verify-review` + `export-user-data`
- [ ] Set production secrets: `supabase secrets set OPENAI_API_KEY=sk-your-key`
- [ ] Enable email confirmation (Dashboard → Authentication → Settings)
- [ ] Configure Apple OAuth (Dashboard → Authentication → Providers → Apple)
- [ ] Configure phone auth (Twilio) for multi-country
- [ ] Daily database backups enabled (Dashboard → Settings → Database)
- [ ] Rate limiting on auth endpoints
- [ ] Create initial admin user: `supabase db execute "INSERT INTO user_roles ..."`
- [ ] Update Supabase.xcconfig with production URL and anon key

### Admin Panel
- [ ] Deploy to Vercel (or similar)
- [ ] Custom domain (admin.trustcare.app)
- [ ] Auth restricted to admin role
- [ ] All CRUD operations tested

### Security
- [ ] Supabase keys in Supabase.xcconfig (git-ignored, never committed)
- [ ] .gitignore excludes Config/Supabase.xcconfig
- [ ] RLS policies tested (cross-user access prevented)
- [ ] proof_image_url not exposed to non-owners in SELECT
- [ ] claim-documents bucket only readable by admins
- [ ] Phone numbers validated per country format

### Localization
- [ ] All 6 languages have complete String Catalog entries
- [ ] RTL layout tested with Arabic
- [ ] Specialty names translated (from specialties table)
- [ ] Date/time/currency formatting respects locale
- [ ] App Store listing localized

### Monitoring
- [ ] Crashlytics or Sentry integrated
- [ ] Supabase dashboard monitored for slow queries
- [ ] Edge Function logging: `supabase functions logs verify-review`
- [ ] AI verification success rate tracked

---

## PART J: CHANGELOG — V5 vs V4

| Change | V4 | V5 |
|--------|----|----|
| Price level | Not present | Crowdsourced $/$$/$$$/$$$$ on reviews, averaged on providers |
| Services catalog | Not present | provider_services table, shown for claimed providers |
| Provider claims | Not present | Google Maps-style claim flow, provider_claims table, admin approval |
| Subscriptions | Not present | provider_subscriptions table (free/basic/premium tiers) |
| Multi-language | Not present | 6 languages via String Catalogs, RTL for Arabic |
| Multi-country | Not present | country_code on providers + profiles, phone auth per country |
| Admin panel | Not present | Next.js web app, 6 screens, Day 1 requirement |
| AI verification | Edge Function present but no trigger | Database webhook auto-triggers on proof upload |
| Referral codes | Not present | Auto-generated per user, provider codes (V2) |
| Campaigns/ads | Not present | provider_campaigns table, featured listings (V2) |
| AI Health Chat | Not present | Claude-powered chat with safety guardrails (V2) |
| Appointments | Not present | Booking + contact forms (V3) |
| Provider adding | Not present | Users can add providers during review (crowdsourced) |
| Monetization | Not addressed | Free for users, subscriptions + ads + marketplace revenue model |
| Schema tables | 7 tables | 15 tables (+ 3 V2/V3 tables ready) |
| Seed data | 5 providers (Turkey) | 5 providers across 5 countries |
| Featured/sponsored | Not present | is_featured flag + "Sponsored" label on cards |
