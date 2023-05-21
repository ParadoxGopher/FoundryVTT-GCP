#!/bin/sh
# shellcheck disable=SC3010,SC3046,SC3051
# SC3010 - busybox supports [[ ]]
# SC3046 - busybox supports source command
# SC3051 - busybox supports source command

set -o nounset
set -o errexit
set -o pipefail

mkdir -p $DATA_DIR

chown foundry:foundry $DATA_DIR

echo "Mounting GCS Fuse."
gcsfuse --uid $FOUNDRY_UID --gid $FOUNDRY_GID -o allow_other $BUCKET $DATA_DIR
echo "Mounting completed."

echo "Clearing old lock file."
rm -rf $DATA_DIR/Config/options.json.lock

if [ "$SKIP_INSTALL" = "true" ]; then
	echo "Loading Foundry installation."
	release_filename="/data/container_cache/foundryvtt-${FOUNDRY_VERSION}.zip"
	unzip -q "${release_filename}" 'resources/*'
	echo "Done loading."

	su-exec "${FOUNDRY_UID}:${FOUNDRY_GID}" ./launcher.sh resources/app/main.mjs --port=30000 --headless --noupdate --dataPath=$DATA_DIR
else
	./entrypoint.sh resources/app/main.mjs --port=30000 --headless --noupdate --dataPath=$DATA_DIR
fi
