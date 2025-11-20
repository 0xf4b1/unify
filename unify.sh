#!/bin/bash

UNITY_REPO="${UNITY_REPO:-"$HOME/Unity/Hub/Editor"}"
UNITY_VARIANTS=(${UNITY_VARIANTS:-linux64_player_nondevelopment_mono linux64_withgfx_nondevelopment_mono})
UNITY_ENGINE_PREFIX="${UNITY_ENGINE_PREFIX:-./Variations}"

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

DATA_DIR=`dirname "$res"`

# Check Unity Engine
UNITY_PATH="$UNITY_REPO/$version"
if [ ! -f "$UNITY_PATH/Unity.tar.xz" ]; then
	echo "Unity version not found locally"
	echo "Fetching Unity archive ..."
	mkdir -p "$UNITY_REPO"
	curl --silent -X POST -H "Content-Type: application/json" -d '{"operationName":"GetRelease","variables":{"version":"'$version'","limit":300},"query":"query GetRelease($limit: Int, $skip: Int, $version: String!, $stream: [UnityReleaseStream!]) {\n getUnityReleases(\nlimit: $limit\nskip: $skip\nstream: $stream\nversion: $version\nentitlements: [XLTS]\n ) {\ntotalCount\nedges {\n node {\n version\n entitlements\n releaseDate\n unityHubDeepLink\n stream\n __typename\n }\n __typename\n}\n__typename\n }\n}"}' \
	https://services.unity.com/graphql -o archive || die 3 Could not fetch Unity archive
	HASH=`grep -oE "unityhub://$version/\w+" archive` || die 4 Unity version not found in archive
	HASH=`echo $HASH | cut -d/ -f4`
	# TODO support Mono/IL2CPP variants, e.g.
	# https://download.unity3d.com/download_unity/abdb44fca7f7/MacEditorTargetInstaller/UnitySetup-Linux-Mono-Support-for-Editor-6000.2.13f1.pkg
	# https://download.unity3d.com/download_unity/abdb44fca7f7/MacEditorTargetInstaller/UnitySetup-Linux-IL2CPP-Support-for-Editor-6000.2.13f1.pkg
	URL="https://download.unity3d.com/download_unity/$HASH/MacEditorTargetInstaller/UnitySetup-Linux-Support-for-Editor-$version.pkg"
	mkdir "$UNITY_REPO/$version"
	echo "Downloading Unity from $URL ..."
	curl $URL -o "$UNITY_PATH/Unity.pkg" || die 5 Could not fetch Unity engine archive
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
	echo "Extracting ${UNITY_VARIANTS[@]} from Unity.pkg"
	# Ignoring error messages, as only one variant is probably in the archive
	7z x -o"$UNITY_PATH" "$UNITY_PATH/Unity.pkg"
	7z x -o"$UNITY_PATH" "$UNITY_PATH/Payload~" "${UNITY_VARIANTS[@]/#/$UNITY_ENGINE_PREFIX/}"
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
