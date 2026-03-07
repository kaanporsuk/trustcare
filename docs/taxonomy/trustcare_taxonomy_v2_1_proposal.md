# TrustCare Taxonomy v2.1 Proposal

## Locked product decisions

Two decisions are now fixed:

- **Pharmacy remains in core scope**
- **The full taxonomy launches at day one**

This means TrustCare will launch with the full v2 taxonomy breadth rather than a phased release.

## Core model

- **Specialty** = who treats the patient
- **Treatment / Procedure** = what is done
- **Facility Type** = where care happens

On top of that, TrustCare supports two search modes:

1. **Search by Symptom / Concern**
2. **Direct search by provider, specialty, treatment / procedure, or facility**

Provider and facility reviews remain **separate public trust objects**.

## Launch scope

- **84 specialties**
- **47 treatment / procedure items**
- **19 facility types**
- **19 symptom / concern domains**

### Pharmacy in core scope

Pharmacy is no longer conditional. It is part of the launch taxonomy and product scope.

Implications:
- pharmacy entities are searchable at launch
- pharmacy discovery is supported in direct search
- pharmacy can be reviewed as a facility-type entity
- pharmacy aliases such as Drugstore and Chemist should be supported where relevant

## Search architecture

### 1. Symptom / Concern AI search
User enters plain-language intent such as:
- headache
- chest pain
- anxiety
- hair loss
- fertility
- tooth pain

The AI layer maps to likely:
- specialties
- treatments / procedures
- facility types
- urgency-sensitive routing

This is **guidance, not diagnosis**.

### 2. Direct search
User searches by:
- provider name
- specialty
- treatment / procedure
- facility type
- facility name

## Review architecture

### Provider reviews
Examples of review dimensions:
- clinical expertise
- communication
- trust / confidence
- bedside manner
- clarity of explanation
- follow-up / responsiveness
- outcome satisfaction

### Facility reviews
Examples of review dimensions:
- cleanliness
- staff professionalism
- scheduling / booking
- waiting time
- organization / operations
- billing transparency
- comfort / infrastructure
- safety experience

A care episode can produce:
- one provider review
- one facility review

But there is **no merged public score**.

## Taxonomy policy

- Specialty picker shows specialties only.
- Treatment / Procedure picker shows treatments, procedures, therapies, and diagnostic services only.
- Facility Type picker shows facility types only.
- Complementary and alternative care remains searchable but should be clearly labeled and visually secondary in evidence-first ranking surfaces.
- Canonical IDs remain stable even when display labels evolve.

## Facility type additions included at launch

The facility layer is broad at launch, including:
- Hospital (General)
- Clinic / Medical Center
- Specialty Clinic
- Dental Clinic
- Imaging / Diagnostic Center
- Laboratory / Blood Tests
- Surgery Center / Day Surgery Center
- Rehabilitation / Physiotherapy Center
- Fertility / IVF Clinic
- Mental Health Clinic
- Eye Clinic
- Maternity / Women’s Health Clinic
- Telehealth / Virtual Care
- Aesthetic / Cosmetic Clinic
- Oncology Center
- Dialysis Center
- Pediatric Clinic
- Urgent Care / Walk-in Clinic
- Pharmacy

## Build priorities

1. Ship the full taxonomy at launch.
2. Complete multilingual taxonomy coverage before release.
3. Add alias coverage and symptom-to-taxonomy mapping.
4. Keep provider and facility review objects separate end-to-end.
5. Ensure pharmacy entities and reviews are first-class citizens at launch.

## Recommendation

This is the strongest launch version for TrustCare:

- broad enough to feel comprehensive
- structured enough to stay maintainable
- consumer-friendly through symptom search
- clinically precise through direct taxonomy search
- trust-preserving through separate provider and facility reviews
