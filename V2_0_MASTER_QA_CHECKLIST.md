# TrustCare V2.0 - Master QA Checklist
## iOS Simulator Manual Testing Guide

**Date:** February 23, 2026  
**Version:** V2.0 (5-Language Localization, AI Rehber, Dynamic Reviews)  
**Tester:** [Your Name]  
**Device:** iOS Simulator (iPhone 15 Pro recommended)

---

## Pre-Test Setup

- [ ] Launch TrustCare in iOS Simulator
- [ ] Verify app launches without crashes
- [ ] Observe initial language (should auto-detect system language)
- [ ] Grant location permissions when prompted

---

## 1. 🌍 LOCALIZATION SYSTEM TEST

### 1.1 Access Language Picker
- [ ] Tap **Profile** tab (bottom-right avatar icon)
- [ ] Tap **Settings** gear icon (top-right corner)
- [ ] Locate **Language / Dil** section
- [ ] Current language is selected (blue checkmark)

### 1.2 Test Language Switching - Turkish
- [ ] Select **Türkçe (Turkish)**
- [ ] App UI instantly refreshes (no restart required)
- [ ] **Expected Behavior:**
  - Bottom tabs: "Ana Sayfa", "Keşfet", "Değerlendir", "Rehber", "Profil"
  - Settings title: "Ayarlar"
  - Search placeholder text in Turkish

### 1.3 Test Language Switching - German
- [ ] Return to Settings → Language
- [ ] Select **Deutsch (German)**
- [ ] **Expected Behavior:**
  - Bottom tabs: "Home", "Entdecken", "Bewerten", "Berater", "Profil"
  - Specialty categories render in German (e.g., "Allgemeinmedizin")

### 1.4 Test Language Switching - Polish
- [ ] Select **Polski (Polish)**
- [ ] Navigate to **Home** tab
- [ ] Tap the **Specialty Filter** (e.g., "All Categories" dropdown)
- [ ] **Expected Behavior:**
  - Category headers like "Medicina Geral" → "Lekarz Ogólny"
  - Specialty names like "Pediatrics" → "Pediatria"

### 1.5 Test Language Switching - Dutch
- [ ] Select **Nederlands (Dutch)**
- [ ] Navigate to **Home** tab
- [ ] Open specialty filter again
- [ ] **Expected Behavior:**
  - "General Practice" → "Huisartsgeneeskunde"
  - UI labels in Dutch

### 1.6 Reset to English
- [ ] Return to Settings → Language → **English**
- [ ] Verify all UI elements back to English
- [ ] ✅ **PASS if all 5 languages switch instantly without app restart**

---

## 2. 🗺️ KEŞFET (DISCOVER) - MapKit Integration Test

### 2.1 Map Loading & Rendering
- [ ] Tap **Keşfet** (Discover) tab (second tab, map icon)
- [ ] Map loads with user location centered
- [ ] Provider pins (red markers) appear on map
- [ ] **Expected:** No infinite zoom loop
- [ ] **Expected:** No black screen or crash

### 2.2 Compact Provider Cards
- [ ] Scroll horizontally through provider cards at bottom
- [ ] Each card shows:
  - [ ] Provider photo (or placeholder)
  - [ ] Provider name
  - [ ] Specialty
  - [ ] Rating (⭐ stars)
  - [ ] Distance (e.g., "2.5 km")
- [ ] Tap a card → Map centers on that provider's pin

### 2.3 "Search This Area" Button
- [ ] Pan/zoom the map to a different region
- [ ] **Expected:** Floating "Search this area" button appears
- [ ] Tap the button
- [ ] **Expected:** 
  - Button animates (loading indicator)
  - Provider cards refresh with new results
  - Button disappears after fetch completes
- [ ] ✅ **PASS if map doesn't freeze and results load**

### 2.4 Provider Detail from Map
- [ ] Tap a provider pin on the map
- [ ] **Expected:** Callout appears with provider name
- [ ] Tap the callout (or card)
- [ ] **Expected:** Provider detail sheet opens
- [ ] Detail sheet shows full info (photo, ratings, reviews, contact)
- [ ] ✅ **PASS if detail sheet opens without crash**

