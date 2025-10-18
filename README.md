# qBittorrent Themes

Curated color themes for **qBittorrent**, available for both the Qt desktop client and WebUI (qbittorrent-nox). Each theme ships in two formats:

- **Qt desktop client**: `.qbtheme` bundle (v4.6.0+, Qt6)
- **WebUI**: `.tar.gz` or `.zip` archive

## 📦 Downloads

| Theme | Palette | Qt Client | WebUI |
|-------|---------|-----------|-------|
| **Dark** | ![Dark](assets/palette-dark.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dark.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dark.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dark.zip) |
| **Dracula** | ![Dracula](assets/palette-dracula.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dracula.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dracula.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/dracula.zip) |
| **Gruvbox Dark** | ![Gruvbox Dark](assets/palette-gruvbox-dark.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-dark.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-dark.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-dark.zip) |
| **Gruvbox Light** | ![Gruvbox Light](assets/palette-gruvbox-light.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-light.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-light.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/gruvbox-light.zip) |
| **Solarized Dark** | ![Solarized Dark](assets/palette-solarized-dark.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-dark.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-dark.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-dark.zip) |
| **Solarized Light** | ![Solarized Light](assets/palette-solarized-light.svg) | [.qbtheme](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-light.qbtheme) | [tar.gz](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-light.tar.gz) · [zip](https://github.com/MahdiMirzadeh/qbittorrent/releases/latest/download/solarized-light.zip) |

## 🚀 Installation

### WebUI (Alternative Web UI)

1. Download a WebUI theme archive (`.tar.gz` or `.zip`) from the [Downloads](#-downloads) section
2. Extract it to a directory:
   ```bash
   mkdir -p ~/.config/qbittorrent/webui
   tar -xzf dracula.tar.gz -C ~/.config/qbittorrent/webui
   ```
3. In qBittorrent:
   - Go to **Tools → Options → Web UI**
   - Enable **"Use alternative Web UI"**
   - Set **"Files location"** to the extracted folder (e.g., `~/.config/qbittorrent/webui/webui-dracula`)
   - Click **Save** and reload the WebUI page

**Troubleshooting**: If you encounter "Unacceptable file type, only regular file is allowed", disable alternative UI via API:
```bash
curl "http://localhost:8080/api/v2/app/setPreferences?json=%7B%22alternative_webui_enabled%22:false%7D"
```

### Qt Desktop Client

1. Download a `.qbtheme` file from the [Downloads](#-downloads) section
2. In qBittorrent:
   - Go to **Tools → Options → Behavior → Interface**
   - Under **"Interface theme"**, click **"..."** and select the downloaded `.qbtheme` file
   - Click **OK** and **restart qBittorrent**

## 🛠️ Build Locally

### Prerequisites

- `jq` — JSON processor
- `rcc` — Qt Resource Compiler (Qt5 or Qt6)
- `zip` — (optional) for WebUI `.zip` archives

```bash
# Arch Linux
sudo pacman -S jq qt6-base

# Ubuntu/Debian
sudo apt install jq qtbase5-dev-tools

# macOS
brew install jq qt
```

### Build Commands

```bash
# Build all themes
./gen.sh

# Build a single theme
./gen.sh themes/dracula.json

# Outputs:
# - qt/<theme>.qbtheme
# - webui/<theme>.tar.gz
# - webui/<theme>.zip (if zip is installed)
```

## 📸 Screenshots

### Qt client
- Dark
  
  ![qt dark](assets/qt-dark.webp)
- Dracula
  
  ![qt dracula](assets/qt-dracula.webp)
- Solarized Dark
  
  ![qt solarized dark](assets/qt-solarized-dark.webp)
- Solarized Light
  
  ![qt solarized light](assets/qt-solarized-light.webp)
- Gruvbox Dark
  
  ![qt gruvbox dark](assets/qt-gruvbox-dark.webp)
- Gruvbox Light
  
  ![qt gruvbox light](assets/qt-gruvbox-light.webp)

### WebUI
- (coming soon)

## 🧑‍💻 Development

### Architecture

This repository contains:

```
.
├── gen.sh              # POSIX-compliant build script
├── themes/             # Theme definitions (JSON)
│   ├── dracula.json
│   ├── dark.json
│   └── ...
├── template/
│   ├── qt/             # Qt client templates
│   │   ├── stylesheet.qss.template
│   │   ├── config.json.template
│   │   └── icons/
│   └── webui/          # WebUI base + theme override
│       ├── private/
│       │   └── css/
│       │       └── theme.css.template
│       └── ...
├── qt/                 # Build output: .qbtheme files
└── webui/              # Build output: archives
```

### Qt Client Themes
**Format**: A single `.qbtheme` bundle loaded by qBittorrent's Qt client at runtime.

**Contents**:
- `stylesheet.qss` — Qt Style Sheet (CSS-like syntax)
- `config.json` — Palette and semantic colors
- `icons/` — Optional SVG resources (e.g., custom checkboxes)

**Templates** (`template/qt/`):
- `stylesheet.qss.template` and `config.json.template` use placeholders like `%BG_PRIMARY%`, `%FG_PRIMARY%`, `%ACCENT%`
- `icons/` directory contains SVGs referenced in QSS: `url(:/uitheme/icons/checkbox_checked.svg)`

**Build Process** (`./gen.sh`):
1. Reads color definitions from `themes/<name>.json` using `jq`
2. Generates `stylesheet.qss` and `config.json` via token substitution (sed)
3. Compiles resources with `rcc` → `qt/<name>.qbtheme`

**Compatibility**:
- **qBittorrent v4.6.0+** (Qt6-based) — fully supported
- **qBittorrent < v4.6.0** (Qt5) — generally works, minor visual differences possible

**Adding Custom Icons**:
- Place SVGs in `template/qt/icons/`
- Reference them in QSS: `url(:/uitheme/icons/your_icon.svg)`

### WebUI Themes

**Format**: Regular file tree packed as `.tar.gz` or `.zip` (qbittorrent-nox requires regular files, no symlinks)

**Source Template** (`template/webui/`):
- Based on qBittorrent's stock WebUI
- Includes `private/css/theme.css.template` — theme override loaded **last** to ensure priority

**Theme CSS**:
- Exposes CSS variables mapped from the same JSON color tokens:
  - `--bg-primary`, `--fg-primary`, `--accent`
  - Status colors: `--status-downloading`, `--status-paused`, etc.
- Ensures visual consistency between WebUI and Qt client

**Build Process** (`./gen.sh`):
1. Copies `template/webui/` to a temporary directory
2. Renders `theme.css` from `theme.css.template` using JSON color tokens
3. Creates archives: `webui/<name>.tar.gz` (and `.zip` if available)

**Customization**:
- **Icons**: Replace files in `private/images/` with same filenames
- **Additional CSS**: Edit `theme.css.template` and rebuild

### Creating a New Theme

1. **Create a theme definition**:
   ```bash
   cp themes/dracula.json themes/mytheme.json
   ```

2. **Edit color tokens** in `themes/mytheme.json`:
   ```json
   {
     "name": "My Theme",
     "author": "Your Name",
     "description": "A beautiful custom theme",
     "colors": {
       "BG_PRIMARY": "#1e1e2e",
       "FG_PRIMARY": "#cdd6f4",
       "ACCENT": "#89b4fa",
       ...
     }
   }
   ```
   
   **Required tokens**: See existing themes for the full list of color keys.

3. **Build the theme**:
   ```bash
   ./gen.sh themes/mytheme.json
   ```

4. **Output artifacts**:
   - `qt/mytheme.qbtheme`
   - `webui/mytheme.tar.gz`
   - `webui/mytheme.zip` (if `zip` is installed)

## ⚙️ Compatibility

- **qBittorrent v4.6.0+** (Qt6) — Fully tested and supported
- **qBittorrent < v4.6.0** (Qt5) — Generally compatible, minor rendering differences may occur
- **WebUI** — Works with all qBittorrent versions supporting alternative WebUI

## 🤝 Contributing

Contributions are welcome! To add a new theme:

1. Fork this repository
2. Create a new theme JSON in `themes/`
3. Test locally with `./gen.sh`
4. Submit a pull request

For bug reports or feature requests, please [open an issue](https://github.com/MahdiMirzadeh/qbittorrent/issues).

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

Theme generator and templates by [Mahdi Mirzadeh](https://github.com/MahdiMirzadeh). Built for the [qBittorrent project](https://www.qbittorrent.org/).
