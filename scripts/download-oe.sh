  echo version=$1
  echo release=$2
  ls ${PWD}
  docker run -v ${PWD}/build:/binaries/oe progressofficial/oe_installer:$1
  ls -l ${PWD}/build
  ls ${PWD}
  mv ${PWD}/src/PROGRESS_OE.tar.gz ${PWD}/src/PROGRESS_PATCH_OE.tar.gz
  docker run -v ${PWD}/build:/binaries/oe progressofficial/oe_installer:$2
  ls -l ${PWD}/build