---

## 3. ⭐ DEĞERLENDIR (REVIEW) - Dynamic Survey Form Test

### 3.1 Navigate to Review Hub
- [ ] Tap **Değerlendir** (Review) tab (third tab, star icon)
- [ ] Search bar appears at top
- [ ] Type "phar" or "eczane" (Turkish for pharmacy)
- [ ] Provider suggestions appear below
- [ ] Select a **Pharmacy** from results

### 3.2 Review Form Rendering - Pharmacy Survey
- [ ] Review sheet opens
- [ ] **Expected:** Exactly **4 survey questions** display:
  1. **Wait Time** ("Bekleme Süresi" or "Wait Time")
  2. **Courtesy** ("Nezaket" or "Courtesy")
  3. **Knowledge** ("Bilgi" or "Knowledge")
  4. **Environment** ("Ortam" or "Environment")
- [ ] Each question has 5 empty stars
- [ ] No extra questions like "Bedside Manner" (wrong specialty)

### 3.3 Star Rating Drag Gesture
- [ ] Long-press on the first star of **Wait Time**
- [ ] Drag horizontally across stars
- [ ] **Expected:** Stars fill as you drag (1-5 stars)
- [ ] Release at 4 stars
- [ ] **Expected:** 4 stars remain filled (golden yellow)
- [ ] Repeat for other 3 questions
- [ ] ✅ **PASS if drag gesture fills stars smoothly**

### 3.4 Photo Attachment
- [ ] Scroll to bottom of review form
- [ ] Locate "Fotoğraf Ekle" / "Add Photo" button
- [ ] Tap the button
- [ ] **Expected:** Photo picker opens (Simulator shows default photos)
- [ ] Select any photo from picker
- [ ] **Expected:** Photo thumbnail appears in form
- [ ] Tap thumbnail → Full-size preview shows
- [ ] Tap X icon → Photo removes
- [ ] ✅ **PASS if photo attaches and removes cleanly**

### 3.5 Proof Image (Optional)
- [ ] Look for "Kanıt Ekle" / "Add Proof" section (if verification enabled)
- [ ] Attach a second photo as proof
- [ ] **Expected:** Separate thumbnail for proof image

### 3.6 Submit Review
- [ ] Fill all 4 ratings (at least 1 star each)
- [ ] Optional: Write text in "Comment" field (e.g., "Great service!")
- [ ] Tap **"Gönder"** / **"Submit"** button at bottom
- [ ] **Expected:**
  - Loading spinner appears briefly
  - Success message: "Değerlendirmeniz gönderildi!" / "Review submitted!"
  - Form dismisses
  - Returns to Review Hub
- [ ] **NO DATABASE CRASH** ✅
- [ ] ✅ **PASS if review submits successfully**

---

## 4. 🤖 REHBER (GUIDE) - AI Medical Advisor Test

### 4.1 Access Rehber Tab
- [ ] Tap **Rehber** (Guide) tab (fourth tab, message bubble icon)
- [ ] **Expected:** KVKK consent screen appears (if first launch)

### 4.2 KVKK Consent Screen
- [ ] Read consent message (Turkish GDPR compliance text)
- [ ] **Expected:** Two buttons:
  - "Kabul Et" (Accept) - Primary CTA
  - "Reddet" (Decline) - Secondary
- [ ] Tap **"Kabul Et"** (Accept)
- [ ] **Expected:** Chat interface appears
- [ ] ✅ **PASS if consent screen dismisses**

### 4.3 Normal Symptom - Specialty Routing
- [ ] Type in message field: **"I have a headache"** (or Turkish: "Başım ağrıyor")
- [ ] Tap Send button (paper plane icon)
- [ ] **Expected:**
  - Message appears in chat (user bubble, right-aligned)
  - Loading indicator shows while AI processes
  - AI response appears (assistant bubble, left-aligned)
- [ ] **AI Response Should Include:**
  - Acknowledgment of symptom
  - 1-2 clarifying questions (e.g., "How long? Severity?")
  - OR specialty recommendation (e.g., "Neurology" or "Family Medicine")
