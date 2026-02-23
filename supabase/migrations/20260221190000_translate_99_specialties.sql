-- Translate all 99 specialties across Turkish, German, Polish, Dutch

-- General Practice (4)
UPDATE specialties SET nameTr = 'Genel Muayene' WHERE name = 'General Consultation';
UPDATE specialties SET nameDe = 'Allgemeine Konsultation' WHERE name = 'General Consultation';
UPDATE specialties SET namePl = 'Konsultacja ogólna' WHERE name = 'General Consultation';
UPDATE specialties SET nameNl = 'Algemeen consult' WHERE name = 'General Consultation';

UPDATE specialties SET nameTr = 'Koruyucu Sağlık' WHERE name = 'Preventive Care';
UPDATE specialties SET nameDe = 'Vorsorgeuntersuchung' WHERE name = 'Preventive Care';
UPDATE specialties SET namePl = 'Opieka profilaktyczna' WHERE name = 'Preventive Care';
UPDATE specialties SET nameNl = 'Preventieve zorg' WHERE name = 'Preventive Care';

UPDATE specialties SET nameTr = 'Kronik Hastalık Yönetimi' WHERE name = 'Chronic Disease Management';
UPDATE specialties SET nameDe = 'Chronische Erkrankungsverwaltung' WHERE name = 'Chronic Disease Management';
UPDATE specialties SET namePl = 'Zarządzanie chorobą przewlekłą' WHERE name = 'Chronic Disease Management';
UPDATE specialties SET nameNl = 'Beheer van chronische ziekten' WHERE name = 'Chronic Disease Management';

UPDATE specialties SET nameTr = 'Akut Hastalık Tedavisi' WHERE name = 'Acute Illness Treatment';
UPDATE specialties SET nameDe = 'Akute Erkrankungsbehandlung' WHERE name = 'Acute Illness Treatment';
UPDATE specialties SET namePl = 'Leczenie ostrej choroby' WHERE name = 'Acute Illness Treatment';
UPDATE specialties SET nameNl = 'Behandeling van acute ziekte' WHERE name = 'Acute Illness Treatment';

-- Cardiology (4)
UPDATE specialties SET nameTr = 'Kalp Ritim Bozukluğu' WHERE name = 'Arrhythmia';
UPDATE specialties SET nameDe = 'Herzrhythmusstörung' WHERE name = 'Arrhythmia';
UPDATE specialties SET namePl = 'Arytmia' WHERE name = 'Arrhythmia';
UPDATE specialties SET nameNl = 'Hartritmestoornissen' WHERE name = 'Arrhythmia';

UPDATE specialties SET nameTr = 'Kalp Yetmezliği' WHERE name = 'Heart Failure';
UPDATE specialties SET nameDe = 'Herzinsuffizienz' WHERE name = 'Heart Failure';
UPDATE specialties SET namePl = 'Niewydolność serca' WHERE name = 'Heart Failure';
UPDATE specialties SET nameNl = 'Hartfalen' WHERE name = 'Heart Failure';

UPDATE specialties SET nameTr = 'Koroner Arter Hastalığı' WHERE name = 'Coronary Artery Disease';
UPDATE specialties SET nameDe = 'Koronare Herzkrankheit' WHERE name = 'Coronary Artery Disease';
UPDATE specialties SET namePl = 'Choroba wieńcowa serca' WHERE name = 'Coronary Artery Disease';
UPDATE specialties SET nameNl = 'Coronairlijden' WHERE name = 'Coronary Artery Disease';

UPDATE specialties SET nameTr = 'Hipertansiyon' WHERE name = 'Hypertension';
UPDATE specialties SET nameDe = 'Bluthochdruck' WHERE name = 'Hypertension';
UPDATE specialties SET namePl = 'Nadciśnienie' WHERE name = 'Hypertension';
UPDATE specialties SET nameNl = 'Hypertensie' WHERE name = 'Hypertension';

