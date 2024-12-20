  echo base: ${OE_VERSION}
  echo version: ${env.OE_VERSION}
  
  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${OE_VERSION}
  mv ${PWD}/src/PROGRESS_OE.tar.gz ${PWD}/src/PROGRESS_PATCH_OE.tar.gz
  docker run -v ${PWD}/src:/binaries/oe progressofficial/oe_installer:${{ env.OE_RELEASE}}
  ls -l ${PWD}/src