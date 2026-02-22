# Prompt 8 Final QA Checklist — 22 Items

**Start Date:** ___________  
**Tester:** ___________  
**Device/Simulator:** iOS 17.6+ (Simulator: Sonoma)  
**App Version:** TrustCare (Debug build)  
**Build Date:** 2025-02-22

---

## ✅ Authentication & Session Management (4/4)

- [ ] **Email Signup:** Create new account with email + password → account created, home appears
- [ ] **Email Login:** Login with email + password → JWT stored, session active
- [ ] **Apple Sign-In:** Tap "Sign in with Apple" → consent → session created, home appears
- [ ] **Session Persistence:** Kill app, relaunch → user still logged in, no re-auth required

---

## ✅ Review Submission Pipeline (5/5)

- [ ] **Survey Form Capture:** Fill all ~20 fields → all values save to ReviewSubmissionViewModel state
- [ ] **Photo Selection:** Tap camera/photo library → select image → preview shows correct photo
- [ ] **Photo Upload + Submit:** Submit review with photo → review appears in My Reviews tab, proof_image_url populated
- [ ] **Submit Without Photo:** Submit review without photo → review appears, proof_image_url = NULL
- [ ] **Network Retry on Timeout:** Disable network → submit → shows "Ağ bağlantısı sorunu", retries 3×, then error message

---

## ✅ Provider Discovery & Location (5/5)

- [ ] **City Selector on Launch:** Open app → Home tab → LocationSelectorView sheet appears by default
- [ ] **Select City + Radius:** Choose city (e.g., "Adana"), radius (e.g., 10 km) → providers load, map centers
- [ ] **Specialty Filter:** Type specialty in search → results filter to matching providers, marker clusters update
- [ ] **Empty State:** Select city with no providers → shows "Bu bölgede henüz sağlayıcı yok..." with "Sağlayıcı Ekle" button
- [ ] **Pull-to-Refresh:** On Home list, pull down → list refreshes, timestamps update

---

## ✅ Dark Mode Support (2/2)

- [ ] **Light Trait:** Open Simulator settings → Light appearance → app renders with white cards, light backgrounds
- [ ] **Dark Trait:** Open Simulator settings → Dark appearance → app renders with dark cards, dark backgrounds

---

## ✅ UI Polish & Loading States (4/4)

- [ ] **Launch Screen:** Kill app, relaunch → blue screen with "TrustCare" title appears for ~2 seconds before app loads
- [ ] **App Icon:** On Simulator home screen → app icon shows blue shield with white checkmark (1024×1024)
- [ ] **Loading Skeletons:** Open Home → loading state shows 6 gray placeholder cards before real providers appear
- [ ] **Search Empty State:** Search for specialty with 0 results → "Sonuç bulunamadı" message appears

---

## ✅ User Profile & Data (2/2)

- [ ] **My Reviews Tab:** Navigate to Profil → My Reviews → shows all submitted reviews with filter tabs (All/Verified/Pending/Unverified)
- [ ] **Saved Providers Tab:** Navigate to Profil → Saved Providers → shows bookmarked providers, pull-to-refresh works

---

## ✅ Rehber (AI Advisor) Chat (3/3)

- [ ] **Start Chat Session:** Navigate to Rehber tab → chat interface loads with input field
- [ ] **Send Message:** Type health question (e.g., "bas ağrısı") → AI responds with recommendations/specialist suggestions
- [ ] **Emergency Flag:** Start chat with emergency toggle ON → session marks as `was_emergency = true`

---

## ✅ Permissions & Integrations (1/1)

- [ ] **Location Permission:** First launch → system dialog "Allow location access?" → tap Allow/Deny → app respects choice
- [ ] **Photos Permission (bonus):** Review tab, tap camera → system dialog → tap Allow/Deny → camera/library accessible
- [ ] **Camera Permission (bonus):** Review tab, tap camera icon → system dialog → tap Allow/Deny → camera app launches

---

## 🔍 Additional Verification (Optional)

- [ ] Check Supabase logs for any failed RLS queries (expect 0 errors)
- [ ] Verify app icon appears in app bundle: `xcrun simctl bundle list system -h | grep TrustCare` shows app icon
- [ ] Check dark mode contrast in both modes (WCAG AA minimum)
- [ ] Monitor network tab for retry attempts on submit timeout

---

## 🐛 Bug Tracker

| Issue | Date | Severity | Resolved? |
|-------|------|----------|-----------|
| | | | |
| | | | |
| | | | |

---

## 📝 Notes

```
[Free-form space for tester observations, screenshots, or additional findings]




```

---

## Sign-Off

**QA Status:** ☐ PASS | ☐ FAIL | ☐ BLOCKED

**Tester Signature:** _________________ **Date:** ________________

**Notes for Developer:**

---

**END OF QA CHECKLIST**
