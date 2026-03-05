# 🌦️ Stratus — Weather Intelligence

A live weather dashboard static website built with vanilla HTML, CSS, and JavaScript. Deployed and hosted on Microsoft Azure Blob Storage as a static website with automated CI/CD via GitHub Actions.

## 🌐 Live Site

https://stratusstorageweb.z1.web.core.windows.net/

## ✦ Features

- Auto-detects your location via browser GPS on load
- Search any city in the world by name
- Live clock with local time and UTC offset
- Animated canvas atmosphere that reacts to current weather conditions (rain, snow, mist)
- Real-time weather data including temperature, feels-like, humidity, wind speed, pressure, and visibility
- 5-day forecast with weather condition icons
- Sun panel with sunrise, sunset, UV index bar, rain probability, and max wind gust
- Custom 404 page matching the site aesthetic
- Azure hosting badge
- Fully responsive for mobile and desktop

## 🛰️ APIs Used

| API | Purpose | Key Required |
|-----|---------|-------------|
| Open-Meteo | Current weather + forecast | No |
| Open-Meteo Geocoding | City name search | No |
| Nominatim (OpenStreetMap) | Reverse geocoding (GPS → city name) | No |

## 🗂️ Project Structure
```
stratus-weather-site/
├── website/
│   ├── index.html         ← Main weather dashboard
│   └── 404.html           ← Custom error page
├── scripts/
│   └── provision-and-deploy.sh  ← Azure CLI setup script
├── .github/
│   └── workflows/
│       └── deploy.yml     ← GitHub Actions CI/CD pipeline
└── README.md
```

## 🚀 Deploying to Azure

### Prerequisites
- Azure CLI installed
- Active Azure subscription
- Git

### Manual Deploy
```powershell
# Login
az login --tenant YOUR-TENANT-ID

# Create resource group
az group create --name stratus-rg --location eastus

# Create storage account
az storage account create --name stratusstorageweb --resource-group stratus-rg --location eastus --sku Standard_LRS --kind StorageV2 --allow-blob-public-access true

# Enable static website hosting
az storage blob service-properties update --account-name stratusstorageweb --static-website --index-document "index.html" --404-document "404.html" --auth-mode login

# Upload files
az storage blob upload-batch --account-name stratusstorageweb --account-key "YOUR-KEY" --source ./website --destination '$web' --overwrite
```

### Automated Deploy (GitHub Actions)

Every push to `main` that modifies files in `website/` triggers an automatic deployment.

Add these three secrets to your GitHub repository under **Settings → Secrets and variables → Actions:**

| Secret | Value |
|--------|-------|
| `AZURE_CREDENTIALS` | JSON output from `az ad sp create-for-rbac` |
| `AZURE_STORAGE_ACCOUNT` | `stratusstorageweb` |
| `AZURE_RESOURCE_GROUP` | your resource group name |

## 🛠️ Built With

- Vanilla HTML, CSS, JavaScript
- Azure Blob Storage (Static Website Hosting)
- GitHub Actions (CI/CD)
- Open-Meteo API
- Nominatim Geocoding

## 📄 License

MIT