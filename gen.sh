#!/bin/sh
# qBittorrent theme generator (POSIX shell)
# Generates Qt client themes (.qbtheme), WebUI archives, and color palette SVGs

set -e

# Default configuration
TEMPLATE_DIR=${TEMPLATE_DIR:-template/qt}
TEMPLATE_WEBUI_DIR=${TEMPLATE_WEBUI_DIR:-template/webui}
OUTPUT_DIR_QT=${OUTPUT_DIR_QT:-qt}
OUTPUT_DIR_WEBUI=${OUTPUT_DIR_WEBUI:-webui}
OUTPUT_DIR_ASSETS=${OUTPUT_DIR_ASSETS:-assets}

# Build flags (can be overridden)
BUILD_QT=${BUILD_QT:-1}
BUILD_WEBUI=${BUILD_WEBUI:-1}
BUILD_PALETTE=${BUILD_PALETTE:-1}

show_usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [THEME_FILE]

Generate qBittorrent themes from JSON definitions.

Options:
  -h, --help           Show this help message
  -q, --qt-only        Build only Qt client themes
  -w, --webui-only     Build only WebUI themes
  -p, --palette-only   Generate only color palette SVGs
  --no-qt              Skip Qt client theme generation
  --no-webui           Skip WebUI theme generation
  --no-palette         Skip palette SVG generation

