  echo ${OE_VERSION}=$1
  echo ${OE_RELEASE}=$2

  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${OE_VERSION}
  mv ${PWD}/src/PROGRESS_OE.tar.gz ${PWD}/src/PROGRESS_PATCH_OE.tar.gz
  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${OE_RELEASE}
  ls -l ${PWD}/src