- [ ] **NO emergency alert** (headache is not emergency)
- [ ] ✅ **PASS if AI responds appropriately**

### 4.4 Emergency Keyword - 112 Overlay
- [ ] In the same chat, type: **"chest pain"** (or Turkish: "göğüs ağrım var")
- [ ] Tap Send
- [ ] **Expected CRITICAL BEHAVIOR:**
  - AI detects emergency keyword
  - **Red emergency overlay** appears over chat
  - Overlay shows:
    - 🚨 Emergency icon
    - Text: "Call 112 immediately" (or Turkish equivalent)
    - Large **"Call 112"** button (red background)
    - Dismiss button (X or "Close")
- [ ] **DO NOT TAP "CALL 112"** (will dial in Simulator)
- [ ] Tap **Dismiss/Close** button
- [ ] **Expected:** Overlay dismisses, chat interface remains
- [ ] ✅ **PASS if emergency overlay triggered correctly**

### 4.5 Rehber Session Persistence
- [ ] Navigate away from Rehber tab (e.g., go to Home)
- [ ] Return to Rehber tab
- [ ] **Expected:** Chat history persists (messages still visible)
- [ ] Type another message: **"back pain"** (or Turkish: "bel ağrım")
- [ ] **Expected:** AI continues conversation context
- [ ] ✅ **PASS if session persists across tab switches**

---

## 5. 🏠 HOME TAB - Provider Search & Filters

### 5.1 Location-Based Search
- [ ] Tap **Home** tab (first tab, house icon)
- [ ] Default location shows (e.g., "Current Location" or "İzmir, Türkiye")
- [ ] Provider cards load below search bar
- [ ] ✅ **PASS if providers load without "Unable to load providers" error**

### 5.2 Specialty Filter
- [ ] Tap **"All Categories"** dropdown (or specialty filter button)
- [ ] Specialty browser sheet opens
- [ ] **Expected:** Categories are collapsible (DisclosureGroup UI)
- [ ] Expand **"General Practice"** category
- [ ] **Expected:** Specialties list:
  - "General Practice"
  - "Family Medicine"
  - "Internal Medicine"
  - "Pediatrics"
- [ ] Tap **"Pediatrics"**
- [ ] **Expected:**
  - Sheet dismisses
  - Filter badge updates to "Pediatrics"
  - Provider list refreshes (only pediatric providers)
- [ ] ✅ **PASS if filter applies correctly**

### 5.3 Search Text Query
- [ ] Tap search bar at top of Home screen
- [ ] Type **"cardio"**
- [ ] **Expected:**
  - Autocomplete suggestions appear (specialty: "Cardiology")
  - Provider suggestions appear (cardiologists)
- [ ] Tap a suggested provider
- [ ] Provider detail sheet opens
- [ ] ✅ **PASS if search autocomplete works**

### 5.4 Radius Filter
- [ ] Look for radius filter UI (e.g., "5 km", "10 km", "25 km", "50 km" chips)
- [ ] Tap **"10 km"**
- [ ] **Expected:** Provider list refreshes (only within 10 km)
- [ ] ✅ **PASS if radius filter updates results**

---

## 6. 👤 PROFILE TAB - User Settings & Data

### 6.1 Profile Screen Access
- [ ] Tap **Profile** tab (fifth tab, person icon)
- [ ] **Expected:** Profile screen shows:
  - User avatar (photo or placeholder)
  - Name (or "Guest" if not logged in)
  - Settings button (gear icon, top-right)
  - Claimed Providers section (if any)

### 6.2 Settings Menu
- [ ] Tap **Settings** gear icon
- [ ] **Expected Sections:**
  - [ ] Language / Dil (tested in Section 1)
  - [ ] Notifications
  - [ ] Privacy / KVKK
  - [ ] About / Hakkında
  - [ ] Logout / Çıkış Yap (if authenticated)

