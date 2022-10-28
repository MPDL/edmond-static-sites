#!/bin/bash
#
#set -ev; #error fixing
#set -xv; #debug
#set -nv; #check syntax
#

function help {
   cat << EOF

   The purpose of this script is to deploy static pages for Edmond.
   For more info see:
    https://github.com/MPDL/dataverse/issues/15

   Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-k unblock-key]
   Available options:
      -h          Print this Help.
      -s server   Environment's host server.
      -d docroot  Web files location (mandatory).

EOF
  exit
}
PROYECT-HOME=`dirname $(readlink -f $0)`
DOCROOT="${HOME}/.."

while getopts ":hp:d:" option; do
   case $option in
      h) help
         exit;;
      p) PROYECT-HOME=${OPTARG};;
      d) DOCROOT=${OPTARG};;
     \?) # Invalid option
         echo "${0}: Invalid option (try option -h for help)"
         exit;;
   esac
done

if [ -z ${DOCROOT} ]; then
  echo "${0}: missing mandatory parameter -d!"
  exit;;
}

readonly PAGES="${DOCROOT}/guides"
readonly LOG="/tmp/$(basename "${0}").$(date +'%s').log";
export LOG;


printf "\n\n Preparing destination folders:\n" | tee -a "${LOG}"
function create_dir {
  if [ ! -d "${1}" ]; then
    if mkdir -p "${1}"; then
      printf "\n\t %s created" "${1}" | tee -a "${LOG}"
      status+=0
    else
      printf "\n\t %s could not be created!" "${1}" | tee -a "${LOG}"
      exit 1
    fi
  else
    printf "\n\t %s already exists" "${1}" | tee -a "${LOG}"
    status+=0
  fi
}

# issue-15
create_dir "${PAGES}"

printf "\n\n Copying resources to destination:\n" | tee -a "${LOG}"
function copy_from_to_with_flags {
    if cp "${3}" "${1}" "${2}";
    then
      printf "\n\t %s copied to %s" "${1}" "${2}" | tee -a "${LOG}"
      status+=0
    else
      printf "\n\t some problem copying %s to %s, this step failed!" "${1}" "${2}" | tee -a "${LOG}"
      status+=1
    fi
}
export -f copy_from_to_with_flags
# issue-15
copy_from_to_with_flags "${PROYECT-HOME}/guides" "${PAGES}" "-RT"


if [ ${status} -eq 0 ]; then
  printf "\n... DONE!\n"
  exit 0
else
  printf "\n... sorry, some step fails!\nsome hints: %s... for more info see %s\n" "${status}" "${LOG}"
  exit 2
fi
