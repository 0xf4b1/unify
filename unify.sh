#!/bin/bash

UNITY_REPO="${UNITY_REPO:-"$HOME/Unity/Hub/Editor"}"
UNITY_VARIANTS=(${UNITY_VARIANTS:-linux64_player_nondevelopment_mono linux64_withgfx_nondevelopment_mono})
UNITY_ENGINE_PREFIX="${UNITY_ENGINE_PREFIX:-Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations}"

die() {
	CODE=$1
	shift
	>&2 echo $*
	exit $CODE
}

echo $1

# Determine Unity engine version
res=`find "$1" -name level0`
[ -z "$res" ] && die 1 Cannot find level0 file
version=`strings "$res" | head -n 1`
echo "Found Unity version: $version"

# Probe for opengl renderer
DATA_DIR=`dirname "$res"`
strings "$DATA_DIR/Resources/unity_builtin_extra" | grep gl_ >/dev/null || die 2 OpenGL renderer not enabled ':('

# Check Unity Engine
UNITY_PATH="$UNITY_REPO/$version"
if [ ! -f "$UNITY_PATH/Unity.tar.xz" ]; then
	echo "Unity version not found locally"
	if [ ! -f "$UNITY_REPO/archive" ]; then
		echo "Fetching Unity archive ..."
		mkdir -p "$UNITY_REPO"
		curl https://unity.com/releases/editor/archive -o "$UNITY_REPO/archive" || die 3 Could not fetch Unity archive
	fi
	res=`cat $UNITY_REPO/archive | grep unityhub://$version`
	[ -z "$res" ] && die 4 Unity version not found in archive
	HASH=${res##*$version/}
	HASH=${HASH%%\"*}
	mkdir "$UNITY_REPO/$version"
	curl "https://download.unity3d.com/download_unity/$HASH/LinuxEditorInstaller/Unity.tar.xz" -o "$UNITY_PATH/Unity.tar.xz" || die 5 Could not fetch Unity engine archive
fi
EXTRACT=true
for UNITY_VARIANT in "${UNITY_VARIANTS[@]}"
do
	if [ -d "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT" ]; then
		EXTRACT=false
		break
	fi
done
if [ "$EXTRACT" = true ]; then
	echo "Extracting ${UNITY_VARIANTS[@]} from Unity.tar.xz"
	# Ignoring error messages, as only one variant is probably in the archive
	tar -xf "$UNITY_PATH/Unity.tar.xz" -C "$UNITY_PATH" "${UNITY_VARIANTS[@]/#/$UNITY_ENGINE_PREFIX/}" > /dev/null 2>&1
fi
for UNITY_VARIANT in "${UNITY_VARIANTS[@]}"
do
	if [ -d "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT" ]; then
		cp -r "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT"/* "$DATA_DIR/../" || die 6 Could not copy Unity Engine files

		echo "Unity engine files copied."
		exit 0
	fi
done

die 7 None of the UNITY_VARIANTS found in the Unity engine archive
