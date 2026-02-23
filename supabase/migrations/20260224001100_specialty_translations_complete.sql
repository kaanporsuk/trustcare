BEGIN;

WITH translations(name, name_tr, name_de, name_pl, name_nl, name_da) AS (
  VALUES
    -- PRIMARY CARE
    ('General Practice', 'Genel Pratisyen', 'Allgemeinmedizin', 'Medycyna ogólna', 'Huisartsgeneeskunde', 'Almen medicin'),
    ('Family Medicine', 'Aile Hekimliği', 'Familienmedizin', 'Medycyna rodzinna', 'Huisartsgeneeskunde', 'Familiemedicin'),
    ('Internal Medicine', 'İç Hastalıkları', 'Innere Medizin', 'Choroby wewnętrzne', 'Interne geneeskunde', 'Intern medicin'),
    ('Pediatrics', 'Çocuk Sağlığı ve Hastalıkları', 'Kinder- und Jugendmedizin', 'Pediatria', 'Kindergeneeskunde', 'Pædiatri'),
    ('Geriatrics', 'Geriatri', 'Geriatrie', 'Geriatria', 'Geriatrie', 'Geriatri'),

    -- SURGICAL
    ('General Surgery', 'Genel Cerrahi', 'Allgemeinchirurgie', 'Chirurgia ogólna', 'Algemene chirurgie', 'Generel kirurgi'),
    ('Orthopedic Surgery', 'Ortopedi ve Travmatoloji', 'Orthopädie und Unfallchirurgie', 'Ortopedia i traumatologia', 'Orthopedie', 'Ortopædkirurgi'),
    ('Cardiovascular Surgery', 'Kalp ve Damar Cerrahisi', 'Herz- und Gefäßchirurgie', 'Kardiochirurgia', 'Hart- en vaatchirurgie', 'Hjerte- og karkirurgi'),
    ('Neurosurgery', 'Beyin ve Sinir Cerrahisi', 'Neurochirurgie', 'Neurochirurgia', 'Neurochirurgie', 'Neurokirurgi'),
    ('Plastic & Reconstructive Surgery', 'Plastik ve Rekonstrüktif Cerrahi', 'Plastische und Rekonstruktive Chirurgie', 'Chirurgia plastyczna i rekonstrukcyjna', 'Plastische en reconstructieve chirurgie', 'Plastik- og rekonstruktiv kirurgi'),
    ('Thoracic Surgery', 'Göğüs Cerrahisi', 'Thoraxchirurgie', 'Torakochirurgia', 'Thoraxchirurgie', 'Thoraxkirurgi'),
    ('Vascular Surgery', 'Damar Cerrahisi', 'Gefäßchirurgie', 'Chirurgia naczyniowa', 'Vaatchirurgie', 'Karkirurgi'),
    ('Pediatric Surgery', 'Çocuk Cerrahisi', 'Kinderchirurgie', 'Chirurgia dziecięca', 'Kinderchirurgie', 'Børnekirurgi'),
    ('Transplant Surgery', 'Organ Nakli Cerrahisi', 'Transplantationschirurgie', 'Chirurgia transplantacyjna', 'Transplantatiechirurgie', 'Transplantationskirurgi'),
    ('Bariatric Surgery', 'Bariatrik Cerrahi', 'Bariatrische Chirurgie', 'Chirurgia bariatryczna', 'Bariatrische chirurgie', 'Bariatrisk kirurgi'),

    -- MEDICAL SPECIALTIES
    ('Cardiology', 'Kardiyoloji', 'Kardiologie', 'Kardiologia', 'Cardiologie', 'Kardiologi'),
    ('Dermatology', 'Dermatoloji', 'Dermatologie', 'Dermatologia', 'Dermatologie', 'Dermatologi'),
    ('Endocrinology', 'Endokrinoloji', 'Endokrinologie', 'Endokrynologia', 'Endocrinologie', 'Endokrinologi'),
    ('Gastroenterology', 'Gastroenteroloji', 'Gastroenterologie', 'Gastroenterologia', 'Gastro-enterologie', 'Gastroenterologi'),
    ('Hematology', 'Hematoloji', 'Hämatologie', 'Hematologia', 'Hematologie', 'Hæmatologi'),
    ('Infectious Disease', 'Enfeksiyon Hastalıkları', 'Infektiologie', 'Choroby zakaźne', 'Infectieziekten', 'Infektionsmedicin'),
    ('Nephrology', 'Nefroloji', 'Nephrologie', 'Nefrologia', 'Nefrologie', 'Nefrologi'),
    ('Neurology', 'Nöroloji', 'Neurologie', 'Neurologia', 'Neurologie', 'Neurologi'),
    ('Oncology', 'Onkoloji', 'Onkologie', 'Onkologia', 'Oncologie', 'Onkologi'),
    ('Pulmonology', 'Göğüs Hastalıkları', 'Pneumologie', 'Pulmonologia', 'Longziekten', 'Lungemedicin'),
    ('Rheumatology', 'Romatoloji', 'Rheumatologie', 'Reumatologia', 'Reumatologie', 'Reumatologi'),
    ('Allergy & Immunology', 'Alerji ve İmmünoloji', 'Allergologie und Immunologie', 'Alergologia i immunologia', 'Allergologie en immunologie', 'Allergologi og immunologi'),
    ('Sports Medicine', 'Spor Hekimliği', 'Sportmedizin', 'Medycyna sportowa', 'Sportgeneeskunde', 'Idrætsmedicin'),
    ('Pain Management', 'Ağrı Yönetimi', 'Schmerzmedizin', 'Leczenie bólu', 'Pijngeneeskunde', 'Smertebehandling'),
    ('Sleep Medicine', 'Uyku Tıbbı', 'Schlafmedizin', 'Medycyna snu', 'Slaapgeneeskunde', 'Søvnmedicin'),

    -- WOMEN''S HEALTH
    ('Obstetrics & Gynecology', 'Kadın Hastalıkları ve Doğum', 'Gynäkologie und Geburtshilfe', 'Ginekologia i położnictwo', 'Gynaecologie en verloskunde', 'Obstetrik og gynækologi'),
    ('Reproductive Endocrinology / IVF', 'Üreme Endokrinolojisi ve Tüp Bebek', 'Reproduktionsendokrinologie und IVF', 'Endokrynologia rozrodu i IVF', 'Reproductieve endocrinologie en IVF', 'Reproduktiv endokrinologi og IVF'),
    ('Maternal-Fetal Medicine', 'Perinatoloji', 'Pränatalmedizin', 'Medycyna matczyno-płodowa', 'Materno-foetale geneeskunde', 'Maternel-føtal medicin'),
    ('Breast Surgery', 'Meme Cerrahisi', 'Brustchirurgie', 'Chirurgia piersi', 'Borstchirurgie', 'Brystkirurgi'),
    ('Urogynecology', 'Ürojinekoloji', 'Urogynäkologie', 'Uroginekologia', 'Urogynaecologie', 'Urogynækologi'),

    -- DENTAL
    ('General Dentistry', 'Genel Diş Hekimliği', 'Allgemeine Zahnheilkunde', 'Stomatologia ogólna', 'Algemene tandheelkunde', 'Almen tandpleje'),
    ('Orthodontics', 'Ortodonti', 'Kieferorthopädie', 'Ortodoncja', 'Orthodontie', 'Ortodonti'),
    ('Oral Surgery', 'Ağız Cerrahisi', 'Oralchirurgie', 'Chirurgia jamy ustnej', 'Mondchirurgie', 'Oralkirurgi'),
    ('Endodontics', 'Endodonti', 'Endodontie', 'Endodoncja', 'Endodontologie', 'Endodonti'),
    ('Periodontics', 'Periodontoloji', 'Parodontologie', 'Periodontologia', 'Parodontologie', 'Parodontologi'),
    ('Prosthodontics', 'Protetik Diş Tedavisi', 'Prothetik', 'Protetyka stomatologiczna', 'Prothetische tandheelkunde', 'Protetik'),
    ('Pediatric Dentistry', 'Çocuk Diş Hekimliği', 'Kinderzahnheilkunde', 'Stomatologia dziecięca', 'Kindertandheelkunde', 'Børnetandpleje'),
    ('Cosmetic Dentistry', 'Kozmetik Diş Hekimliği', 'Ästhetische Zahnheilkunde', 'Stomatologia estetyczna', 'Cosmetische tandheelkunde', 'Kosmetisk tandpleje'),

    -- EYE CARE
    ('Ophthalmology', 'Göz Hastalıkları', 'Augenheilkunde', 'Okulistyka', 'Oogheelkunde', 'Øjensygdomme'),
    ('LASIK / Refractive Surgery', 'LASIK / Refraktif Cerrahi', 'LASIK / Refraktive Chirurgie', 'LASIK / Chirurgia refrakcyjna', 'LASIK / Refractieve chirurgie', 'LASIK / Refraktiv kirurgi'),
    ('Retina Specialist', 'Retina Hastalıkları', 'Retinologie', 'Choroby siatkówki', 'Retinaziekten', 'Nethindelidelser'),
    ('Pediatric Ophthalmology', 'Çocuk Göz Hastalıkları', 'Kinderophthalmologie', 'Okulistyka dziecięca', 'Kinderoogheelkunde', 'Børneøjensygdomme'),
    ('Optometry', 'Optometri', 'Optometrie', 'Optometria', 'Optometrie', 'Optometri'),

    -- ENT
    ('ENT / Otolaryngology', 'Kulak Burun Boğaz', 'Hals-Nasen-Ohrenheilkunde', 'Otorynolaryngologia', 'Keel-, neus- en oorheelkunde', 'Øre-næse-hals-sygdomme'),
    ('Audiology', 'Odyoloji', 'Audiologie', 'Audiologia', 'Audiologie', 'Audiologi'),
    ('Head & Neck Surgery', 'Baş ve Boyun Cerrahisi', 'Kopf- und Halschirurgie', 'Chirurgia głowy i szyi', 'Hoofd-halschirurgie', 'Hoved- og halskirurgi'),
    ('Rhinology', 'Rinoloji', 'Rhinologie', 'Rynologia', 'Rhinologie', 'Rinologi'),

    -- MENTAL HEALTH
    ('Psychiatry', 'Psikiyatri', 'Psychiatrie', 'Psychiatria', 'Psychiatrie', 'Psykiatri'),
    ('Psychology / Therapy', 'Psikoloji ve Psikoterapi', 'Psychologie und Psychotherapie', 'Psychologia i psychoterapia', 'Psychologie en psychotherapie', 'Psykologi og terapi'),
    ('Child & Adolescent Psychiatry', 'Çocuk ve Ergen Psikiyatrisi', 'Kinder- und Jugendpsychiatrie', 'Psychiatria dzieci i młodzieży', 'Kinder- en jeugdpsychiatrie', 'Børne- og ungdomspsykiatri'),
    ('Addiction Medicine', 'Bağımlılık Tedavisi', 'Suchtmedizin', 'Medycyna uzależnień', 'Verslavingsgeneeskunde', 'Misbrugsmedicin'),
    ('Neuropsychology', 'Nöropsikoloji', 'Neuropsychologie', 'Neuropsychologia', 'Neuropsychologie', 'Neuropsykologi'),

    -- UROLOGY
    ('Urology', 'Üroloji', 'Urologie', 'Urologia', 'Urologie', 'Urologi'),
    ('Andrology', 'Androloji', 'Andrologie', 'Andrologia', 'Andrologie', 'Andrologi'),
    ('Pediatric Urology', 'Çocuk Ürolojisi', 'Kinderurologie', 'Urologia dziecięca', 'Kinderurologie', 'Pædiatrisk urologi'),

    -- REHABILITATION
    ('Physical Therapy / Physiotherapy', 'Fizyoterapi', 'Physiotherapie', 'Fizjoterapia', 'Fysiotherapie', 'Fysioterapi'),
    ('Occupational Therapy', 'Ergoterapi', 'Ergotherapie', 'Terapia zajęciowa', 'Ergotherapie', 'Ergoterapi'),
    ('Speech Therapy', 'Konuşma ve Dil Terapisi', 'Logopädie', 'Logopedia', 'Logopedie', 'Logopædi'),
    ('Chiropractic', 'Kayropraktik', 'Chiropraktik', 'Chiropraktyka', 'Chiropractie', 'Kiropraktik'),
    ('Physical Medicine & Rehab', 'Fiziksel Tıp ve Rehabilitasyon', 'Physikalische Medizin und Rehabilitation', 'Medycyna fizykalna i rehabilitacja', 'Revalidatiegeneeskunde', 'Fysisk medicin og rehabilitering'),

    -- AESTHETIC & COSMETIC
    ('Aesthetic Medicine', 'Medikal Estetik', 'Ästhetische Medizin', 'Medycyna estetyczna', 'Esthetische geneeskunde', 'Æstetisk medicin'),
    ('Botox & Fillers', 'Botoks ve Dolgu', 'Botox und Filler', 'Botoks i wypełniacze', 'Botox en fillers', 'Botox og fillers'),
    ('Hair Transplant', 'Saç Ekimi', 'Haartransplantation', 'Przeszczep włosów', 'Haartransplantatie', 'Hårtransplantation'),
    ('Liposuction & Body Contouring', 'Liposuction ve Vücut Konturlama', 'Liposuktion und Körperkonturierung', 'Liposukcja i modelowanie sylwetki', 'Liposuctie en lichaamscontouring', 'Fedtsugning og kropskonturering'),
    ('Rhinoplasty', 'Rinoplasti', 'Rhinoplastik', 'Rynoplastyka', 'Rhinoplastiek', 'Rhinoplastik'),
    ('Facelift & Neck Lift', 'Yüz Germe ve Boyun Germe', 'Facelifting und Halsstraffung', 'Lifting twarzy i szyi', 'Facelift en halslift', 'Ansigtsløft og halsløft'),
    ('Breast Augmentation / Reduction', 'Meme Büyütme / Küçültme', 'Brustvergrößerung / Brustverkleinerung', 'Powiększanie / redukcja piersi', 'Borstvergroting / borstverkleining', 'Brystforstørrelse / brystreduktion'),
    ('Laser Treatments', 'Lazer Tedavileri', 'Laserbehandlungen', 'Zabiegi laserowe', 'Laserbehandelingen', 'Laserbehandlinger'),
    ('Chemical Peels & Microneedling', 'Kimyasal Peeling ve Mikroiğneleme', 'Chemische Peelings und Microneedling', 'Peelingi chemiczne i mikronakłuwanie', 'Chemische peelings en microneedling', 'Kemiske peelinger og microneedling'),
    ('Eyelid Surgery', 'Göz Kapağı Cerrahisi', 'Lidchirurgie', 'Chirurgia powiek', 'Ooglidchirurgie', 'Øjenlågskirurgi'),
    ('Tummy Tuck', 'Karın Germe', 'Bauchdeckenstraffung', 'Plastyka brzucha', 'Buikwandcorrectie', 'Maveplastik'),
    ('Lip Enhancement', 'Dudak Dolgunlaştırma', 'Lippenaugmentation', 'Powiększanie ust', 'Lipvergroting', 'Læbeforstørrelse'),
    ('Skin Rejuvenation / PRP', 'Cilt Gençleştirme / PRP', 'Hautverjüngung / PRP', 'Odmładzanie skóry / PRP', 'Huidverjonging / PRP', 'Hudforyngelse / PRP'),
    ('Tattoo Removal', 'Dövme Silme', 'Tattooentfernung', 'Usuwanie tatuażu', 'Tatoeageverwijdering', 'Fjernelse af tatovering'),
    ('Dental Aesthetics (Smile Design)', 'Diş Estetiği (Gülüş Tasarımı)', 'Ästhetische Zahnmedizin (Smile Design)', 'Stomatologia estetyczna (projektowanie uśmiechu)', 'Esthetische tandheelkunde (smile design)', 'Æstetisk tandpleje (smile design)'),

    -- DIAGNOSTIC
    ('Radiology', 'Radyoloji', 'Radiologie', 'Radiologia', 'Radiologie', 'Radiologi'),
    ('Pathology', 'Patoloji', 'Pathologie', 'Patomorfologia', 'Pathologie', 'Patologi'),
    ('Nuclear Medicine', 'Nükleer Tıp', 'Nuklearmedizin', 'Medycyna nuklearna', 'Nucleaire geneeskunde', 'Nuklearmedicin'),
    ('Laboratory / Blood Tests', 'Laboratuvar ve Kan Testleri', 'Labor und Bluttests', 'Laboratorium i analizy krwi', 'Laboratorium en bloedtests', 'Laboratorium og blodprøver'),

    -- EMERGENCY & URGENT CARE
    ('Emergency Medicine', 'Acil Tıp', 'Notfallmedizin', 'Medycyna ratunkowa', 'Spoedeisende geneeskunde', 'Akutmedicin'),
    ('Urgent Care / Walk-in Clinic', 'Acil Poliklinik', 'Notfallpraxis', 'Pomoc doraźna', 'Huisartsenpost', 'Akutklinik'),
    ('Trauma Surgery', 'Travma Cerrahisi', 'Unfallchirurgie', 'Chirurgia urazowa', 'Traumachirurgie', 'Traumekirurgi'),

    -- ALTERNATIVE & COMPLEMENTARY
    ('Acupuncture', 'Akupunktur', 'Akupunktur', 'Akupunktura', 'Acupunctuur', 'Akupunktur'),
    ('Homeopathy', 'Homeopati', 'Homöopathie', 'Homeopatia', 'Homeopathie', 'Homøopati'),
    ('Naturopathy', 'Natüropati', 'Naturheilkunde', 'Naturopatia', 'Naturopathie', 'Naturopati'),
    ('Traditional Chinese Medicine', 'Geleneksel Çin Tıbbı', 'Traditionelle Chinesische Medizin', 'Tradycyjna medycyna chińska', 'Traditionele Chinese geneeskunde', 'Traditionel kinesisk medicin'),
    ('Osteopathy', 'Osteopati', 'Osteopathie', 'Osteopatia', 'Osteopathie', 'Osteopati'),

    -- STANDALONE / OTHER
    ('Pharmacy', 'Eczane', 'Apotheke', 'Apteka', 'Apotheek', 'Apotek'),
    ('Hospital (General)', 'Hastane (Genel)', 'Krankenhaus (allgemein)', 'Szpital (ogólny)', 'Ziekenhuis (algemeen)', 'Hospital (generelt)'),
    ('Nutrition & Dietetics', 'Beslenme ve Diyetetik', 'Ernährungsmedizin und Diätetik', 'Dietetyka', 'Diëtetiek', 'Ernæring og diætetik'),
    ('Podiatry', 'Podoloji', 'Podologie', 'Podologia', 'Podologie', 'Podologi'),
    ('Genetics & Genomics', 'Genetik ve Genomik', 'Humangenetik', 'Genetyka', 'Klinische genetica', 'Klinisk genetik'),
    ('Palliative Care', 'Palyatif Bakım', 'Palliativmedizin', 'Opieka paliatywna', 'Palliatieve zorg', 'Palliativ behandling'),
    ('Wound Care', 'Yara Bakımı', 'Wundversorgung', 'Leczenie ran', 'Wondverzorging', 'Sårpleje')
)
UPDATE specialties AS s
SET
  name_tr = t.name_tr,
  name_de = t.name_de,
  name_pl = t.name_pl,
  name_nl = t.name_nl,
  name_da = t.name_da
FROM translations AS t
WHERE s.name = t.name;

DO $$
DECLARE
  missing_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO missing_count
  FROM specialties
  WHERE name_tr IS NULL
     OR name_de IS NULL
     OR name_pl IS NULL
     OR name_nl IS NULL
     OR name_da IS NULL;

  IF missing_count > 0 THEN
    RAISE EXCEPTION 'Specialty translation migration incomplete. Missing rows: %', missing_count;
  END IF;
END $$;

COMMIT;