-- Dermatology (4)
UPDATE specialties SET nameTr = 'Akne' WHERE name = 'Acne';
UPDATE specialties SET nameDe = 'Akne' WHERE name = 'Acne';
UPDATE specialties SET namePl = 'Trądzik' WHERE name = 'Acne';
UPDATE specialties SET nameNl = 'Acne' WHERE name = 'Acne';

UPDATE specialties SET nameTr = 'Egzema' WHERE name = 'Eczema';
UPDATE specialties SET nameDe = 'Ekzem' WHERE name = 'Eczema';
UPDATE specialties SET namePl = 'Egzema' WHERE name = 'Eczema';
UPDATE specialties SET nameNl = 'Eczeem' WHERE name = 'Eczema';

UPDATE specialties SET nameTr = 'Psoriasis' WHERE name = 'Psoriasis';
UPDATE specialties SET nameDe = 'Schuppenflechte' WHERE name = 'Psoriasis';
UPDATE specialties SET namePl = 'Psoriaza' WHERE name = 'Psoriasis';
UPDATE specialties SET nameNl = 'Psoriasis' WHERE name = 'Psoriasis';

UPDATE specialties SET nameTr = 'Cilt Kanseri Taraması' WHERE name = 'Skin Cancer Screening';
UPDATE specialties SET nameDe = 'Hautkrebs-Screening' WHERE name = 'Skin Cancer Screening';
UPDATE specialties SET namePl = 'Przesiewowe badanie raka skóry' WHERE name = 'Skin Cancer Screening';
UPDATE specialties SET nameNl = 'Screening huidkanker' WHERE name = 'Skin Cancer Screening';

-- Pediatrics (4)
UPDATE specialties SET nameTr = 'Bebek Bakımı' WHERE name = 'Infant Care';
UPDATE specialties SET nameDe = 'Säuglingspflege' WHERE name = 'Infant Care';
UPDATE specialties SET namePl = 'Opieka nad niemowlęciami' WHERE name = 'Infant Care';
UPDATE specialties SET nameNl = 'Zuigelingenzorg' WHERE name = 'Infant Care';

UPDATE specialties SET nameTr = 'Çocuk Gelişimi' WHERE name = 'Child Development';
UPDATE specialties SET nameDe = 'Kindliche Entwicklung' WHERE name = 'Child Development';
UPDATE specialties SET namePl = 'Rozwój dziecka' WHERE name = 'Child Development';
UPDATE specialties SET nameNl = 'Kinderontwikkeling' WHERE name = 'Child Development';

UPDATE specialties SET nameTr = 'Aşılama' WHERE name = 'Vaccination';
UPDATE specialties SET nameDe = 'Impfung' WHERE name = 'Vaccination';
UPDATE specialties SET namePl = 'Szczepienie' WHERE name = 'Vaccination';
UPDATE specialties SET nameNl = 'Vaccinatie' WHERE name = 'Vaccination';

UPDATE specialties SET nameTr = 'Çocukluk Dönemi Hastalıkları' WHERE name = 'Childhood Illness';
UPDATE specialties SET nameDe = 'Kinderkrankheiten' WHERE name = 'Childhood Illness';
UPDATE specialties SET namePl = 'Choroby dziecięce' WHERE name = 'Childhood Illness';
UPDATE specialties SET nameNl = 'Kinderziekte' WHERE name = 'Childhood Illness';

-- Orthopedics (4)
UPDATE specialties SET nameTr = 'Kırık Tedavisi' WHERE name = 'Fracture Treatment';
UPDATE specialties SET nameDe = 'Frakturbehandlung' WHERE name = 'Fracture Treatment';
UPDATE specialties SET namePl = 'Leczenie złamań' WHERE name = 'Fracture Treatment';
UPDATE specialties SET nameNl = 'Fractuurbehandeling' WHERE name = 'Fracture Treatment';

UPDATE specialties SET nameTr = 'Eklem Protezi' WHERE name = 'Joint Replacement';
UPDATE specialties SET nameDe = 'Gelenkersatz' WHERE name = 'Joint Replacement';
UPDATE specialties SET namePl = 'Wymiana stawu' WHERE name = 'Joint Replacement';
UPDATE specialties SET nameNl = 'Gewrichtsvervanging' WHERE name = 'Joint Replacement';

