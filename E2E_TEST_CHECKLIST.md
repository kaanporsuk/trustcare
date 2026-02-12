# TrustCare End-to-End Testing Checklist
## February 13, 2026

### Phase 1: Launch & Authentication
- [ ] Launch app in iOS Simulator or device
- [ ] See login screen (email/password or Sign in with Apple)
- [ ] Create test account or use existing: test@trustcare.app / Test123!
- [ ] Sign in succeeds
- [ ] Nav to Home tab automatically after sign-in
- [ ] No errors in console

### Phase 2: Home Tab - Provider Search
- [ ] Home tab loads with nearby providers OR empty state if no location
- [ ] Search bar visible at top
- [ ] Search for "dentist" 
  - [ ] Provider cards appear with name, specialty, rating, distance
  - [ ] Tap provider card → ProviderDetailView opens
  - [ ] Provider details display correctly (name, address, reviews, ratings)
  - [ ] Back button works, returns to Home
- [ ] Search for non-existent provider "zxcvbnmasdfghjkl"
  - [ ] "No providers found" message appears with helpful text
- [ ] Tap provider card to view details
  - [ ] Tab bar should be hidden
  - [ ] Back button visible and works
  - [ ] Reviews section shows reviews with ratings and text

### Phase 3: Review Tab - Complete Review Flow
#### Step 1: Find/Add Provider
- [ ] Review tab loads
- [ ] Progress bar shows "Step 1 of 7"
- [ ] Search input field visible
- [ ] Search for "dentist"
  - [ ] Loading spinner appears while searching
  - [ ] Results appear with address
  - [ ] Tap provider card
    - [ ] Card gets blue border and checkmark
    - [ ] "Change" button appears on selected provider
    - [ ] "Next" button should be enabled
- [ ] Test "Add a new provider" flow
  - [ ] Delete the selected provider
  - [ ] Search for non-existent "Dr. UniquePharmacist2026"
  - [ ] Tap "Add a new provider" button
  - [ ] Modal opens with form (Name, Specialty dropdown, Address required)
  - [ ] Fill in form:
    - Name: "Dr. Test Provider"
    - Specialty: "Cardiologist"
    - Address: "123 Test St, Test City"
  - [ ] Tap Submit
    - [ ] "Provider added successfully" toast appears
    - [ ] Modal closes
    - [ ] New provider is auto-selected
    - [ ] Auto-advances to Step 2
- [ ] OR search for existing provider and select

#### Step 2: Visit Details
- [ ] Progress bar shows "Step 2 of 7"
- [ ] DatePicker visible - "When was your visit?"
  - [ ] Can select past date
  - [ ] Cannot select future date (disabled)
- [ ] Visit Type picker with options (Consultation, Checkup, Emergency, etc.)
  - [ ] Select one (default: Consultation)
- [ ] Tap "Next"
  - [ ] Back button now works

#### Step 3: Ratings
- [ ] Progress bar shows "Step 3 of 7"
- [ ] Four slider controls visible:
  - [ ] Wait Time (with clock icon)
  - [ ] Bedside Manner (with heart icon)
  - [ ] Treatment Efficacy (with cross icon)
  - [ ] Cleanliness (with sparkles icon)
- [ ] Each slider shows current value
- [ ] Overall Rating card shows calculated star rating
- [ ] Adjust each slider and verify overall rating updates
- [ ] Tap "Next"

#### Step 4: Price Level
- [ ] Progress bar shows "Step 4 of 7"
- [ ] Price level picker visible with options:
  - [ ] Inexpensive / Moderate / Expensive / Very Expensive
- [ ] Select one
- [ ] Tap "Next"

#### Step 5: Written Review
- [ ] Progress bar shows "Step 5 of 7"
- [ ] Title field (optional text input)
  - [ ] Type in title, verify it limits to 100 characters
- [ ] Comment TextEditor
  - [ ] Type review text (must be ≥50 chars)
  - [ ] Character counter shows "X / 1000" below
  - [ ] Counter is RED when below 50 characters
  - [ ] Counter turns SECONDARY color when ≥50 characters
- [ ] "Would you recommend?" toggle
  - [ ] Toggle on/off works
- [ ] Test validation:
  - [ ] Type 25 characters → "Next" button DISABLED or error on tap
  - [ ] Type 50+ characters → "Next" button ENABLED
- [ ] Tap "Next" with valid comment

#### Step 6: Media
- [ ] Progress bar shows "Step 6 of 7"
- [ ] "Add Photos" section visible
- [ ] Test photo upload:
  - [ ] Tap "Add Photo" button
  - [ ] Photo picker opens (Camera roll, Recents, etc.)
  - [ ] Select photo from library
    - [ ] Photo appears in preview
    - [ ] Can add up to 5 photos
    - [ ] Each photo shows in grid
  - [ ] Test "Skip" button
    - [ ] Photos should be cleared
    - [ ] Auto-advances to Step 7
- [ ] OR add at least one photo and tap "Next"