Arguments:
  THEME_FILE           Path to a single theme JSON file (optional)
                       If not provided, builds all themes in themes/*.json

Examples:
  $0                          # Build all themes
  $0 themes/dracula.json      # Build single theme
  $0 --qt-only                # Build only Qt themes for all
  $0 --palette-only           # Generate only palette SVGs

EOF
    exit 0
}

# Check dependencies
check_deps() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required but not installed."
        exit 1
    fi
    if [ "$BUILD_QT" = "1" ] && ! command -v rcc >/dev/null 2>&1; then
        echo "Error: rcc (Qt Resource Compiler) is required but not installed."
        exit 1
    fi
}

check_deps

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: template directory '$TEMPLATE_DIR' not found"
    exit 1
fi

# Generate color palette SVG for a theme
gen_palette() {
    theme_file=$1
    theme_name=$(basename "$theme_file" .json)
    output_file="$OUTPUT_DIR_ASSETS/palette-${theme_name}.svg"
    
    mkdir -p "$OUTPUT_DIR_ASSETS"
    
    # Extract 8 key colors for 2x4 grid
    bg_primary=$(jq -r '.colors.BG_PRIMARY' "$theme_file")
    bg_secondary=$(jq -r '.colors.BG_SECONDARY' "$theme_file")
    fg_primary=$(jq -r '.colors.FG_PRIMARY' "$theme_file")
    accent=$(jq -r '.colors.ACCENT' "$theme_file")
    status_downloading=$(jq -r '.colors.STATUS_DOWNLOADING' "$theme_file")
    status_uploading=$(jq -r '.colors.STATUS_UPLOADING' "$theme_file")
    status_paused=$(jq -r '.colors.STATUS_PAUSED' "$theme_file")
    status_error=$(jq -r '.colors.STATUS_ERROR' "$theme_file")
    
    # Create SVG with 2x4 grid (80x40px)
    cat > "$output_file" <<EOF
<svg width="80" height="40" xmlns="http://www.w3.org/2000/svg">
  <rect x="0" y="0" width="20" height="20" fill="$bg_primary"/>
  <rect x="20" y="0" width="20" height="20" fill="$bg_secondary"/>
  <rect x="40" y="0" width="20" height="20" fill="$fg_primary"/>
  <rect x="60" y="0" width="20" height="20" fill="$accent"/>
  <rect x="0" y="20" width="20" height="20" fill="$status_downloading"/>
  <rect x="20" y="20" width="20" height="20" fill="$status_uploading"/>
  <rect x="40" y="20" width="20" height="20" fill="$status_paused"/>
  <rect x="60" y="20" width="20" height="20" fill="$status_error"/>
</svg>
EOF
    
    echo "  -> Generated palette: $output_file"
}

# Build one theme from JSON
build_one() {
    THEME_FILE=$1
    OUTPUT_QBT=$2

    THEME_NAME=$(basename "$THEME_FILE" .json)
    OUTPUT_QBT=${OUTPUT_QBT:-${OUTPUT_DIR_QT}/${THEME_NAME}.qbtheme}

    if [ ! -f "$THEME_FILE" ]; then
        echo "Error: Theme file '$THEME_FILE' not found"
        return 1
    fi

    echo "Building theme: $THEME_NAME"
    
    # Generate palette SVG if enabled
    if [ "$BUILD_PALETTE" = "1" ]; then
        gen_palette "$THEME_FILE"
    fi
    
    # Skip Qt/WebUI if not enabled
    if [ "$BUILD_QT" != "1" ] && [ "$BUILD_WEBUI" != "1" ]; then
        return 0
    fi

    # Build sed substitution script from theme colors
    TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t qbt_theme.XXXXXX)
    SED_SCRIPT="$TEMP_DIR/subst.sed"
    : > "$SED_SCRIPT"
    jq -r '.colors | to_entries[] | "\(.key)=\(.value)"' "$THEME_FILE" | while IFS='=' read -r key value; do
        esc_value=$(printf '%s' "$value" | sed -e 's/[\\\/&|]/\\&/g')
        printf 's|%%%s%%|%s|g\n' "$key" "$esc_value" >> "$SED_SCRIPT"
    done

    # Build Qt client theme
    if [ "$BUILD_QT" = "1" ]; then
        echo "  -> Building Qt client theme"
        
        # Generate stylesheet.qss and config.json
        sed -f "$SED_SCRIPT" "$TEMPLATE_DIR/stylesheet.qss.template" > "$TEMP_DIR/stylesheet.qss"
        sed -f "$SED_SCRIPT" "$TEMPLATE_DIR/config.json.template" > "$TEMP_DIR/config.json"

        # Copy and process icons directory if present
        if [ -d "$TEMPLATE_DIR/icons" ]; then
            mkdir -p "$TEMP_DIR/icons"
            for icon in "$TEMPLATE_DIR/icons"/*; do
                if [ -f "$icon" ]; then
                    icon_name=$(basename "$icon")
                    if [ "${icon_name##*.}" = "svg" ]; then
                        # Apply color substitution to SVG files
                        sed -f "$SED_SCRIPT" "$icon" > "$TEMP_DIR/icons/$icon_name"
                    else
                        # Copy non-SVG files as-is
                        cp "$icon" "$TEMP_DIR/icons/$icon_name"
                    fi
                fi
            done
        fi

        # Create resources.qrc
        cat > "$TEMP_DIR/resources.qrc" <<\EOF
<!DOCTYPE RCC><RCC version="1.0">
  <qresource>
    <file>stylesheet.qss</file>
    <file>config.json</file>
EOF
        if [ -d "$TEMP_DIR/icons" ]; then
            (
                cd "$TEMP_DIR" || exit 1
                find icons -type f -print | while IFS= read -r f; do
                    printf '    <file>%s</file>\n' "$f"
                done
            ) >> "$TEMP_DIR/resources.qrc"
        fi
        cat >> "$TEMP_DIR/resources.qrc" <<\EOF
  </qresource>
</RCC>
EOF

        # Compile .qbtheme
        OLDPWD=$PWD
        cd "$TEMP_DIR" || exit 1
        mkdir -p "$(dirname "$OUTPUT_QBT")"
        rcc resources.qrc -o "$(basename "$OUTPUT_QBT")" -binary
        cd "$OLDPWD" || exit 1

        mkdir -p "$(dirname "$OUTPUT_QBT")"
        mv "$TEMP_DIR/$(basename "$OUTPUT_QBT")" "$OUTPUT_QBT"
        echo "     -> Created: $OUTPUT_QBT"
    fi

    # Build WebUI archive if enabled
    if [ "$BUILD_WEBUI" = "1" ] && [ -d "$TEMPLATE_WEBUI_DIR" ] && [ -f "$TEMPLATE_WEBUI_DIR/private/css/theme.css.template" ]; then
        echo "  -> Building WebUI theme"
        ARCHIVE_ROOT_NAME=webui-${THEME_NAME}
        ARCHIVE_BASENAME=${ARCHIVE_ROOT_NAME}

        TMP_WEBUI_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t qbt_webui.XXXXXX)
        TMP_WEBUI_DIR="$TMP_WEBUI_BASE/$ARCHIVE_ROOT_NAME"
        mkdir -p "$TMP_WEBUI_DIR"

        cp -a "$TEMPLATE_WEBUI_DIR"/. "$TMP_WEBUI_DIR"/
        sed -f "$SED_SCRIPT" "$TEMPLATE_WEBUI_DIR/private/css/theme.css.template" > "$TMP_WEBUI_DIR/private/css/theme.css"
        rm -f "$TMP_WEBUI_DIR/private/css/theme.css.template"

        mkdir -p "$OUTPUT_DIR_WEBUI"
        tar -C "$TMP_WEBUI_BASE" -czf "$OUTPUT_DIR_WEBUI/${ARCHIVE_BASENAME}.tar.gz" "$ARCHIVE_ROOT_NAME"
        echo "     -> Created: $OUTPUT_DIR_WEBUI/${ARCHIVE_BASENAME}.tar.gz"
        if command -v zip >/dev/null 2>&1; then
            ( cd "$TMP_WEBUI_BASE" && zip -qr "$OLDPWD/$OUTPUT_DIR_WEBUI/${ARCHIVE_BASENAME}.zip" "$ARCHIVE_ROOT_NAME" ) >/dev/null 2>&1 || true
            if [ -f "$OUTPUT_DIR_WEBUI/${ARCHIVE_BASENAME}.zip" ]; then
                echo "     -> Created: $OUTPUT_DIR_WEBUI/${ARCHIVE_BASENAME}.zip"
            fi
        fi
        rm -rf "$TMP_WEBUI_BASE"
    fi

    rm -rf "$TEMP_DIR"
}

# Parse arguments
THEME_FILE=""
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            show_usage
            ;;
        -q|--qt-only)
            BUILD_QT=1
            BUILD_WEBUI=0
            BUILD_PALETTE=0
            shift
            ;;
        -w|--webui-only)
            BUILD_QT=0
            BUILD_WEBUI=1
            BUILD_PALETTE=0
            shift
            ;;
        -p|--palette-only)
            BUILD_QT=0
            BUILD_WEBUI=0
            BUILD_PALETTE=1
            shift
            ;;
        --no-qt)
            BUILD_QT=0
            shift
            ;;
        --no-webui)
            BUILD_WEBUI=0
            shift
            ;;
        --no-palette)
            BUILD_PALETTE=0
            shift
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            ;;
        *)
            THEME_FILE="$1"
            shift
            ;;
    esac
done

# Build themes
if [ -n "$THEME_FILE" ]; then
    # Build single theme
    build_one "$THEME_FILE"
else
    # Build all themes in themes/
    found=0
    for f in themes/*.json; do
        [ -e "$f" ] || continue
        found=1
        build_one "$f"
    done
    if [ $found -eq 0 ]; then
        echo "Error: No theme files found in themes/"
        echo "Run '$0 --help' for usage information."
        exit 1
    fi
fi
