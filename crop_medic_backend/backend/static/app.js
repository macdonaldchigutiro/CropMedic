const photo = document.getElementById("photo");
const preview = document.getElementById("preview");
const hint = document.getElementById("hint");
const result = document.getElementById("result");
const statusEl = document.getElementById("status");
const langEl = document.getElementById("lang");

if ("serviceWorker" in navigator) {
  navigator.serviceWorker.register("/sw.js").catch(() => {});
}

photo.addEventListener("change", async () => {
  const file = photo.files[0];
  if (!file) return;

  preview.src = URL.createObjectURL(file);
  preview.hidden = false;
  hint.hidden = true;
  result.hidden = true;
  statusEl.textContent = "Checking your leaf…";

  const form = new FormData();
  form.append("file", file);

  try {
    const res = await fetch(`/api/predict?lang=${langEl.value}`, { method: "POST", body: form });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Something went wrong.");
    }
    show(await res.json());
    statusEl.textContent = "";
  } catch (e) {
    statusEl.textContent = e.message + " Check your connection and try again.";
  }
});

function show(data) {
  const isHealthy = data.disease.toLowerCase() === "healthy";
  document.getElementById("disease").textContent = isHealthy ? "Healthy leaf" : data.disease;
  document.getElementById("meta").textContent =
    `${data.crop}, ${Math.round(data.confidence * 100)}% confident` + (data.demo ? " (demo mode)" : "");
  document.getElementById("fill").style.width = Math.round(data.confidence * 100) + "%";
  document.getElementById("warning").hidden = !data.low_confidence;

  const list = document.getElementById("advice");
  list.innerHTML = "";
  data.advice.forEach((step) => {
    const li = document.createElement("li");
    li.textContent = step;
    list.appendChild(li);
  });
  result.hidden = false;
}