### 6.3 Logout Flow (if applicable)
- [ ] If logged in, tap **"Çıkış Yap"** / **"Logout"**
- [ ] **Expected:** Confirmation alert
- [ ] Confirm logout
- [ ] **Expected:** Returns to login/onboarding screen
- [ ] ✅ **PASS if logout clears session**

---

## 7. 🧪 EDGE CASE TESTS

### 7.1 Network Offline Mode
- [ ] Enable Airplane Mode on Simulator (Settings → Airplane Mode)
- [ ] Open TrustCare
- [ ] Navigate to Home tab
- [ ] **Expected:** Error message: "Network error. Please check your connection."
- [ ] Disable Airplane Mode
- [ ] Pull to refresh (drag down on provider list)
- [ ] **Expected:** Data loads successfully
- [ ] ✅ **PASS if offline error handled gracefully**

### 7.2 Empty Search Results
- [ ] On Home tab, search for: **"zzzxyz123"** (nonsense query)
- [ ] **Expected:** "No providers found" message
- [ ] Clear search
- [ ] **Expected:** Full provider list returns
- [ ] ✅ **PASS if empty state handled**

### 7.3 Review Without All Ratings
- [ ] On Review tab, select a provider
- [ ] Fill only 2 out of 4 ratings (leave others empty)
- [ ] Tap **Submit**
- [ ] **Expected:** Validation error: "Please rate all questions"
- [ ] Fill remaining ratings
- [ ] Tap Submit → Success
- [ ] ✅ **PASS if validation works**

---

## 8. 📊 PERFORMANCE & STABILITY

### 8.1 Memory Leaks
- [ ] Navigate through all 5 tabs 10 times rapidly
- [ ] **Expected:** No crashes, no slowdown
- [ ] ✅ **PASS if app remains responsive**

### 8.2 Map Performance
- [ ] On Keşfet tab, zoom in/out rapidly 10 times
- [ ] Pan map to different regions
- [ ] **Expected:** No freezing, no stuttering
- [ ] ✅ **PASS if map remains smooth**

### 8.3 Chat Scroll Performance
- [ ] On Rehber tab, send 20+ messages rapidly
- [ ] Scroll up and down through chat history
- [ ] **Expected:** Smooth scrolling, no lag
- [ ] ✅ **PASS if chat UI performs well**

---

## 9. ✅ FINAL VALIDATION

### 9.1 Database Integrity
- [ ] No "JSON decoding error" messages in Xcode console
- [ ] No "Unable to load providers" errors
- [ ] All specialties render with correct translations

### 9.2 Localization Coverage
- [ ] All UI labels translate in 5 languages (not just some)
- [ ] No missing translation keys (e.g., "{category_general_practice}")
- [ ] Category headers and specialty names fully localized

### 9.3 AI Rehber Functionality
- [ ] Normal symptoms route to specialties
- [ ] Emergency keywords trigger 112 overlay
- [ ] Chat persists across sessions

### 9.4 Review System
- [ ] Dynamic survey questions match provider specialty
- [ ] Photo upload/remove works
- [ ] Reviews submit without database errors

---

## 📋 TEST SUMMARY

| Module                  | Status | Notes |
|-------------------------|--------|-------|
| Localization (5 langs)  | ⬜     |       |
| Keşfet (Map)            | ⬜     |       |
| Değerlendir (Review)    | ⬜     |       |
| Rehber (AI Guide)       | ⬜     |       |
| Home (Search/Filters)   | ⬜     |       |
| Profile/Settings        | ⬜     |       |
| Edge Cases              | ⬜     |       |
| Performance/Stability   | ⬜     |       |

**Critical Bugs Found:**  
(List any P0/P1 bugs here)

**Minor Issues Found:**  
(List any P2/P3 bugs here)

**Overall QA Result:** ⬜ PASS / ⬜ FAIL

---

## 🚀 Post-QA Actions

- [ ] File any bugs found in issue tracker
- [ ] Notify team of P0 blockers
- [ ] Update deployment readiness status
- [ ] Schedule production release (if all tests pass)

---

**Tester Signature:** _______________  
**Date Completed:** _______________  
**Build Version:** V2.0 (Feb 23, 2026)