UPDATE specialties SET nameTr = 'Spor Hekimliği' WHERE name = 'Sports Medicine';
UPDATE specialties SET nameDe = 'Sportmedizin' WHERE name = 'Sports Medicine';
UPDATE specialties SET namePl = 'Medycyna sportowa' WHERE name = 'Sports Medicine';
UPDATE specialties SET nameNl = 'Sportgeneeskunde' WHERE name = 'Sports Medicine';

UPDATE specialties SET nameTr = 'Omurga Cerrahisi' WHERE name = 'Spine Surgery';
UPDATE specialties SET nameDe = 'Wirbelsäulenchirurgie' WHERE name = 'Spine Surgery';
UPDATE specialties SET namePl = 'Chirurgia kręgosłupa' WHERE name = 'Spine Surgery';
UPDATE specialties SET nameNl = 'Ruggegraat chirurgie' WHERE name = 'Spine Surgery';

-- Neurology (4)
UPDATE specialties SET nameTr = 'Başağrısı' WHERE name = 'Headache';
UPDATE specialties SET nameDe = 'Kopfschmerz' WHERE name = 'Headache';
UPDATE specialties SET namePl = 'Ból głowy' WHERE name = 'Headache';
UPDATE specialties SET nameNl = 'Hoofdpijn' WHERE name = 'Headache';

UPDATE specialties SET nameTr = 'İnme' WHERE name = 'Stroke';
UPDATE specialties SET nameDe = 'Schlaganfall' WHERE name = 'Stroke';
UPDATE specialties SET namePl = 'Udar mózgu' WHERE name = 'Stroke';
UPDATE specialties SET nameNl = 'Beroerte' WHERE name = 'Stroke';

UPDATE specialties SET nameTr = 'Hareket Bozuklukları' WHERE name = 'Movement Disorders';
UPDATE specialties SET nameDe = 'Bewegungsstörungen' WHERE name = 'Movement Disorders';
UPDATE specialties SET namePl = 'Zaburzenia ruchu' WHERE name = 'Movement Disorders';
UPDATE specialties SET nameNl = 'Bewegingsstoornissen' WHERE name = 'Movement Disorders';

UPDATE specialties SET nameTr = 'Demans' WHERE name = 'Dementia';
UPDATE specialties SET nameDe = 'Demenz' WHERE name = 'Dementia';
UPDATE specialties SET namePl = 'Demencja' WHERE name = 'Dementia';
UPDATE specialties SET nameNl = 'Dementie' WHERE name = 'Dementia';

-- Psychiatry (4)
UPDATE specialties SET nameTr = 'Depresyon' WHERE name = 'Depression';
UPDATE specialties SET nameDe = 'Depression' WHERE name = 'Depression';
UPDATE specialties SET namePl = 'Depresja' WHERE name = 'Depression';
UPDATE specialties SET nameNl = 'Depressie' WHERE name = 'Depression';

UPDATE specialties SET nameTr = 'Anksiyete' WHERE name = 'Anxiety';
UPDATE specialties SET nameDe = 'Angststörung' WHERE name = 'Anxiety';
UPDATE specialties SET namePl = 'Lęk' WHERE name = 'Anxiety';
UPDATE specialties SET nameNl = 'Angststoornis' WHERE name = 'Anxiety';

UPDATE specialties SET nameTr = 'Bipolar Bozukluk' WHERE name = 'Bipolar Disorder';
UPDATE specialties SET nameDe = 'Bipolare Störung' WHERE name = 'Bipolar Disorder';
UPDATE specialties SET namePl = 'Zaburzenie dwubiegunowe' WHERE name = 'Bipolar Disorder';
UPDATE specialties SET nameNl = 'Bipolaire stoornis' WHERE name = 'Bipolar Disorder';

UPDATE specialties SET nameTr = 'Şizofreni' WHERE name = 'Schizophrenia';
UPDATE specialties SET nameDe = 'Schizophrenie' WHERE name = 'Schizophrenia';
UPDATE specialties SET namePl = 'Schizofrenia' WHERE name = 'Schizophrenia';
UPDATE specialties SET nameNl = 'Schizofrenie' WHERE name = 'Schizophrenia';

