  echo version=$1
  echo release=$2
  ls ${PWD}
  docker run -v ${PWD}/build/installer:/target progressofficial/oe_installer:$1
  ls -l ${PWD}/build/installer
  cp ${PWD}/build/installer/PROGRESS_OE.tar.gz ${PWD}/build/installer/PROGRESS_PATCH_OE.tar.gz
  rm ${PWD}/build/installer/PROGRESS_OE.tar.gz
  docker run -v ${PWD}/build/installer:/target progressofficial/oe_installer:$2
  ls -l ${PWD}/build/installer