#### Step 7: Verification
- [ ] Progress bar shows "Step 7 of 7"
- [ ] "Verify Your Visit" section
- [ ] Text explains what counts as proof
- [ ] Test verification:
  - **Option A: Skip Verification**
    - [ ] Tap "Skip Verification" button
    - [ ] Loading screen briefly shows
  - **Option B: Upload Proof**
    - [ ] Tap "Upload Proof" button
    - [ ] Photo picker opens
    - [ ] Select an image
    - [ ] Image preview appears
    - [ ] Text: "Only visible to our verification system..."
    - [ ] Tap "Submit Review"
      - [ ] Loading overlay appears: "Submitting review..."
      - [ ] Progress bar shows upload progress

#### Review Confirmation
- [ ] After submit, fullscreen modal appears:
  - [ ] Large checkmark animation (scales up from small)
  - [ ] "Review Submitted!" heading
  - [ ] Status text explaining verification:
    - "Your review is pending verification. We'll check your proof within 24-48 hours."
    - OR "Your review has been submitted. You can add verification documents anytime."
  - [ ] Two buttons: "Write Another Review" and "Go Home"
- [ ] Tap "Write Another Review"
  - [ ] Review form resets
  - [ ] Back on Step 1 (provider step)
- [ ] OR tap "Go Home"
  - [ ] Returns to Home tab
  - [ ] Tab bar is visible again

### Phase 4: Profile Tab - My Reviews
- [ ] Profile tab opens
- [ ] Avatar visible (with initials or photo if uploaded)
- [ ] Name, member since date visible
- [ ] Referral code visible (copy button works - haptic feedback)
- [ ] Review stats show (total reviews, verified %)
- [ ] Tap "My Reviews"
  - [ ] MyReviewsView opens
  - [ ] Tab bar hidden
  - [ ] Filter segmented picker (All / Verified / Pending)
  - [ ] Review card appears with:
    - [ ] Provider name
    - [ ] Specialty
    - [ ] Star rating
    - [ ] Review snippet (100 chars)
    - [ ] Date
    - [ ] Verification badge (Verified/Pending/Unverified)
  - [ ] Tap review card
    - [ ] ReviewDetailView opens showing full review
    - [ ] Back button works
  - [ ] Swipe left on review
    - [ ] Delete option appears
    - [ ] Confirm and delete (removes from list)
  - [ ] Pull-to-refresh works
  - [ ] Change filter to "Verified" or "Pending"
    - [ ] List updates to show only that type

### Phase 5: Profile Tab - Settings
- [ ] Back to Profile tab
- [ ] Tap "Settings"
  - [ ] SettingsView opens with sections:
    - [ ] Account: email (read-only), phone (read-only), Change Password link, Sign Out
    - [ ] Notifications: 3 toggles (Review Updates, Verification Status, New Providers)
    - [ ] Preferences: Language dropdown, Theme dropdown
    - [ ] Privacy & Consent: 4 toggles (Analytics, Marketing, Review Data, AI Verification)
    - [ ] Data Export: "Download My Data" button
    - [ ] About: Version number, "Rate App" link
    - [ ] Help & Information: "Help & Support", "Privacy Policy", "Terms of Service" links
    - [ ] Danger Zone: "Delete Account" button

#### Test Theme Change
- [ ] Tap Theme dropdown
- [ ] Select "Light" theme
  - [ ] App switches to light mode immediately
- [ ] Select "Dark" theme
  - [ ] App switches to dark mode
- [ ] Select "System" theme
  - [ ] App follows system setting

#### Test Language Change
- [ ] Tap Language dropdown
- [ ] Current language: English
- [ ] Select "Deutsch"
  - [ ] All UI text changes to German (if strings are translated)
  - [ ] OR verify structure works (strings will update)
- [ ] Select another language (Turkish, Arabic, Polish, Dutch)
  - [ ] Language changes
- [ ] Change back to English

#### Test Help & Support Page
- [ ] Tap "Help & Support"
  - [ ] HelpSupportView opens with scrollable content
  - [ ] Title: "Help & Support" (blue, bold)
  - [ ] Sections visible:
    - [ ] Getting Started (expandable FAQs)
    - [ ] Reviews & Verification (expandable FAQs)
    - [ ] Account (expandable FAQs)
    - [ ] Contact Us (email, response time, Send Feedback button)
  - [ ] Tap on Q&A items to expand/collapse
  - [ ] Tab bar hidden
  - [ ] Back button works (returns to Settings)
  - [ ] Content scrollable if needed

#### Test Privacy Policy Page
- [ ] Back to Settings
- [ ] Tap "Privacy Policy"
  - [ ] PrivacyPolicyView opens
  - [ ] Title: "Privacy Policy" with date (blue)
  - [ ] Sections visible with bullet points:
    - [ ] Information We Collect
    - [ ] How We Use Your Information
    - [ ] Data Storage & Security
    - [ ] Your Rights
    - [ ] Data Retention
    - [ ] Contact
  - [ ] Content scrollable
  - [ ] Back button works

