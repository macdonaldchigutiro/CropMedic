# Common Bean external validation plan

This plan is for the **BLD-BD pilot model only**. The pilot training classes are:

- Angular Leaf Spot
- Bean Common Mosaic Virus
- Healthy

The 672 BLD-BD originals remain training/internal-test data. Do not reuse them as external validation.

## Validation layers

### 1. Cross-source known-class benchmark

Use an independent source that contains the same or clearly equivalent known classes.

Candidate: **High-Resolution Dataset of Common Bean Leaf Diseases in Bangladesh** (Mendeley DOI `10.17632/89c9r5m2gx.1`). It contains Angular Leaf Spot, Mosaic Virus, Healthy, Anthracnose and Rust. Before using its Mosaic Virus class as a direct Bean Common Mosaic Virus benchmark, confirm the label provenance; do not silently assume every mosaic-virus image is BCMV.

If the label review is satisfactory, reserve a fixed holdout from Angular Leaf Spot, Mosaic Virus and Healthy for cross-source evaluation. Do not tune thresholds on this holdout.

### 2. East African field benchmark and unknown-disease challenge

Use field images from a different geography to test whether the model survives realistic backgrounds, phones, lighting and plant presentation.

- **Makerere / NaCRRI Beans (Uganda)** — 1,295 real handheld/field images, classes Healthy, Angular Leaf Spot and Bean Rust, CC BY 4.0. Use Healthy and Angular Leaf Spot as known-class evidence if the images can be obtained reliably. Treat Bean Rust as an **unsupported-disease challenge**, not as one of the pilot model's known classes.
- **Tanzania common-bean field datasets** — large smartphone field collections with Healthy, Bean Rust and Bean Anthracnose. Use Healthy as additional known-class evidence; use Rust/Anthracnose as unsupported-disease challenge images for rejection testing.

These datasets are valuable for field robustness, but they do **not** by themselves validate the pilot's Bean Common Mosaic Virus class.

### 3. Non-crop / wrong-crop rejection challenge

Keep a separate challenge set outside training containing:

- unrelated crops;
- weeds and wild plants;
- soil and bare field scenes;
- tools, vehicles and buildings;
- food photos;
- hands/faces/people;
- blurred, dark, overexposed and badly framed images.

The desired behaviour is **uncertain / unsupported**, not a confident bean disease prediction.

## Release rule

Common bean remains **Coming soon** until all three pilot classes have independent evidence, unsupported disease/non-crop rejection is acceptable, and Zimbabwe-style field photos have been reviewed. Public benchmark accuracy alone is not field readiness.

## Evaluation command

After the frozen pilot artifacts exist:

```bash
python evaluate_external_dataset.py \
  --crop-id common_bean \
  --model-dir /content/drive/MyDrive/CropMedic/batch1/common_bean \
  --data-dir external_common_bean/known \
  --unknown-dir external_common_bean/unknown
```

Do not tune the model or its thresholds on the external set after seeing the results. If performance is poor, create a new training version and keep the original external benchmark untouched where possible.
