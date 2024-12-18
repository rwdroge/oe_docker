  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${OPENEDGE_VERSION}
  mv ${PWD}/src/PROGRESS_OE.tar.gz ${PWD}/src/PROGRESS_PATCH_OE.tar.gz
  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${OPENEDGE_BASE_VERSION}
  ls -l ${PWD}/src