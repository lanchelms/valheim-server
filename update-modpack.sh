#!/usr/bin/env bash

NAMESPACE="LanChelms"
MOD="DeepNorthModpack"
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Config Paths
SEASON_CFG="${HOME}/lanchelms-valheim-data/server/BepInEx/config/RustyMods.Seasonality.cfg"
BIOME_CFG="${HOME}/lanchelms-valheim-data/server/BepInEx/config/radamanto.BiomeLock.cfg"

BOSS_KEYS=(
  "08.02 - Eikthyr"
  "08.03 - Elder"
  "08.04 - Bonemass"
  "08.05 - Moder"
  "08.06 - Yagluth"
  "08.07 - Queen"
  "08.08 - Fader"
)

# Initialize associative array to hold the parsed states
declare -A BOSS_VALUES

echo "Fetching latest version for ${NAMESPACE}/${MOD}..."
VERSION=$(curl -s "https://hexium.gg/api/experimental/package/${NAMESPACE}/${MOD}/" | jq -r '.latest.version_number')
[ -z "${VERSION}" ] || [ "${VERSION}" == "null" ] && { echo "Error: Fetch failed."; exit 1; }
# Use custom version passed on command line
[ -z "${1}" ] || { VERSION=${1}; }
DOWNLOAD_URL=$(curl -s "https://hexium.gg/api/experimental/package/${NAMESPACE}/${MOD}/${VERSION}/" | jq -r '.download_url')
[ -z "${DOWNLOAD_URL}" ] || [ "${DOWNLOAD_URL}" == "null" ] && { echo "Error: could not find download url for ${VERSION}."; exit 1; }
echo "Downloading ${VERSION} from ${DOWNLOAD_URL}"
mkdir -p "${BASE_DIR}/tmp/"
OUTPUT_FILE="${BASE_DIR}/tmp/${NAMESPACE}_${MOD}_${VERSION}.zip"
wget -q --show-progress -O "${OUTPUT_FILE}" "${DOWNLOAD_URL}" || { echo "Download failed."; exit 1; }

# --- BACKUP & PARSE DYNAMIC CONFIGS ---
TIMESTAMP=$(date +%s)
SEASON_BAK="${SEASON_CFG}.${TIMESTAMP}.bak"
BIOME_BAK="${BIOME_CFG}.${TIMESTAMP}.bak"

# 1. Seasonality Backup
cp "${SEASON_CFG}" "${SEASON_BAK}"
SEASON=$(grep "^Season =" "${SEASON_BAK}" | cut -d'=' -f2 | xargs)

# 2. BiomeLock Backup & Parse into Associative Array
cp "${BIOME_CFG}" "${BIOME_BAK}"

echo -e "\n--- Current State Parsed ---"
echo "Season: ${SEASON}"
for BOSS in "${BOSS_KEYS[@]}"; do
  VAL=$(grep "^${BOSS} =" "${BIOME_BAK}" | cut -d'=' -f2 | xargs)
  BOSS_VALUES["$BOSS"]="$VAL"
  echo "${BOSS} = ${VAL}"
done
echo "----------------------------"

# Prompt to stop the server
read -p "Ready to apply. Stop the Docker container? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update aborted. The server must be stopped to apply the modpack safely."
    exit 0
fi

(cd "${BASE_DIR}" && docker compose stop)

# --- INSTALL MODPACK ---
echo "Installing modpack..."
cd ~/r2modman-headless
go run . --install-dir ~/lanchelms-valheim-data/server/ --profile-zip "${OUTPUT_FILE}" || { echo "Failed"; exit 1; }

# --- RESTORE DYNAMIC CONFIGS ---
# 1. Seasonality Restore
sed -i "s/^Season =.*/Season = ${SEASON}/" "${SEASON_CFG}"
echo "Restored season to: ${SEASON}"

# 2. BiomeLock Restore
echo "Restoring BiomeLock boss states..."
for BOSS in "${BOSS_KEYS[@]}"; do
  VAL="${BOSS_VALUES[$BOSS]}"
  sed -i "s/^${BOSS} =.*/${BOSS} = ${VAL}/" "${BIOME_CFG}"
  echo "  -> ${BOSS} = ${VAL}"
done

# --- CLEANUP ---
rm -rf ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat/Greylist/**

# greylist
mv ~/lanchelms-valheim-data/server/BepInEx/plugins/ComfyMods-Gizmo ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat/Greylist/
mv ~/lanchelms-valheim-data/server/BepInEx/plugins/Advize-PlantEasily ~/lanchelms-valheim-data/server/BepInEx/config/AzuAntiCheat/Greylist/

# Remove maintenance mode if it was turned on
rm -f ~/lanchelms-valheim-data/server/BepInEx/config/maintenance
sed -i 's/Maintenance Mode = On/Maintenance Mode = Off/g' ~/lanchelms-valheim-data/server/BepInEx/config/org.bepinex.plugins.servercharacters.cfg

# Prompt to start the server
read -p "Update finished. Start the Docker container? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] && (cd "${BASE_DIR}" && docker compose start)

