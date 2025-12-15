#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Project root = one level above /operation
OPERATION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Paths inside operation
DOCKER_DIR="$OPERATION_ROOT/Docker/"
SCRIPTS_DIR="$OPERATION_ROOT/scripts/"
k8S_DIR="$OPERATION_ROOT/k8s/"
usage () {
  echo "[Usage]: <${0}> [-d] [-s] [-b] "
  echo "   ============================== "
  echo "    -b   - building image"
  echo "    -d   - Deploy Container"
  echo "    -s   - Stop Container"
  echo "    -r   - Remove Container image"
  echo "   ============================== "
  exit 1
}
no_opts () {
  echo "Pls provide a valid option to run the script"
  echo "Try ${0} '-h' or '--help' for more "
  exit 1

}
for arg in "${@}"; do
  if [[ "$arg" == '--help' ]]; then
    usage 
  exit 0
  fi
done
while getopts "pbdsrh"  opts; do
  case  "${opts}" in
  b)  cd "${DOCKER_DIR}" ; "${SCRIPT_DIR}"/build.sh ; cd - ;;
  p)  cd "${DOCKER_DIR}" ; "${SCRIPT_DIR}"/build.sh p ; cd - ;;
  d)  cd "${k8S_DIR}" ; "${SCRIPT_DIR}"/deploy.sh ; cd - ;;
  s) cd "${k8S_DIR}" ; "${SCRIPT_DIR}"/options.sh ; cd - ;;
  r) cd "${DOCKER_DIR}" ; "${SCRIPT_DIR}"/options.sh r ; cd - ;;
  h) usage ; exit 1 ;;
  ?) no_opts ; exit 1 ;; 
 esac
done
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

