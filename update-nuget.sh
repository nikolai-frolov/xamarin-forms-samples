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