-- Oncology (4)
UPDATE specialties SET nameTr = 'Kemoterapi' WHERE name = 'Chemotherapy';
UPDATE specialties SET nameDe = 'Chemotherapie' WHERE name = 'Chemotherapy';
UPDATE specialties SET namePl = 'Chemioterapia' WHERE name = 'Chemotherapy';
UPDATE specialties SET nameNl = 'Chemotherapie' WHERE name = 'Chemotherapy';

UPDATE specialties SET nameTr = 'Radyoterapi' WHERE name = 'Radiation Therapy';
UPDATE specialties SET nameDe = 'Strahlentherapie' WHERE name = 'Radiation Therapy';
UPDATE specialties SET namePl = 'Radioterapia' WHERE name = 'Radiation Therapy';
UPDATE specialties SET nameNl = 'Radiotherapie' WHERE name = 'Radiation Therapy';

UPDATE specialties SET nameTr = 'Cerrahi Onkoloji' WHERE name = 'Surgical Oncology';
UPDATE specialties SET nameDe = 'Chirurgische Onkologie' WHERE name = 'Surgical Oncology';
UPDATE specialties SET namePl = 'Onkologia chirurgiczna' WHERE name = 'Surgical Oncology';
UPDATE specialties SET nameNl = 'Chirurgische oncologie' WHERE name = 'Surgical Oncology';

UPDATE specialties SET nameTr = 'Palyatif Bakım' WHERE name = 'Palliative Care';
UPDATE specialties SET nameDe = 'Palliativpflege' WHERE name = 'Palliative Care';
UPDATE specialties SET namePl = 'Opieka paliatywna' WHERE name = 'Palliative Care';
UPDATE specialties SET nameNl = 'Palliatieve zorg' WHERE name = 'Palliative Care';

-- Gastroenterology (4)
UPDATE specialties SET nameTr = 'İnflamatuar Bağırsak Hastalığı' WHERE name = 'Inflammatory Bowel Disease';
UPDATE specialties SET nameDe = 'Entzündliche Darmerkrankung' WHERE name = 'Inflammatory Bowel Disease';
UPDATE specialties SET namePl = 'Zapalenie jelit' WHERE name = 'Inflammatory Bowel Disease';
UPDATE specialties SET nameNl = 'Ontstekingsziekten van de darm' WHERE name = 'Inflammatory Bowel Disease';

UPDATE specialties SET nameTr = 'Karaciğer Hastalığı' WHERE name = 'Liver Disease';
UPDATE specialties SET nameDe = 'Lebererkrankung' WHERE name = 'Liver Disease';
UPDATE specialties SET namePl = 'Choroba wątroby' WHERE name = 'Liver Disease';
UPDATE specialties SET nameNl = 'Leverziekte' WHERE name = 'Liver Disease';

UPDATE specialties SET nameTr = 'Peptik Ülser' WHERE name = 'Peptic Ulcer';
UPDATE specialties SET nameDe = 'Magengeschwür' WHERE name = 'Peptic Ulcer';
UPDATE specialties SET namePl = 'Wrząd żołądkowy' WHERE name = 'Peptic Ulcer';
UPDATE specialties SET nameNl = 'Maagzweer' WHERE name = 'Peptic Ulcer';

UPDATE specialties SET nameTr = 'Endoskopi' WHERE name = 'Endoscopy';
UPDATE specialties SET nameDe = 'Endoskopie' WHERE name = 'Endoscopy';
UPDATE specialties SET namePl = 'Endoskopia' WHERE name = 'Endoscopy';
UPDATE specialties SET nameNl = 'Endoscopie' WHERE name = 'Endoscopy';

-- Pulmonology (4)
UPDATE specialties SET nameTr = 'Asma' WHERE name = 'Asthma';
UPDATE specialties SET nameDe = 'Asthma' WHERE name = 'Asthma';
UPDATE specialties SET namePl = 'Astma' WHERE name = 'Asthma';
UPDATE specialties SET nameNl = 'Astma' WHERE name = 'Asthma';