#### Test Terms of Service Page
- [ ] Back to Settings
- [ ] Tap "Terms of Service"
  - [ ] TermsOfServiceView opens
  - [ ] 9 numbered sections visible:
    - [ ] 1. Acceptance of Terms
    - [ ] 2. User Accounts
    - [ ] 3. Reviews & Content
    - [ ] 4. Verification
    - [ ] 5. Provider Information
    - [ ] 6. Prohibited Conduct
    - [ ] 7. Limitation of Liability
    - [ ] 8. Changes to Terms
    - [ ] 9. Contact
  - [ ] Content scrollable
  - [ ] Back button works

### Phase 6: Profile Tab - Edit Profile
- [ ] Back to Profile tab
- [ ] Tap pencil icon next to name
  - [ ] EditProfileView opens as modal
  - [ ] Fields visible:
    - [ ] Full Name (pre-populated)
    - [ ] Bio (TextEditor, dark background)
    - [ ] Phone (pre-populated)
  - [ ] Edit name: "John Doe Test"
  - [ ] Edit bio: "Passionate about healthcare reviews"
  - [ ] Edit phone: "+1-555-1234"
  - [ ] Tap "Save"
    - [ ] Loading overlay appears
    - [ ] "Profile updated" toast appears at top
    - [ ] Success haptic feedback (feel vibration)
    - [ ] Modal closes
    - [ ] Name updates on profile card

#### Test Avatar Upload
- [ ] Tap avatar image
  - [ ] Action sheet appears: "Take Photo", "Choose from Library", "Cancel"
- [ ] Tap "Choose from Library"
  - [ ] Photo picker opens
  - [ ] Select a photo
    - [ ] Avatar updates with photo
    - [ ] "Photo updated" toast appears
    - [ ] Success haptic feedback
- [ ] OR tap "Take Photo"
  - [ ] Camera opens
  - [ ] Take a photo
    - [ ] Avatar updates
    - [ ] "Photo updated" toast appears

### Phase 7: Logout & Persistent Data
- [ ] Back to Profile tab
- [ ] Tap Settings
- [ ] Scroll to "Sign Out" button (or "Log Out" button)
- [ ] Tap Sign Out
  - [ ] Confirmation dialog appears
  - [ ] Tap "Log Out"
    - [ ] Warning haptic feedback
    - [ ] Redirected to Login screen
    - [ ] All user data cleared from local state

#### Sign Back In
- [ ] Tap email field, enter: test@trustcare.app
- [ ] Tap password field, enter: Test123!
- [ ] Tap "Sign In"
  - [ ] Loading state appears
  - [ ] Sign in succeeds
  - [ ] Home tab loads

#### Verify Data Persistence
- [ ] Profile tab → "My Reviews"
  - [ ] **✓ MUST SEE**: The review(s) you submitted are still there
  - [ ] Same provider name, rating, comment
  - [ ] Filter still works
- [ ] Profile tab → Avatar
  - [ ] **✓ MUST SEE**: Avatar photo persists (if uploaded)
- [ ] Profile tab → Name
  - [ ] **✓ MUST SEE**: Updated name persists
- [ ] Profile tab → Bio information
  - [ ] **✓ MUST SEE**: Bio persists

### Phase 8: Error Handling & Edge Cases
- [ ] Test network error:
  - [ ] Turn off WiFi/Airplane mode
  - [ ] Try to search for provider
  - [ ] "Network error. Please check your connection..." appears
  - [ ] Restore connection
- [ ] Test validation errors:
  - [ ] Go to write review
  - [ ] Type < 50 characters
  - [ ] Try to tap "Next"
  - [ ] Error appears: "Your review must be at least 50 characters..."
  - [ ] Red character counter shows count
- [ ] Test empty states:
  - [ ] My Reviews shows empty state if no reviews
  - [ ] "No reviews yet" message with "Write a Review" button
  - [ ] New user Home tab shows empty state or providers nearby

### Phase 9: Haptic Feedback & Animations
- [ ] Feel haptic feedback on:
  - [ ] Button taps (light vibration)
  - [ ] Provider selection (haptic on select)
  - [ ] Review submission success (confirmation vibration)
  - [ ] Error alerts (error vibration)
  - [ ] Copy referral code (tap vibration)
  - [ ] Logout confirmation (warning vibration)
- [ ] See animations on:
  - [ ] Review confirmation checkmark (smooth scale-in)
  - [ ] Skeleton card shimmer (loading cards)
  - [ ] Ratings slider updates (smooth transitions)

### Summary
- [ ] All 7 review steps work correctly
- [ ] Data persists after logout/login
- [ ] All settings pages load with correct content
- [ ] Error messages are clear and helpful
- [ ] Haptic feedback felt throughout
- [ ] No crashes or console errors
- [ ] Loading states show smoothly
- [ ] Empty states display correctly

**Notes:**
- Check Xcode console for any error messages
- Verify no warnings about deprecated APIs
- Check that all network calls complete
- Confirm data appears in Supabase Cloud dashboard
