MONO_VERSIONS_PATH='/Library/Frameworks/Mono.framework/Versions'
TMPMOUNT=`/usr/bin/mktemp -d /tmp/visualstudio.XXXX`

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

installNuget() {
  local MONO_VERSION=$1
  local NUGET_VERSION=$2
  local NUGET_URL="https://dist.nuget.org/win-x86-commandline/v${NUGET_VERSION}/nuget.exe"
  echo "Installing nuget $NUGET_VERSION for Mono $MONO_VERSION"
  cd ${MONO_VERSIONS_PATH}/${MONO_VERSION}/lib/mono/nuget
  sudo mv nuget.exe nuget_old.exe

  pushd $TMPMOUNT
  download_with_retries $NUGET_URL "." "nuget.exe"
  sudo chmod a+x nuget.exe
  sudo mv nuget.exe ${MONO_VERSIONS_PATH}/${MONO_VERSION}/lib/mono/nuget
  popd
}

installNuget "6.12.0" "5.9.1"