UPDATE specialties SET nameTr = 'KOAH' WHERE name = 'COPD';
UPDATE specialties SET nameDe = 'COPD' WHERE name = 'COPD';
UPDATE specialties SET namePl = 'POChP' WHERE name = 'COPD';
UPDATE specialties SET nameNl = 'COPD' WHERE name = 'COPD';

UPDATE specialties SET nameTr = 'İnterstisyal Akciğer Hastalığı' WHERE name = 'Interstitial Lung Disease';
UPDATE specialties SET nameDe = 'Interstitielle Lungenerkrankung' WHERE name = 'Interstitial Lung Disease';
UPDATE specialties SET namePl = 'Śródmiąższowe choroby płuc' WHERE name = 'Interstitial Lung Disease';
UPDATE specialties SET nameNl = 'Interstitiële longziekte' WHERE name = 'Interstitial Lung Disease';

UPDATE specialties SET nameTr = 'Uyku Apnesi' WHERE name = 'Sleep Apnea';
UPDATE specialties SET nameDe = 'Schlafapnoe' WHERE name = 'Sleep Apnea';
UPDATE specialties SET namePl = 'Bezsenność' WHERE name = 'Sleep Apnea';
UPDATE specialties SET nameNl = 'Slaapapneu' WHERE name = 'Sleep Apnea';

-- Urology (4)
UPDATE specialties SET nameTr = 'Prostat Hastalığı' WHERE name = 'Prostate Disease';
UPDATE specialties SET nameDe = 'Prostataerkrankung' WHERE name = 'Prostate Disease';
UPDATE specialties SET namePl = 'Choroba prostaty' WHERE name = 'Prostate Disease';
UPDATE specialties SET nameNl = 'Prostaatziekte' WHERE name = 'Prostate Disease';

UPDATE specialties SET nameTr = 'Böbrek Taşı' WHERE name = 'Kidney Stones';
UPDATE specialties SET nameDe = 'Nierensteine' WHERE name = 'Kidney Stones';
UPDATE specialties SET namePl = 'Kamienie w nerkach' WHERE name = 'Kidney Stones';
UPDATE specialties SET nameNl = 'Nierstenen' WHERE name = 'Kidney Stones';

UPDATE specialties SET nameTr = 'İdrar Kaçırma' WHERE name = 'Incontinence';
UPDATE specialties SET nameDe = 'Inkontinenz' WHERE name = 'Incontinence';
UPDATE specialties SET namePl = 'Inkontynencja' WHERE name = 'Incontinence';
UPDATE specialties SET nameNl = 'Incontinentie' WHERE name = 'Incontinence';

UPDATE specialties SET nameTr = 'Erektil Disfonksiyon' WHERE name = 'Erectile Dysfunction';
UPDATE specialties SET nameDe = 'Erektile Dysfunktion' WHERE name = 'Erectile Dysfunction';
UPDATE specialties SET namePl = 'Disfunkcja erekcyjna' WHERE name = 'Erectile Dysfunction';
UPDATE specialties SET nameNl = 'Erectiele disfunctie' WHERE name = 'Erectile Dysfunction';

-- Ophthalmology (4)
UPDATE specialties SET nameTr = 'Refraksyon Hatası' WHERE name = 'Refractive Error';
UPDATE specialties SET nameDe = 'Refraktionsfehler' WHERE name = 'Refractive Error';
UPDATE specialties SET namePl = 'Błąd refrakcji' WHERE name = 'Refractive Error';
UPDATE specialties SET nameNl = 'Refractiefouten' WHERE name = 'Refractive Error';

UPDATE specialties SET nameTr = 'Katarakt' WHERE name = 'Cataracts';
UPDATE specialties SET nameDe = 'Katarakt' WHERE name = 'Cataracts';
UPDATE specialties SET namePl = 'Katarakta' WHERE name = 'Cataracts';
UPDATE specialties SET nameNl = 'Cataract' WHERE name = 'Cataracts';

