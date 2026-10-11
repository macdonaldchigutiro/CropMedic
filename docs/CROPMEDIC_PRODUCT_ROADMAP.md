# CropMedic product roadmap

CropMedic should remain simple enough for an older farmer to use without training, while still feeling premium and modern.

## Core product promise

**See a crop problem → scan it → understand the likely issue → know what to do next → know who to contact if help is still needed.**

## Implemented / first-wave features

### 1. AI crop diagnosis
- Scan or upload a leaf photo.
- Supported crops initially: maize, tomato, potato, bell pepper.
- Healthy/disease/uncertain flows.
- Safer low-confidence handling.
- English, Shona, Ndebele and Tonga UI foundation.

### 2. Crop disease library
- Offline-friendly static knowledge foundation.
- Common symptoms.
- Conditions that favour spread.
- Practical first steps.
- Prevention guidance.
- Escalation to extension/agronomy support when disease is severe or treatment is uncertain.

### 3. Weather and crop-risk screen
- Province/nearest-centre selector.
- Current temperature, humidity, rain and wind.
- Short forecast.
- Farmer-focused alerts such as fungal-risk conditions, heat stress, wind/spraying caution and rain risk.
- Weather is advisory and must not be presented as a disease diagnosis.

### 4. Extension-services help directory
- National/provincial contact structure.
- Only publish phone numbers after checking a current public source.
- Expand to province → district → ward where reliable public data exists.
- Show a last-verified date for contacts before public release.

### 5. Printable diagnosis reports
- Result screen can create a report.
- Word-compatible download in the web preview.
- Print / Save as PDF from the browser.
- Report includes crop photo, diagnosis, confidence, advice, alternatives and a professional-help disclaimer.

## Next-wave features

### 6. Scan history / farm records
- Save crop, photo, date, diagnosis, confidence and advice.
- Filter by crop or field.
- Generate multi-scan field-health reports.

### 7. Seasonal crop calendar
- Crop stage: planting → establishment → vegetative → flowering → harvest.
- Stage-specific disease/pest watch-outs.
- Water/weather reminders.
- Simple management prompts.

### 8. Offline mode
- Disease library should be fully usable without internet.
- Cache previously viewed guidance and previous scans.
- Queue reports/history locally when connectivity is poor.

### 9. Audio guidance
- “Listen” button on diagnosis and library guidance.
- Prioritise Shona, Ndebele, Tonga and English.
- Important for users with low literacy or who prefer spoken guidance.

### 10. Extension-officer handoff
- “Share with extension officer” from a diagnosis.
- Attach latest CropMedic report.
- Include image, diagnosis, confidence and farmer notes.

### 11. Better image validation
- Dedicated supported-leaf / non-leaf check before disease classification.
- Reject faces, people, vehicles, food, household objects, unsupported plants and unusable photos.
- Quality checks for blur, darkness, distance and incomplete leaf framing.

## Features to avoid until the core is excellent

- social-media style farmer feed
- general news feed
- loans and insurance marketplace
- input marketplace
- produce trading marketplace
- livestock management
- broad “super-app” features

These can be reconsidered later, but should not dilute CropMedic's crop-health focus.

## Safety principles

- Do not fabricate a diagnosis when confidence is poor.
- Avoid generic pesticide dose instructions.
- Prefer registered product-label information and local extension guidance.
- Clearly distinguish AI guidance from professional diagnosis.
- Verify public contact information before release.
- Validate the model on ordinary Zimbabwe field photos before claiming field-ready accuracy.
