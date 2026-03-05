# 🌦️ Stratus — Weather Intelligence

> A live weather dashboard deployed to Microsoft Azure Blob Storage as a static website, with automated CI/CD via GitHub Actions.

![Stratus Banner][screenshot-banner]

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [APIs Used](#apis-used)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Deployment Steps](#deployment-steps)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Design Choices](#design-choices)
- [Challenges & Solutions](#challenges--solutions)
- [Screenshots](#screenshots)
- [Demo](#demo)
- [License](#license)

---

## Overview

Stratus is a fully functional, production-deployed weather intelligence dashboard built with **vanilla HTML, CSS, and JavaScript** — no frameworks, no build tools, no dependencies. It fetches live weather data from the free Open-Meteo API and renders it in a distinctive dark instrument-panel aesthetic inspired by nautical navigation rooms and editorial print design.

The site is hosted entirely on **Azure Blob Storage** using the static website feature, meaning there is no server, no backend, and no compute cost, just files served directly from blob storage over HTTPS.

---

## Architecture

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

### Azure Resource Breakdown

| Resource | Name | Purpose |
|----------|------|---------|
| Resource Group | `stratus-static-site-rg` | Logical container for all resources |
| Storage Account | `stratusstorageweb` | Hosts the static website files |
| Blob Container | `$web` | Special public container for static hosting |
| Static Website | Primary web endpoint | Public HTTPS URL for the site |

---

## Features

- **Auto-location detection** — Uses browser Geolocation API on load, falls back to Lagos
- **City search** — Search any city worldwide by name using Open-Meteo Geocoding
- **Live clock** — Real-time clock with local time and UTC offset in the navbar
- **Animated atmosphere** — Canvas-based particle animation that switches between floating mist (clear/cloudy) and falling rain/snow based on actual current conditions
- **Current conditions** — Temperature, feels-like, humidity, wind speed & direction, pressure, precipitation, visibility
- **5-day forecast** — Daily high/low temperatures with WMO weather condition icons
- **Sun & Atmosphere panel** — Sunrise, sunset, UV index with visual bar, rain probability, max wind gust
- **4-stat dashboard** — Humidity, wind speed, air pressure, visibility in dedicated cards
- **Custom 404 page** — Branded error page matching the site aesthetic
- **Azure hosting badge** — Displays deployment platform in the hero section
- **Fully responsive** — Mobile-first layout that adapts to all screen sizes

---

## APIs Used

| API | Endpoint | Purpose | Key Required |
|-----|----------|---------|-------------|
| Open-Meteo Forecast | `api.open-meteo.com/v1/forecast` | Current weather + 6-day forecast | No |
| Open-Meteo Geocoding | `geocoding-api.open-meteo.com/v1/search` | City name → coordinates | No |
| Nominatim (OpenStreetMap) | `nominatim.openstreetmap.org/reverse` | GPS coordinates → city name | No |

All APIs are completely free with no authentication required, making this deployable with zero API costs.

---

## Project Structure

```
stratus-weather-site/
│
├── website/                          ← Static site source files
│   ├── index.html                    ← Main weather dashboard (single file app)
│   └── 404.html                      ← Custom branded error page
│
├── scripts/
│   └── provision-and-deploy.sh       ← Azure CLI provisioning script (Linux/Mac)
│
├── .github/
│   └── workflows/
│       └── deploy.yml                ← GitHub Actions CI/CD pipeline
│
├── screenshots/                      ← Project screenshots
│   ├──-azure-resource-group.png   [Azure Portal showing resource group created]
│   ├──-storage-account.png        [Storage account overview in Azure Portal]
│   ├──-static-website-enabled.png [Static website hosting enabled, endpoint shown]
│   ├──-web-container.png          [$web container with uploaded index.html + 404.html]
│   ├──-site-live-desktop.png      [Stratus dashboard live on desktop browser]
│   ├──-site-live-mobile.png       [Stratus dashboard live on mobile (Lagos weather)]
│   ├──-github-secrets.png         [GitHub repo secrets configuration screen]
│   ├──-github-actions-run.png     [Successful GitHub Actions workflow run]
│   └──-forecast-panel.png         [5-day forecast and Sun & Atmosphere panel]
│
└── README.md                         ← This file
```

---

## Configuration

### Azure Storage Account Settings

| Setting | Value | Reason |
|---------|-------|--------|
| SKU | `Standard_LRS` | Locally redundant storage — cheapest tier, sufficient for static sites |
| Kind | `StorageV2` | Required for static website hosting feature |
| Location | `southafricanorth` | Widely available, good latency |
| Public blob access | `true` | Required so browsers can download files anonymously |
| Min TLS version | `TLS1_2` | Security best practice, rejects older insecure connections |
| Index document | `index.html` | Served at the root URL `/` |
| 404 document | `404.html` | Served when a path is not found |

### Cache Control

All uploaded files are served with:
```
Cache-Control: public, max-age=3600
```
This tells browsers and CDN edge nodes to cache files for 1 hour before re-requesting, reducing load times on repeat visits.

### CORS Configuration

CORS is enabled on the storage account to allow the browser to make API calls to Open-Meteo and Nominatim:

```powershell
az storage cors add `
  --account-name stratusstorageweb `
  --services b `
  --methods GET POST OPTIONS `
  --origins "*" `
  --allowed-headers "*" `
  --exposed-headers "*" `
  --max-age 3600
```

---

## Deployment Steps

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Active Azure subscription
- Git installed

### Step 1 — Login to Azure

```powershell
az login --tenantID
az account set --subscription "SUBSCRIPTION-ID"
az account show --output table
```

![Azure Login][screenshot-azure-login]

### Step 2 — Create Resource Group

```powershell
az group create `
  --name stratus-static-site-rg `
  --location eastus
```

![Resource Group Created][screenshot-01-azure-resource-group]

### Step 3 — Create Storage Account

```powershell
az storage account create `
  --name stratusstorageweb `
  --resource-group stratus-static-site-rg `
  --location eastus `
  --sku Standard_LRS `
  --kind StorageV2 `
  --allow-blob-public-access true `
  --output none
```

![Storage Account][screenshot-02-storage-account]

### Step 4 — Enable Static Website Hosting

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

### Step 5 — Enable CORS

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

### Step 6 — Upload Website Files

```powershell
az storage blob upload-batch `
  --account-name stratusstorageweb `
  --account-key "ACCOUNT-KEY" `
  --source ./website `
  --destination '$web' `
  --overwrite `
  --content-cache-control "public, max-age=3600" `
  --output table
```

![Files Uploaded][screenshot-04-web-container]

### Step 7 — Get Live URL

```powershell
az storage account show `
  --name stratusstorageweb `
  --resource-group aurora-static-site-rg `
  --query "primaryEndpoints.web" `
  --output tsv
```

The site is now live at:
```
https://stratusstorageweb.z1.web.core.windows.net/
```

![Live Site Desktop][screenshot-05-site-live-desktop]
![Live Site Mobile][screenshot-06-site-live-mobile]

---

## GitHub Actions CI/CD

Every push to `main` that modifies files in `website/**` automatically triggers a deployment to Azure — no manual upload needed.

### Pipeline Flow

```
git push origin main
       │
       ▼
  GitHub Actions triggered
       │
       ├──▶ Job 1: Validate
       │         └── html-validate on all HTML files
       │
       └──▶ Job 2: Deploy (only if validate passes)
                 ├── az login (Service Principal)
                 ├── az storage blob upload-batch
                 ├── Get live URL
                 └── Post summary to Actions tab
```

### Setup — Create Service Principal

```powershell
$SUBSCRIPTION_ID = az account show --query id --output tsv

az ad sp create-for-rbac `
  --name "stratus-github-actions" `
  --role "Storage Blob Data Contributor" `
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/aurora-static-site-rg" `
  --sdk-auth
```

Copy the entire JSON output — you will not be able to retrieve it again.

### Setup — Add GitHub Secrets

Navigate to: **Repository → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Value |
|-------------|-------|
| `AZURE_CREDENTIALS` | Full JSON from `az ad sp create-for-rbac` output |
| `AZURE_STORAGE_ACCOUNT` | `stratusstorageweb` |
| `AZURE_RESOURCE_GROUP` | `aurora-static-site-rg` |

![GitHub Secrets][screenshot-08-github-secrets]

### Triggering a Deploy

```powershell
git add .
git commit -m "update: new weather feature"
git push origin main
```

GitHub Actions picks up the push and deploys automatically within ~60 seconds.

![GitHub Actions Run][screenshot-09-github-actions-run]

---

## Design Choices

### Why Azure Blob Storage (not App Service or VMs)?

Static websites have no server-side logic — there is nothing to compute. Blob Storage serves files directly over HTTPS, which means:
- **Zero server cost** — you only pay for storage (~$0.02/GB/month) and bandwidth
- **Infinite scalability** — Azure handles traffic spikes automatically
- **No maintenance** — no OS patches, no runtime updates, no server management

### Why Vanilla JS (no React/Vue/Angular)?

A static weather dashboard has no need for a component framework. Using vanilla JS means:
- **No build step** — files can be edited and uploaded directly
- **Smaller payload** — no framework bundle, faster load on mobile
- **Simpler deployment** — no `npm run build` in the CI pipeline

### Why Open-Meteo (not OpenWeatherMap)?

Open-Meteo requires no API key, has no rate limits for reasonable usage, and provides WMO-standard weather codes. This means the site works immediately for anyone who clones it without any account setup.

### Why the dark instrument-panel aesthetic?

Weather data is dense — temperature, humidity, pressure, UV, wind, forecast. A dark background with amber/gold accents reduces eye strain when reading numbers, creates clear visual hierarchy between data points, and gives the site a distinctive identity that stands apart from generic blue weather apps.

---

## Challenges & Solutions

### Challenge 1: `az login` failing with MFA error

**Problem:** Personal Gmail-linked Azure accounts enforce Multi-Factor Authentication on the tenant, causing standard `az login` to fail with `AADSTS50076`.

**Solution:** Target the tenant directly using the tenant ID:
```powershell
az login --tenant 268728f9-1135-4c21-9d30-aacca100574d
```
This forces the browser to open the full MFA authentication flow for the specific tenant.

---

### Challenge 2: `--assignee` flag rejecting Gmail address

**Problem:** `az role assignment list --assignee libertyonii@gmail.com` returned "Cannot find user in graph database" because personal Microsoft accounts (Gmail-linked) are stored as external identities in Azure AD and cannot be queried by email address.

**Solution:** Use the Object ID instead:
```powershell
az ad signed-in-user show --query id --output tsv
az role assignment list --assignee YOUR-OBJECT-ID --output table
```

---

### Challenge 3: Open-Meteo API returning 400 Bad Request

**Problem:** The site showed "Could not load weather data" because `weather_code_max` was used as a daily parameter in the API URL, which is not a valid Open-Meteo field name.

**Solution:** Replace `weather_code_max` with the correct field name `weathercode` in both the API URL and the JavaScript render function. Also replace `d.weather_code_max[i+1]` with `d.weathercode[i+1]` in the forecast loop.

---

### Challenge 4: PowerShell `touch` and `curl` not recognised

**Problem:** Linux commands (`touch`, `curl -I`) don't exist in PowerShell, causing "not recognised" errors.

**Solution:** Use PowerShell equivalents:
- `touch README.md` → `New-Item README.md`
- `curl -I "$URL"` → `Invoke-WebRequest -Uri $URL -Method Head`
- Line continuation `\` → backtick `` ` `` in PowerShell

---

### Challenge 5: GitHub Actions `listKeys` authorization failure

**Problem:** The Service Principal had `Storage Blob Data Contributor` role but the workflow tried to call `az storage account keys list`, which requires the separate `listKeys` permission not included in that role.

**Solution:** Assign the additional `Storage Account Contributor` role to the Service Principal:
```powershell
az role assignment create `
  --role "Storage Account Contributor" `
  --assignee YOUR-SP-OBJECT-ID `
  --scope "/subscriptions/YOUR-SUBSCRIPTION-ID/resourceGroups/aurora-static-site-rg"
```

---

### Challenge 6: `$web` container being expanded by PowerShell

**Problem:** PowerShell expands `$web` as a variable (evaluating to empty string) when used in double-quoted strings, breaking the upload-batch destination argument.

**Solution:** Always wrap `$web` in single quotes when passing it as a CLI argument:
```powershell
--destination '$web'   # ✅ correct — single quotes prevent expansion
--destination "$web"   # ❌ wrong  — PowerShell expands $web to empty string
```

---

## Screenshots

| # | Screenshot | Description |
|---|-----------|-------------|
| 01 | ![Resource Group][screenshot-01-azure-resource-group] | Azure Portal — resource group `aurora-static-site-rg` created in East US |
| 02 | ![Storage Account][screenshot-02-storage-account] | Storage account `stratusstorageweb` overview showing kind, replication, and location |
| 03 | ![Static Website][screenshot-03-static-website-enabled] | Static website hosting enabled with primary endpoint URL displayed |
| 04 | ![Web Container][screenshot-04-web-container] | `$web` container contents showing `index.html` and `404.html` uploaded |
| 05 | ![Desktop Site][screenshot-05-site-live-desktop] | Stratus live on desktop — Lagos weather dashboard with all panels loaded |
| 06 | ![Mobile Site][screenshot-06-site-live-mobile] | Stratus live on mobile — responsive layout with temperature hero card |
| 07 | ![City Search][screenshot-07-city-search] | City search used to look up weather for a different city |
| 08 | ![GitHub Secrets][screenshot-08-github-secrets] | GitHub repository secrets configuration with all three secrets added |
| 09 | ![Actions Run][screenshot-09-github-actions-run] | GitHub Actions workflow showing successful validate + deploy jobs |
| 10 | ![Forecast Panel][screenshot-10-forecast-panel] | 5-day forecast and Sun & Atmosphere panel with UV index bar |

> **Note:** Add your actual screenshots to the `screenshots/` folder and update the image references above using the format `![Alt text](screenshots/filename.png)`.

---

## Demo

### Live Site
🌐 **[https://stratusstorageweb.z1.web.core.windows.net/](https://stratusstorageweb.z1.web.core.windows.net/)**

### What to Demonstrate

**1. Auto-location detection**
Open the site on a mobile device and allow location access. The dashboard loads your current city's weather automatically within 2–3 seconds.

**2. City search**
Type any city name (e.g. "London", "Tokyo", "New York") into the search bar and press Enter or click Fetch. The entire dashboard updates with new data and the canvas atmosphere animation changes based on current conditions.

**3. Live weather data**
Point out the real-time accuracy — compare the temperature shown against a known weather source for the same city.

**4. Animated atmosphere**
If current conditions are rainy, the canvas background shows falling blue rain particles. Clear conditions show floating mist. Search a city known to be raining to demonstrate the switch.

**5. Responsive layout**
Resize the browser window or open on mobile to show the grid collapsing from 4-column stats to 2-column, and the hero card stacking vertically.

**6. GitHub Actions auto-deploy**
Make a small visible change to `index.html` (e.g. change the footer year), push to `main`, and show the Actions tab running the deploy pipeline live.

**7. Custom 404 page**
Navigate to `https://stratusstorageweb.z1.web.core.windows.net/nonexistent` to show the branded 404 page.

---

## 🛠️ Built With

- Vanilla HTML, CSS, JavaScript
- Azure Blob Storage (Static Website Hosting)
- Azure CLI
- GitHub Actions (CI/CD)
- Open-Meteo API
- Nominatim / OpenStreetMap Geocoding

---

## 📄 License

MIT — free to use, modify, and deploy.