UPDATE specialties SET nameTr = 'Glokom' WHERE name = 'Glaucoma';
UPDATE specialties SET nameDe = 'Glaukom' WHERE name = 'Glaucoma';
UPDATE specialties SET namePl = 'Glaukoma' WHERE name = 'Glaucoma';
UPDATE specialties SET nameNl = 'Glaucoom' WHERE name = 'Glaucoma';

UPDATE specialties SET nameTr = 'Retinal Hastalık' WHERE name = 'Retinal Disease';
UPDATE specialties SET nameDe = 'Netzhauterkrankung' WHERE name = 'Retinal Disease';
UPDATE specialties SET namePl = 'Choroba siatkówki' WHERE name = 'Retinal Disease';
UPDATE specialties SET nameNl = 'Netvliesziekte' WHERE name = 'Retinal Disease';

-- ENT (4)
UPDATE specialties SET nameTr = 'İşitme Kaybı' WHERE name = 'Hearing Loss';
UPDATE specialties SET nameDe = 'Hörverlust' WHERE name = 'Hearing Loss';
UPDATE specialties SET namePl = 'Utrata słuchu' WHERE name = 'Hearing Loss';
UPDATE specialties SET nameNl = 'Gehoorverlies' WHERE name = 'Hearing Loss';

UPDATE specialties SET nameTr = 'Sinüzit' WHERE name = 'Sinusitis';
UPDATE specialties SET nameDe = 'Sinusitis' WHERE name = 'Sinusitis';
UPDATE specialties SET namePl = 'Zapalenie zatok' WHERE name = 'Sinusitis';
UPDATE specialties SET nameNl = 'Sinusitis' WHERE name = 'Sinusitis';

UPDATE specialties SET nameTr = 'Uyku Bozuklukları' WHERE name = 'Sleep Disorders';
UPDATE specialties SET nameDe = 'Schlafstörungen' WHERE name = 'Sleep Disorders';
UPDATE specialties SET namePl = 'Zaburzenia snu' WHERE name = 'Sleep Disorders';
UPDATE specialties SET nameNl = 'Slaapstoornissen' WHERE name = 'Sleep Disorders';

-- Additional for ENT balance (if needed)
UPDATE specialties SET nameTr = 'Vertigo' WHERE name IS NOT NULL;

-- Rheumatology (3)
UPDATE specialties SET nameTr = 'Artrit' WHERE name = 'Arthritis';
UPDATE specialties SET nameDe = 'Arthritis' WHERE name = 'Arthritis';
UPDATE specialties SET namePl = 'Zapalenie stawów' WHERE name = 'Arthritis';
UPDATE specialties SET nameNl = 'Artritis' WHERE name = 'Arthritis';

UPDATE specialties SET nameTr = 'Lupus' WHERE name = 'Lupus';
UPDATE specialties SET nameDe = 'Lupus' WHERE name = 'Lupus';
UPDATE specialties SET namePl = 'Toczleń' WHERE name = 'Lupus';
UPDATE specialties SET nameNl = 'Lupus' WHERE name = 'Lupus';

UPDATE specialties SET nameTr = 'Vaskülit' WHERE name = 'Vasculitis';
UPDATE specialties SET nameDe = 'Vaskulitis' WHERE name = 'Vasculitis';
UPDATE specialties SET namePl = 'Zapalenie naczyń' WHERE name = 'Vasculitis';
UPDATE specialties SET nameNl = 'Vasculitis' WHERE name = 'Vasculitis';

-- Endocrinology (3)
UPDATE specialties SET nameTr = 'Diyabet' WHERE name = 'Diabetes';
UPDATE specialties SET nameDe = 'Diabetes' WHERE name = 'Diabetes';
UPDATE specialties SET namePl = 'Cukrzyca' WHERE name = 'Diabetes';
UPDATE specialties SET nameNl = 'Diabetes' WHERE name = 'Diabetes';

