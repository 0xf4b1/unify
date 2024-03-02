#!/bin/bash

UNITY_REPO="${UNITY_REPO:-"$HOME/Unity/Hub/Editor"}"
UNITY_VARIANT="${UNITY_VARIANT:-linux64_withgfx_nondevelopment_mono}"
UNITY_ENGINE_PREFIX="${UNITY_ENGINE_PREFIX:-Editor/Data/PlaybackEngines/LinuxStandaloneSupport/Variations}"

echo $1

# Determine Unity engine version
res=`find "$1" -name level0`
[ -z "$res" ] && echo "Can not find level0 file" && exit 1
version=`strings "$res" | head -n 1`
echo "Found Unity version: $version"

# Probe for opengl renderer
DATA_DIR=`dirname "$res"`
strings "$DATA_DIR/Resources/unity_builtin_extra" | grep gl_ >/dev/null
[ ! $? -eq 0 ] && echo "OpenGL renderer not enabled :(" && exit 1

# Check Unity Engine
UNITY_PATH="$UNITY_REPO/$version"
stat "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT" >/dev/null
if [ ! $? -eq 0 ]; then
  stat "$UNITY_PATH/Unity.tar.xz" >/dev/null
  if [ ! $? -eq 0 ]; then
    echo "Unity version not found"
    stat "$UNITY_REPO/archive" >/dev/null
    if [ ! $? -eq 0 ]; then
        echo "Fetching Unity archive ..."
        mkdir -p "$UNITY_REPO"
        curl https://unity.com/releases/editor/archive -o "$UNITY_REPO/archive"
        [ ! $? -eq 0 ] && echo "Could not fetch Unity archive" && exit 1
    fi
    res=`cat $UNITY_REPO/archive | grep unityhub://$version`
    [ -z "$res" ] && echo "Unity version not found in archive" && exit 1
    HASH=${res##*$version/}
    HASH=${HASH%%\"*}
    mkdir "$UNITY_REPO/$version"
    curl "https://download.unity3d.com/download_unity/$HASH/LinuxEditorInstaller/Unity.tar.xz" -o "$UNITY_PATH/Unity.tar.xz"
    [ ! $? -eq 0 ] && echo "Could not fetch Unity engine archive" && exit 1
  fi
  echo "Extracting $UNITY_VARIANT from Unity.tar.xz"
  tar -xf "$UNITY_PATH/Unity.tar.xz" -C "$UNITY_PATH" "$UNITY_ENGINE_PREFIX/$UNITY_VARIANT"
fi

cp -r "$UNITY_PATH/$UNITY_ENGINE_PREFIX/$UNITY_VARIANT"/* "$DATA_DIR/../"
[ ! $? -eq 0 ] && echo "Could not copy Unity Engine files" && exit 1

echo "Unity engine files copied."
