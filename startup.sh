#!/bin/sh
set -o nounset
set -o errexit
set -o pipefail

mkdir -p $DATA_DIR

chown foundry:foundry $DATA_DIR

release_filename="/data/container_cache/foundryvtt-${FOUNDRY_VERSION}.zip"

echo "Mounting GCS Fuse."
gcsfuse --uid $FOUNDRY_UID --gid $FOUNDRY_GID -o allow_other $BUCKET $DATA_DIR
echo "Mounting completed."

echo "Clearing old lock file."
rm -rf $DATA_DIR/Config/options.json.lock

echo "Loading Foundry installation."
unzip -q "${release_filename}" 'resources/*'
echo "Done loading."

su-exec "${FOUNDRY_UID}:${FOUNDRY_GID}" ./launcher.sh resources/app/main.mjs --port=30000 --headless --noupdate --dataPath=$DATA_DIR
