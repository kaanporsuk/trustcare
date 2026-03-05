## TrustCare Master Build Instructions

These instructions govern the "Living Trust + Dynamic Intelligence" redesign across the TrustCare iOS app and Supabase backend.

### Scope and stack

- Primary app: SwiftUI iOS (iOS 17+).
- Backend: Supabase Cloud.
- Redesign covers colors, typography, components, screens, states, and edge-case behavior.
- These rules apply only to the `TrustCare/` app and its related `supabase/` project in this repository.
- These rules do not apply to `admin/` or to any other Git or Supabase project.

### Session-start project verification (required)

- At every single session start (maximum daily), verify you are connected to the correct Git and Supabase Cloud projects, and verify you can deploy updates to live.

### Global constraints (must not be violated)

1. Preserve core logic.
- Keep taxonomy/ontology search flows functional.
- Keep existing Supabase calls (`rpc`, `from`, `select`) functional.
- Preserve localization keys and view model state behavior.

2. Use one token system.
- Do not introduce token aliasing.
- Maintain one canonical color and typography system.
- Migrate old token names via direct replacement.

3. Accessibility is required.
- Support Dynamic Type.
- Provide Reduce Transparency fallbacks where material effects are used.
- Add VoiceOver labels for pins, cards, and primary CTAs.

4. Performance safeguards are required.
- Use stable IDs for lists and map annotations.
- Avoid map/list selection feedback loops.
- Debounce search and map-pan triggered searches.

5. Build for launch reality.
- Assume no imported ratings.
- Handle many providers with 0 reviews.
- Handle sparse city/area coverage.
- Handle missing coordinates safely.

### Supabase safety

- Do not introduce breaking schema or RPC changes unless explicitly requested in the active phase.
- Keep existing database integration behavior backward compatible by default.

### Workflow protocol

- Execute one phase at a time.
- After each phase, run:

```sh
xcodebuild -scheme TrustCare -destination 'platform=iOS Simulator,name=iPhone 15' build
```

- Create exactly one commit per phase:

```sh
git add -A
git commit -m "<message>"
```

- Stop after each phase and report:
- Short summary of files changed.
- Confirmation that the build succeeded.

### Collaboration behavior for this project

- If a requested change conflicts with these constraints, call out the conflict and propose a compliant alternative.
- Prefer minimal, surgical edits that preserve existing business logic.
- Do not perform cross-phase work unless explicitly requested.
