#!/bin/sh
# Modern qBittorrent theme generator (POSIX shell)
# Usage:
#   ./gen.sh <theme.json> [output.qbtheme]
#   ./gen.sh            # builds all themes in themes/*.json

set -e

# Check dependencies once
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed."
    exit 1
fi
if ! command -v rcc >/dev/null 2>&1; then
    echo "Error: rcc (Qt Resource Compiler) is required but not installed."
    exit 1
fi

TEMPLATE_DIR=${TEMPLATE_DIR:-template/qt}
TEMPLATE_WEBUI_DIR=${TEMPLATE_WEBUI_DIR:-template/webui}

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "Error: template directory '$TEMPLATE_DIR' not found"
    exit 1
fi

# function: build one theme from JSON
build_one() {
    THEME_FILE=$1
    OUTPUT_QBT=$2

    THEME_NAME=$(basename "$THEME_FILE" .json)
    OUTPUT_QBT=${OUTPUT_QBT:-qt/${THEME_NAME}.qbtheme}

    if [ ! -f "$THEME_FILE" ]; then
        echo "Error: Theme file '$THEME_FILE' not found"
        return 1
    fi

    echo "Generating qBittorrent theme from $THEME_FILE..."

    TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t qbt_theme.XXXXXX)

    # Build sed substitution script from theme colors
    SED_SCRIPT="$TEMP_DIR/subst.sed"
    : > "$SED_SCRIPT"
    jq -r '.colors | to_entries[] | "\(.key)=\(.value)"' "$THEME_FILE" | while IFS='=' read -r key value; do
        esc_value=$(printf '%s' "$value" | sed -e 's/[\\\/&|]/\\&/g')
        printf 's|%%%s%%|%s|g\n' "$key" "$esc_value" >> "$SED_SCRIPT"
    done

    # Generate stylesheet.qss and config.json
    echo "  -> Generating stylesheet.qss"
    sed -f "$SED_SCRIPT" "$TEMPLATE_DIR/stylesheet.qss.template" > "$TEMP_DIR/stylesheet.qss"
    echo "  -> Generating config.json"
    sed -f "$SED_SCRIPT" "$TEMPLATE_DIR/config.json.template" > "$TEMP_DIR/config.json"

    # Copy icons directory if present
    if [ -d "$TEMPLATE_DIR/icons" ]; then
        echo "  -> Copying icons/ directory"
        cp -R "$TEMPLATE_DIR/icons" "$TEMP_DIR"/
    fi

    # Create resources.qrc
    echo "  -> Creating resources.qrc"
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
    echo "  -> Compiling $OUTPUT_QBT"
    OLDPWD=$PWD
    cd "$TEMP_DIR" || exit 1
    mkdir -p "$(dirname "$OUTPUT_QBT")"
    rcc resources.qrc -o "$(basename "$OUTPUT_QBT")" -binary
    cd "$OLDPWD" || exit 1

    mkdir -p "$(dirname "$OUTPUT_QBT")"
    mv "$TEMP_DIR/$(basename "$OUTPUT_QBT")" "$OUTPUT_QBT"
    echo "Theme created successfully: $OUTPUT_QBT"

    # Build WebUI archive if template exists
    if [ -d "$TEMPLATE_WEBUI_DIR" ] && [ -f "$TEMPLATE_WEBUI_DIR/private/css/theme.css.template" ]; then
        WEBUI_ARCHIVE_DIR=${WEBUI_ARCHIVE_DIR:-webui}
        ARCHIVE_BASENAME=${THEME_NAME}
        ARCHIVE_ROOT_NAME=${ARCHIVE_ROOT_NAME:-webui-${THEME_NAME}}
        echo "  -> Building WebUI archive"

        TMP_WEBUI_BASE=$(mktemp -d 2>/dev/null || mktemp -d -t qbt_webui.XXXXXX)
        TMP_WEBUI_DIR="$TMP_WEBUI_BASE/$ARCHIVE_ROOT_NAME"
        mkdir -p "$TMP_WEBUI_DIR"

        cp -a "$TEMPLATE_WEBUI_DIR"/. "$TMP_WEBUI_DIR"/
        sed -f "$SED_SCRIPT" "$TEMPLATE_WEBUI_DIR/private/css/theme.css.template" > "$TMP_WEBUI_DIR/private/css/theme.css"
        rm -f "$TMP_WEBUI_DIR/private/css/theme.css.template"

        mkdir -p "$WEBUI_ARCHIVE_DIR"
        tar -C "$TMP_WEBUI_BASE" -czf "$WEBUI_ARCHIVE_DIR/${ARCHIVE_BASENAME}.tar.gz" "$ARCHIVE_ROOT_NAME"
        echo "     -> Wrote $WEBUI_ARCHIVE_DIR/${ARCHIVE_BASENAME}.tar.gz"
        if command -v zip >/dev/null 2>&1; then
            ( cd "$TMP_WEBUI_BASE" && zip -qr "$OLDPWD/$WEBUI_ARCHIVE_DIR/${ARCHIVE_BASENAME}.zip" "$ARCHIVE_ROOT_NAME" ) || true
        fi
        rm -rf "$TMP_WEBUI_BASE"
    fi

    rm -rf "$TEMP_DIR"
}

# Entry point: single theme or all in themes/
if [ $# -ge 1 ]; then
    build_one "$1" "$2"
else
    # Build all JSONs under themes/; if none found, print usage
    found=0
    for f in themes/*.json; do
        [ -e "$f" ] || continue
        found=1
        build_one "$f"
    done
    if [ $found -eq 0 ]; then
        echo "Usage: $0 <theme.json> [output.qbtheme]"
        echo "Or place theme files in themes/*.json and run: $0"
        exit 1
    fi
fi