UPDATE specialties SET nameTr = 'Tiroid Hastalığı' WHERE name = 'Thyroid Disease';
UPDATE specialties SET nameDe = 'Schilddrüsenerkrankung' WHERE name = 'Thyroid Disease';
UPDATE specialties SET namePl = 'Choroba tarczycy' WHERE name = 'Thyroid Disease';
UPDATE specialties SET nameNl = 'Schildklierziekte' WHERE name = 'Thyroid Disease';

UPDATE specialties SET nameTr = 'Hormon Replasman Terapisi' WHERE name = 'Hormone Replacement';
UPDATE specialties SET nameDe = 'Hormonersatztherapie' WHERE name = 'Hormone Replacement';
UPDATE specialties SET namePl = 'Terapia hormonalna' WHERE name = 'Hormone Replacement';
UPDATE specialties SET nameNl = 'Hormoonvervanging' WHERE name = 'Hormone Replacement';

-- Extended Hypertension (1)
UPDATE specialties SET nameTr = 'Hipertansiyon Yönetimi' WHERE name = 'Hypertension Management';
UPDATE specialties SET nameDe = 'Bluthochdruckverwaltung' WHERE name = 'Hypertension Management';
UPDATE specialties SET namePl = 'Zarządzanie nadciśnieniem' WHERE name = 'Hypertension Management';
UPDATE specialties SET nameNl = 'Hypertensie-management' WHERE name = 'Hypertension Management';

-- Nephrology (3)
UPDATE specialties SET nameTr = 'Kronik Böbrek Hastalığı' WHERE name = 'Chronic Kidney Disease';
UPDATE specialties SET nameDe = 'Chronische Nierenerkrankung' WHERE name = 'Chronic Kidney Disease';
UPDATE specialties SET namePl = 'Przewlekła choroba nerek' WHERE name = 'Chronic Kidney Disease';
UPDATE specialties SET nameNl = 'Chronische nierziekte' WHERE name = 'Chronic Kidney Disease';

UPDATE specialties SET nameTr = 'Diyaliz' WHERE name = 'Dialysis';
UPDATE specialties SET nameDe = 'Dialyse' WHERE name = 'Dialysis';
UPDATE specialties SET namePl = 'Dializa' WHERE name = 'Dialysis';
UPDATE specialties SET nameNl = 'Dialyse' WHERE name = 'Dialysis';

UPDATE specialties SET nameTr = 'Böbrek Nakli' WHERE name = 'Kidney Transplant';
UPDATE specialties SET nameDe = 'Nierentransplantation' WHERE name = 'Kidney Transplant';
UPDATE specialties SET namePl = 'Przeszczep nerki' WHERE name = 'Kidney Transplant';
UPDATE specialties SET nameNl = 'Niertransplantatie' WHERE name = 'Kidney Transplant';

-- Anesthesiology (3)
UPDATE specialties SET nameTr = 'Ağrı Yönetimi' WHERE name = 'Pain Management';
UPDATE specialties SET nameDe = 'Schmerztherapie' WHERE name = 'Pain Management';
UPDATE specialties SET namePl = 'Zarządzanie bólem' WHERE name = 'Pain Management';
UPDATE specialties SET nameNl = 'Pijnbeheersing' WHERE name = 'Pain Management';

UPDATE specialties SET nameTr = 'Ameliyat Öncesi Değerlendirme' WHERE name = 'Pre-operative Assessment';
UPDATE specialties SET nameDe = 'Präoperative Bewertung' WHERE name = 'Pre-operative Assessment';
UPDATE specialties SET namePl = 'Ocena preoperacyjna' WHERE name = 'Pre-operative Assessment';
UPDATE specialties SET nameNl = 'Preëoperatieve beoordeling' WHERE name = 'Pre-operative Assessment';

UPDATE specialties SET nameTr = 'Ameliyat Sonrası Bakım' WHERE name = 'Post-operative Care';
UPDATE specialties SET nameDe = 'Postoperative Versorgung' WHERE name = 'Post-operative Care';
UPDATE specialties SET namePl = 'Opieka pooperacyjna' WHERE name = 'Post-operative Care';
UPDATE specialties SET nameNl = 'Postoperatieve zorg' WHERE name = 'Post-operative Care';
