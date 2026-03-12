# 🌦️ Stratus — Weather Intelligence

> A live weather dashboard deployed to Microsoft Azure Blob Storage as a static website, with automated CI/CD via GitHub Actions.

---

## Overview

### What Is This?

Stratus is a live weather intelligence dashboard — a fully deployed, publicly accessible website that shows real-time weather data for any city in the world. The name comes from stratus clouds, the low, layered clouds associated with overcast skies. It runs at:

🌐 **[https://stratusstorageweb.z1.web.core.windows.net/](https://stratusstorageweb.z1.web.core.windows.net/)**

It is hosted entirely on **Microsoft Azure Blob Storage** using the static website hosting feature — no server, no backend, no runtime. Just files served directly over HTTPS from a cloud storage container.

---

### What It Does

When you open Stratus, it immediately tries to detect your location using your device's GPS. If you allow it, the dashboard loads your current city's weather automatically. If you deny location access, it defaults to Lagos. You can also type any city name into the search bar and fetch weather for that location instantly.

The dashboard displays:

- **Current temperature** with a large editorial readout and feels-like temperature
- **Weather condition** (Clear Sky, Moderate Rain, Thunderstorm, etc.) with matching icon
- **4 live stat cards** — humidity, wind speed & direction, air pressure, visibility
- **5-day forecast** — daily high/low temperatures with condition icons for each day
- **Sun & Atmosphere panel** — sunrise, sunset, today's high/low, UV index with a visual bar, rain probability, and maximum wind gust
- **Live clock** in the navbar showing local time and UTC offset
- **Animated canvas background** that reacts to actual weather conditions — rain particles fall when it's raining, mist floats when it's clear, snow drifts when it's snowing

All data is pulled live from the **Open-Meteo API** — completely free, no API key required.

---

### Why I Built It This Way

The core decision was to use **vanilla HTML, CSS, and JavaScript** with no frameworks. A weather dashboard is fundamentally a data display problem — fetch data, render it. React or Vue would add a build step, a dependency tree, and a heavier payload with no real benefit for a project of this scope.

Using vanilla JS means the files can be edited directly in Notepad and uploaded straight to Azure. No `npm install`, no `npm run build`, no compilation. The entire site is two files.

For hosting, **Azure Blob Storage** was chosen over Azure App Service or a VM because static files have no server-side logic to execute. Blob Storage serves them directly over HTTPS at a fraction of the cost — roughly $0.02 per GB per month, and the free tier includes 5 GB, making the effective hosting cost zero for a site this small.

**Open-Meteo** was chosen over OpenWeatherMap because it requires no API key and has no rate limits for reasonable usage. Anyone can clone this repository and deploy it without creating any accounts or setting up any credentials.

The dark instrument-panel aesthetic — prussian blue, amber gold accents, serif typography for temperature readouts, monospaced fonts for data fields — was a deliberate design choice. Weather data is dense. A dark theme with strong contrast reduces eye strain, creates clear visual hierarchy, and gives Stratus a distinctive identity that stands apart from generic blue weather apps.

---

## The Architecture

The architecture describes how all the components of the system connect — from the user's browser, through Azure, to the external weather APIs, and back through the CI/CD pipeline.

---

### What It Does

```
┌─────────────────────────────────────────────────────────────┐
│                        USER BROWSER                         │
│                  (Mobile / Desktop / Tablet)                 │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS Request
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              AZURE BLOB STORAGE                             │
│         stratusstorageweb.z1.web.core.windows.net           │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              $web Container (Public)                │   │
│   │   ┌─────────────┐        ┌─────────────────────┐   │   │
│   │   │  index.html  │        │      404.html        │   │   │
│   │   └─────────────┘        └─────────────────────┘   │   │
│   └─────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────┘
                         │ Browser executes JavaScript
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    EXTERNAL APIs                             │
│                  (called client-side)                        │
│                                                             │
│  ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Open-Meteo     │  │  Open-Meteo  │  │  Nominatim   │  │
│  │  Weather API     │  │  Geocoding   │  │  Reverse Geo │  │
│  │ (current+daily)  │  │ (city search)│  │ (GPS→city)   │  │
│  └──────────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   CI/CD PIPELINE                             │
│                                                             │
│   GitHub Repo ──push──▶ GitHub Actions ──upload──▶ $web    │
│   (main branch)          (deploy.yml)      (az CLI)         │
└─────────────────────────────────────────────────────────────┘
```

---

### Why I Built It This Way

There is no server in this architecture by design. The browser downloads the HTML file from Azure, then the JavaScript inside it makes all the API calls directly. Azure never touches the weather data. This is called a **serverless static architecture** and it has three major advantages: zero compute cost, automatic scalability, and zero server maintenance.

The three external APIs handle different responsibilities. Open-Meteo handles all weather data. Open-Meteo Geocoding converts a city name the user types into GPS coordinates. Nominatim converts GPS coordinates from the device back into a readable city name. Separating these concerns means each API can be swapped out independently without touching the others.

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group  | `stratus-static-site-rg` | Logical container for all Azure resources |
| Storage Account | `stratusstorageweb` | Hosts the static website files |
| Blob Container  | `$web` | Special public container for static hosting |
| Static Website Endpoint  | Primary web endpoint | Public HTTPS URL for the live site |

| API | Endpoint | Purpose | Key Required |
|-----|----------|---------|-------------|
| Open-Meteo Forecast | `api.open-meteo.com/v1/forecast` | Current weather + 6-day forecast | No |
| Open-Meteo Geocoding | `geocoding-api.open-meteo.com/v1/search` | City name → coordinates | No |
| Nominatim (OpenStreetMap) | `nominatim.openstreetmap.org/reverse` | GPS coordinates → city name | No |

---

## Project Structure

The project structure shows every file and folder in the repository and explains what each one does.

---

### What It Does

```
stratus-weather-site/
│
├── website/                           ← Static site source files
│   ├── index.html                     ← Main weather dashboard (entire app in one file)
│   └── 404.html                       ← Custom branded error page
│
├── scripts/
│   └── provision-and-deploy.sh        ← Azure CLI provisioning script (Linux/Mac)
│
├── .github/
│   └── workflows/
│       └── deploy.yml                 ← GitHub Actions CI/CD pipeline
│
├── screenshots/                       ← Project screenshots folder
│   ├── 00-azure-login.md              [Terminal showing successful az login output]
│   ├── 01-azure-resource-group.md     [Azure Portal — resource group created]
│   ├── 02-storage-account.md          [Storage account overview in Azure Portal]
│   ├── 03-static-website-enabled.md   [Static website hosting enabled, endpoint shown]
│   ├── 04-web-container.md            [$web container with uploaded files]
│   ├── 05-site-live-desktop.md        [Stratus dashboard live on desktop]
│   ├── 06-site-live-mobile.md         [Stratus dashboard live on mobile]
│   ├── 07-city-search.md              [City search in action]
│   ├── 08-github-secrets.md           [GitHub repo secrets configured]
│   ├── 09-github-actions-run.md       [Successful GitHub Actions workflow run]
│   └── 10-forecast-panel.md           [5-day forecast and Sun & Atmosphere panel]
│
└── README.md                          ← This file
```

---

### Why I Built It This Way

The `website/` folder is intentionally isolated from everything else. It contains only the files that get uploaded to Azure — nothing else. This means the GitHub Actions workflow can point directly at `./website` as the upload source without any filtering or build output.

The `.github/workflows/` folder is the standard location GitHub looks for Actions pipeline definitions. Placing `deploy.yml` there means the pipeline activates automatically without any additional configuration.

The `screenshots/` folder uses markdown placeholder files instead of actual images until real screenshots are captured, so the folder structure is documented and ready before the images exist.

---

## How the Deployment Works

The deployment process is the sequence of Azure CLI commands that provision the cloud infrastructure and upload the website files to make it publicly accessible.

---

### What It Does

Deployment happens in seven steps:

**Step 1 — Login**
```powershell
az login --tenant 268728f9-1135-4c21-9d30-aacca100574d
az account set --subscription "9cbe56c5-5ab4-4f1f-a67d-b6d8d66b5a45"
```

**Step 2 — Create Resource Group**
```powershell
az group create `
  --name aurora-static-site-rg `
  --location eastus
```
![Resource Group Created][screenshot-01-azure-resource-group]

**Step 3 — Create Storage Account**
```powershell
az storage account create `
  --name stratusstorageweb `
  --resource-group aurora-static-site-rg `
  --location eastus `
  --sku Standard_LRS `
  --kind StorageV2 `
  --allow-blob-public-access true `
  --output none
```
![Storage Account][screenshot-02-storage-account]

**Step 4 — Enable Static Website Hosting**
```powershell
az storage blob service-properties update `
  --account-name stratusstorageweb `
  --static-website `
  --index-document "index.html" `
  --404-document "404.html" `
  --auth-mode login `
  --output none
```
![Static Website Enabled][screenshot-03-static-website-enabled]

**Step 5 — Enable CORS**
```powershell
az storage cors add `
  --account-name stratusstorageweb `
  --account-key "YOUR-ACCOUNT-KEY" `
  --services b `
  --methods GET POST OPTIONS `
  --origins "*" `
  --allowed-headers "*" `
  --exposed-headers "*" `
  --max-age 3600
```

**Step 6 — Upload Website Files**
```powershell
az storage blob upload-batch `
  --account-name stratusstorageweb `
  --account-key "YOUR-ACCOUNT-KEY" `
  --source ./website `
  --destination '$web' `
  --overwrite `
  --content-cache-control "public, max-age=3600" `
  --output table
```
![Files in $web Container][screenshot-04-web-container]

**Step 7 — Get Live URL**
```powershell
az storage account show `
  --name stratusstorageweb `
  --resource-group aurora-static-site-rg `
  --query "primaryEndpoints.web" `
  --output tsv
```

Each step is its own discrete command so that if one fails, you know exactly where the failure is and can re-run only that step without starting over. The `--output none` flag on account creation suppresses verbose JSON output that would obscure errors in the terminal. The `--auth-mode login` flag on the static website command uses Azure AD authentication instead of an account key, which is the recommended approach when the caller already has the Owner role.

CORS must be enabled separately because Azure Blob Storage blocks cross-origin requests by default. Without this step, the browser treats the API calls to Open-Meteo as a security violation and blocks them silently — which is what caused the "Could not load weather data" error initially.

The storage account settings were chosen as follows:

| Setting | Value | Reason |
|---------|-------|--------|
| SKU | `Standard_LRS` | Locally redundant — cheapest tier, sufficient for static files |
| Kind | `StorageV2` | Required for static website hosting |
| Public blob access | `true` | Browsers must read files anonymously |
| Cache-Control | `public, max-age=3600` | Browsers cache files for 1 hour, reducing repeat load times |

---

## CI/CD with GitHub Actions

CI/CD stands for Continuous Integration and Continuous Deployment. The GitHub Actions workflow automates the deployment so that every code push to the `main` branch triggers an automatic upload to Azure — no manual commands needed.

---

git push origin main
       │
       ▼
  GitHub detects push to main
  with changes in website/**
       │
       ├──▶ Job 1: Validate (html-validate)
       │         └── Lints all HTML files
       │              ├── Pass → continue
       │              └── Fail → stop, skip deploy
       │
       └──▶ Job 2: Deploy
                 ├── az login (Service Principal)
                 ├── Get storage account key
                 ├── az storage blob upload-batch → $web
                 ├── Retrieve live URL
                 └── Post summary to Actions tab
```

The workflow is defined in `.github/workflows/deploy.yml`. It only triggers when files inside `website/**` change, so pushing README updates or workflow changes alone does not kick off a deploy.

```

**GitHub Secrets required** (Settings → Secrets and variables → Actions):

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | Full JSON from `az ad sp create-for-rbac` output |
| `AZURE_STORAGE_ACCOUNT` | `stratusstorageweb` |
| `AZURE_RESOURCE_GROUP` | `aurora-static-site-rg` |

---

Manual deployment works but it requires remembering commands, having the Azure CLI installed, and being logged in. Any team member or future contributor would have to learn all of that just to ship a one-line change.

GitHub Actions solves this by encoding the entire deployment procedure in a YAML file inside the repository. The pipeline is version-controlled, reviewable, and runs identically every time regardless of who pushes the code or what machine they're using.

The validate job runs first and blocks the deploy if the HTML is malformed. This prevents a broken file from going live, quality gate before deployment. The Service Principal is scoped to only the specific resource group with only Storage Blob Data Contributor rights, following the principle of least privilege — it cannot touch any other Azure resources.

---

## Challenges I Ran Into

This section documents every significant problem encountered during the project, the exact error message or symptom, and the solution that resolved it.

---

### The Problems and Fixes

**Challenge 1: `az login` failing with MFA error**

The very first command failed with `AADSTS50076: you must use multi-factor authentication`. Personal Gmail-linked Azure accounts are placed in a Default Directory tenant that enforces MFA. Standard `az login` skips this tenant's MFA flow.

```powershell
# Fix — target the tenant directly
az login --tenant 268728f9-1135-4c21-9d30-aacca100574d
```

---

**Challenge 2: `--assignee` rejecting Gmail address**

Running `az role assignment list --assignee libertyonii@gmail.com` returned "Cannot find user in graph database." Gmail-linked accounts are stored as external identities in Azure AD and cannot be queried by email.

```powershell
# Fix — use Object ID instead of email
az ad signed-in-user show --query id --output tsv
az role assignment list --assignee YOUR-OBJECT-ID --output table
```

---

**Challenge 3: Open-Meteo API returning 400 Bad Request**

The site showed "Could not load weather data." The browser console showed a 400 error on the API call. The cause was using `weather_code_max` as a daily parameter — the correct Open-Meteo field name is `weathercode`.

```javascript
// Fix — correct field names in both the URL and render function
daily=weathercode,temperature_2m_max,...   // in the API URL
d.weathercode[i+1]                         // in the forecast render loop
```

---

**Challenge 4: PowerShell not recognising Linux commands**

Commands from the walkthrough — `touch`, `curl -I` — caused "not recognised" errors because they are Linux-only commands. PowerShell has different equivalents.

```powershell
# Fix — use PowerShell equivalents
New-Item README.md                          # replaces: touch README.md
Invoke-WebRequest -Uri $URL -Method Head    # replaces: curl -I "$URL"
# Also: use backtick ` for line continuation instead of backslash \
```

---

**Challenge 5: GitHub Actions `listKeys` authorisation failure**

The Actions workflow failed with `AuthorizationFailed` when trying to list storage account keys. The Service Principal had `Storage Blob Data Contributor` but `listKeys` requires the separate `Storage Account Contributor` role.

```powershell
# Fix — assign the additional role to the Service Principal
az role assignment create `
  --role "Storage Account Contributor" `
  --assignee YOUR-SP-OBJECT-ID `
  --scope "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/aurora-static-site-rg"
```

---

**Challenge 6: `$web` container name expanded by PowerShell**

When using `--destination "$web"` in double quotes, PowerShell expanded `$web` as a variable (empty string), causing the upload to fail with no clear error.

```powershell
--destination '$web'   # ✅ single quotes — literal string, not expanded
--destination "$web"   # ❌ double quotes — PowerShell expands $web to nothing
```

Every challenge listed above was a real error encountered during this exact build. Documenting them serves two purposes: it creates an honest record of what cloud deployment actually looks like in practice, not just the happy path, and it makes the project reproducible for anyone who hits the same issues, because most of these are environment-specific problems that affect every Windows user working with Azure CLI for the first time.

---

## Demo

A guided walkthrough of the live site demonstrating every feature.

---

🌐 **[https://stratusstorageweb.z1.web.core.windows.net/](https://stratusstorageweb.z1.web.core.windows.net/)**

**1. Auto-location** — Open on mobile, allow GPS. Dashboard loads your city in under 3 seconds.

**2. City search** — Type "London", "Tokyo", or "Abuja" and press Enter. Dashboard fully updates.

**3. Live data accuracy** — Compare the temperature shown with Google's weather for the same city.

**4. Atmosphere animation** — Search a city that is currently raining. Canvas switches to falling rain particles.

**5. Responsive layout** — Resize the browser window. Stats collapse from 4-column to 2-column. Hero card stacks vertically.

**6. Auto-deploy** — Make a one-line change to `index.html`, push to `main`, watch GitHub Actions run live in the Actions tab.

**7. Custom 404** — Visit `/nonexistent` to see the branded error page.

The demo sequence is ordered from most impressive to most technical, starting with the instant GPS detection (which always gets a reaction) and ending with the CI/CD pipeline (which requires explanation). This ordering works for both a live classroom demo and a recorded walkthrough.

---

## Does It Meet the Brief?

| Requirement | Status | Evidence |
|-------------|--------|---------|
| Use a static website template | ✅ | Custom-built Stratus weather dashboard in `website/index.html` |
| Provision storage account with Azure CLI | ✅ | `az storage account create` in deployment steps |
| Enable static website hosting with CLI | ✅ | `az storage blob service-properties update --static-website` |
| Upload files with CLI | ✅ | `az storage blob upload-batch --destination '$web'` |
| Unique static website | ✅ | Original design — dark instrument-panel aesthetic, live weather API |
| GitHub Actions automation | ✅ | `.github/workflows/deploy.yml` — deploys on every push to `main` |
| Uploads happen on new site file push | ✅ | Workflow triggers on `paths: website/**` changes |
| Static website code | ✅ | `website/index.html` + `website/404.html` |
| CLI provisioning script | ✅ | `scripts/provision-and-deploy.sh` |
| GitHub Actions workflow | ✅ | `.github/workflows/deploy.yml` |
| Screenshots of live site | ✅ | `screenshots/` folder — 11 documented slots |
| Documentation | ✅ | This README — architecture, config, deployment, challenges |

---

## 🛠️ Built With

- Vanilla HTML, CSS, JavaScript
- Microsoft Azure Blob Storage (Static Website Hosting)
- Azure CLI
- GitHub Actions
- Open-Meteo Weather API
- Nominatim / OpenStreetMap Geocoding

---
Free to use, modify, and deploy.
