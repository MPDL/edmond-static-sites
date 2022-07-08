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
      -h        Print this Help.
      -k key    API unblock-key.

EOF
  exit
}
UNBLOCK=""
PROYECT_HOME=`dirname $(readlink -f $0)`

while getopts ":hk:p:" option; do
   case $option in
      h) help
         exit;;
      k) UNBLOCK="?unblock-key=${OPTARG}";;
      p) PROYECT_HOME=$OPTARG;;
     \?) # Invalid option
         echo "Invalid option (try option -h for help)"
         exit;;
   esac
done

USERNAME="dataverse"
TARGET="/srv/web/payara5/glassfish/domains/domain1/docroot"
case $(hostname) in
  vm97)
    isPROD=false
    HOST="dev-edmond2.mpdl.mpg.de"
    API_PROTOCOL="https"
    ;;
  vm12)
    isPROD=false
    HOST="qa-edmond2.mpdl.mpg.de"
    API_PROTOCOL="https"
    ;;     
  vm64)
    isPROD=true
    HOST="edmond.mpdl.mpg.de"
    API_PROTOCOL="https"
    ;;   
  *)
    isPROD=false
    HOST="localhost:8080"
    API_PROTOCOL="http"
    TARGET="$(whereis payara5 | awk '{print $2}')/glassfish/domains/domain1/docroot"
    ;;
esac

readonly BRANDING="${TARGET}/logos"
readonly PAGES="${TARGET}/guides"
readonly STATIC_PAGES_URL="http://${HOST}/guides"
readonly API_URL="${API_PROTOCOL}://${HOST}/api/admin/settings/"
readonly LOG="/tmp/$(basename "${0}").$(date +'%s').log";
export LOG;

printf "\n\nBranding Installation (process output to -> %s)\n" "${LOG}" | tee -a "${LOG}"

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
# issue-7
create_dir "${BRANDING}"
# issue-15
create_dir "${PAGES}"

printf "\n\n Copying resources to destination:\n" | tee -a "${LOG}"
function copy_from_to_with_flags {
    if cp ${3} "${1}" "${2}";
    then
      printf "\n\t %s copied to %s" "${1}" "${2}" | tee -a "${LOG}"
      status+=0
    else
      printf "\n\t some problem copying %s to %s, this step failed!" "${1}" "${2}" | tee -a "${LOG}"
      status+=1
    fi
}
export -f copy_from_to_with_flags
# issue-7
copy_from_to_with_flags "${PROYECT_HOME}/logos" "${BRANDING}" "-RT"
# issue-15
copy_from_to_with_flags "${PROYECT_HOME}/guides" "${PAGES}" "-RT"

if [ "${UNBLOCK}" ]; then
  printf "\n\n Configuring Settings on Database:\n\n" | tee -a "${LOG}"
  function db_setting_to {
    if [[ ! "${1}" =~ [^:] ]]
    then
      setting=:"${1}"
    else
      setting="${1}"
    fi
    curl -X PUT -d "${2}" "${API_URL}${setting}${UNBLOCK}" --silent | jq '.' | tee -a "${LOG}"
    if [ "${PIPESTATUS[0]}" -eq 0 ]; then
      status+=0
    else
      status+=1
    fi
    printf "\n" | tee -a "${LOG}"
  }

  # issue-7
  db_setting_to ":LogoCustomizationFile" "/logos/navbar/logo_for_bright.png"
  db_setting_to ":FooterCustomizationFile" "${PAGES}/mpdl-footer.html"
  db_setting_to ":StyleCustomizationFile" "${PAGES}/css/mpdl-stylesheet.css"
  # issue-15
  readonly COPYRIGHT=" Max Planck Digital Library"
  db_setting_to ":FooterCopyright" "${COPYRIGHT}"
  db_setting_to ":ApplicationPrivacyPolicyUrl" "${STATIC_PAGES_URL}/privacy.html"
  db_setting_to ":ApplicationTermsOfUseUrl" "${STATIC_PAGES_URL}/terms_of_use.html"
  db_setting_to ":ApplicationDisclaimerUrl" "${STATIC_PAGES_URL}/impressum.html"
  db_setting_to ":NavbarGuidesUrl" "${STATIC_PAGES_URL}/help.html"
  db_setting_to ":ApplicationTermsOfUse" "@${PAGES}/mpdl-apptou-signup.txt"
fi

if [ ${status} -eq 0 ]; then
  printf "\n... DONE!\n"
  exit 0
else
  printf "\n... sorry, some step fails!\nsome hints: %s... for more info see %s\n" "${status}" "${LOG}"
  exit 2
fi