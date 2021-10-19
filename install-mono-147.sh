MONO_VERSION="6.12.0.147"
MONO_VERSIONS_PATH='/Library/Frameworks/Mono.framework/Versions'
TMPMOUNT=`/usr/bin/mktemp -d /tmp/visualstudio.XXXX`
TMPMOUNT_FRAMEWORKS="$TMPMOUNT/frameworks"

mkdir -p $TMPMOUNT_FRAMEWORKS/mono

download_with_retries() {
# Due to restrictions of bash functions, positional arguments are used here.
# In case if you using latest argument NAME, you should also set value to all previous parameters.
# Example: download_with_retries $ANDROID_SDK_URL "." "android_sdk.zip"
    local URL="$1"
    local DEST="${2:-.}"
    local NAME="${3:-${URL##*/}}"
    local COMPRESSED="$4"

    if [[ $COMPRESSED == "compressed" ]]; then
        COMMAND="curl $URL -4 -sL --compressed -o '$DEST/$NAME'"
    else
        COMMAND="curl $URL -4 -sL -o '$DEST/$NAME'"
    fi

    echo "Downloading $URL..."
    retries=20
    interval=30
    while [ $retries -gt 0 ]; do
        ((retries--))
        eval $COMMAND
        if [ $? != 0 ]; then
            echo "Unable to download $URL, next attempt in $interval sec, $retries attempts left"
            sleep $interval
        else
            echo "$URL was downloaded successfully to $DEST/$NAME"
            return 0
        fi
    done

    echo "Could not download $URL"
    return 1
}

downloadAndInstallPKG() {
  local PKG_URL=$1
  local PKG_NAME=${PKG_URL##*/}

  download_with_retries $PKG_URL

  echo "Installing $PKG_NAME..."
  sudo installer -pkg "$TMPMOUNT/$PKG_NAME" -target /
}

installNunitConsole() {
  local MONO_VERSION=$1
  NUNIT3_CONSOLE_BIN=nunit3-console

  cat <<EOF > ${TMPMOUNT}/${NUNIT3_CONSOLE_BIN}
#!/bin/bash -e -o pipefail
exec /Library/Frameworks/Mono.framework/Versions/${MONO_VERSION}/bin/mono --debug \$MONO_OPTIONS $NUNIT3_PATH/nunit3-console.exe "\$@"
EOF
  sudo chmod +x ${TMPMOUNT}/${NUNIT3_CONSOLE_BIN}
  sudo mv ${TMPMOUNT}/${NUNIT3_CONSOLE_BIN} ${MONO_VERSIONS_PATH}/${MONO_VERSION}/Commands/${NUNIT3_CONSOLE_BIN}
}

buildMonoDownloadUrl() {
  echo "https://download.mono-project.com/archive/6.12.0/macos-10-universal/MonoFramework-MDK-${1}.macos10.xamarin.universal.pkg"
#  echo "https://dl.xamarin.com/MonoFrameworkMDK/Macx86/MonoFramework-MDK-${1}.macos10.xamarin.universal.pkg"
}

installMono() {
  local VERSION=$1

  echo "Installing Mono ${VERSION}..."
  local MONO_FOLDER_NAME=$(echo $VERSION | cut -d. -f 1,2,3)
  local SHORT_VERSION=$(echo $VERSION | cut -d. -f 1,2)
  local PKG_URL=$(buildMonoDownloadUrl $VERSION)
  downloadAndInstallPKG $PKG_URL

  echo "Installing nunit3-console for Mono "$VERSION
  installNunitConsole $MONO_FOLDER_NAME
  
  echo "Creating short symlink '${SHORT_VERSION}'"
  sudo ln -s ${MONO_VERSIONS_PATH}/${MONO_FOLDER_NAME} ${MONO_VERSIONS_PATH}/${SHORT_VERSION}

  echo "Move to backup folder"
  sudo mv -v $MONO_VERSIONS_PATH/* $TMPMOUNT_FRAMEWORKS/mono/
}

pushd $TMPMOUNT


installMono $MONO_VERSION
sudo mv -v $TMPMOUNT_FRAMEWORKS/mono/* $MONO_VERSIONS_PATH/


popd
