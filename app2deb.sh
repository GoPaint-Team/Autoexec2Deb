#!/bin/bash

# Default values
CREATE_SHORTCUTS="yes"
VERSION="1.0"
ARCH="all"
APP_NAME="Zohans GoPaint"
ICON_NAME="icon.png"

# Parse arguments
for i in "$@"; do
  case $i in
    --executable=*)
      EXECUTABLE="${i#*=}"
      shift
      ;;
    --create-shortcuts=*)
      CREATE_SHORTCUTS="${i#*=}"
      shift
      ;;
    --app-name=*)
      APP_NAME="${i#*=}"
      shift
      ;;
    --icon=*)
      ICON_PATH="${i#*=}"
      shift
      ;;
    *)
      echo "Unknown option $i"
      exit 1
      ;;
  esac
done

if [[ -z "$EXECUTABLE" ]]; then
  echo "Usage: bash autoexec2deb --executable=\"/path/to/main.py\" [--create-shortcuts=yes|no] [--app-name=MyApp] [--icon=/path/to/icon.png]"
  exit 1
fi

WORKDIR="build_${APP_NAME,,}_deb"
mkdir -p $WORKDIR/DEBIAN
mkdir -p $WORKDIR/usr/bin
mkdir -p $WORKDIR/usr/share/applications
mkdir -p $WORKDIR/usr/share/${APP_NAME,,}
mkdir -p $WORKDIR/usr/share/pixmaps

# Create launcher script
LAUNCHER="$WORKDIR/usr/bin/${APP_NAME,,}"
echo "#!/bin/bash
python3 /usr/share/${APP_NAME,,}/$(basename "$EXECUTABLE")" > "$LAUNCHER"
chmod +x "$LAUNCHER"

# Copy your actual executable
cp "$EXECUTABLE" "$WORKDIR/usr/share/${APP_NAME,,}/"

# Control file
cat <<EOF > $WORKDIR/DEBIAN/control
Package: ${APP_NAME,,}
Version: $VERSION
Section: base
Priority: optional
Architecture: $ARCH
Depends: python3, python3-pyqt5
Maintainer: Zohan Haque
Description: Zohan Haque
EOF

# Optional icon
if [[ -n "$ICON_PATH" ]]; then
  cp "$ICON_PATH" "$WORKDIR/usr/share/pixmaps/${APP_NAME,,}.png"
fi

# .desktop shortcut
if [[ "$CREATE_SHORTCUTS" == "yes" ]]; then
  DESKTOP_FILE="$WORKDIR/usr/share/applications/${APP_NAME,,}.desktop"
  cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=PyQt5 App
Exec=/usr/bin/${APP_NAME,,}
Icon=${APP_NAME,,}
Terminal=true
Categories=Utility;
EOF
  chmod +x "$DESKTOP_FILE"

  # Create postinst for desktop shortcut copy
  mkdir -p "$WORKDIR/DEBIAN"
  cat <<EOF > "$WORKDIR/DEBIAN/postinst"
#!/bin/bash
cp /usr/share/applications/${APP_NAME,,}.desktop /home/\$USER/Desktop/ 2>/dev/null || true
chmod +x /home/\$USER/Desktop/${APP_NAME,,}.desktop 2>/dev/null || true
EOF
  chmod 755 "$WORKDIR/DEBIAN/postinst"
fi

# Build package
dpkg-deb --build "$WORKDIR"
echo "✅ Package built: ${WORKDIR}.deb"
