#!/bin/bash

UNITY_REPO="${UNITY_REPO:-"$HOME/Unity/Hub/Editor"}"
UNITY_VARIANT="${UNITY_VARIANT:-linux64_withgfx_nondevelopment_mono}"
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
if [ ! -d "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT" ]; then
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
  echo "Extracting $UNITY_VARIANT from Unity.tar.xz"
  tar -xf "$UNITY_PATH/Unity.tar.xz" -C "$UNITY_PATH" "$UNITY_ENGINE_PREFIX/$UNITY_VARIANT"
fi

cp -r "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT"/* "$DATA_DIR/../" || die 6 Could not copy Unity Engine files

echo "Unity engine files copied."
