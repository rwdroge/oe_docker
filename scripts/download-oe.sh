  echo oeversion=$1
  echo release=$2
  
  docker run -v ${PWD}/build/installer:/target ghcr.io/rwdroge/oe_installer:$1
  sudo mv ${PWD}/build/installer/PROGRESS_OE.tar.gz ${PWD}/build/installer/PROGRESS_PATCH_OE.tar.gz
  docker run -v ${PWD}/build/installer:/target ghcr.io/rwdroge/oe_installer:$2
  ls -l ${PWD}/build/installer