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
DOCROOT="${HOME}/.."

while getopts ":hk:p:d:" option; do
   case $option in
      h) help
         exit;;
      k) UNBLOCK="?unblock-key=${OPTARG}";;
      p) PROYECT_HOME=$OPTARG;;
      d) DOCROOT=${OPTARG};;
     \?) # Invalid option
         echo "Invalid option (try option -h for help)"
         exit;;
   esac
done

if [ -z ${DOCROOT} ]; then
  echo "${0}: missing mandatory parameter -d!"
  exit;;
}

readonly HOST="$(hostname)" #HOST="localhost:8080"
readonly API_PROTOCOL="https"

readonly PAGES-DIR="${DOCROOT}/guides"
readonly PAGES-URL="/guides"
readonly API_URL="${API_PROTOCOL}://${HOST}/api/admin/settings/"
readonly LOG="/tmp/$(basename "${0}").$(date +'%s').log";
export LOG;

if [ -n "${UNBLOCK}" ]; then
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
  db_setting_to ":FooterCustomizationFile" "${PAGES-DIR}/mpdl-footer.html"
  db_setting_to ":StyleCustomizationFile" "${PAGES-DIR}/css/mpdl-stylesheet.css"
  # issue-15
  readonly COPYRIGHT=" Max Planck Digital Library"
  db_setting_to ":FooterCopyright" "${COPYRIGHT}"
  db_setting_to ":ApplicationPrivacyPolicyUrl" "${PAGES-URL}/privacy.html"
  db_setting_to ":ApplicationTermsOfUseUrl" "${PAGES-URL}/terms_of_use.html"
  db_setting_to ":ApplicationDisclaimerUrl" "${PAGES-URL}/impressum.html"
  db_setting_to ":NavbarGuidesUrl" "${PAGES-URL}/help.html"
  db_setting_to ":ApplicationTermsOfUse" "@${PAGES-DIR}/mpdl-apptou-signup.txt"
fi

if [ ${status} -eq 0 ]; then
  printf "\n... DONE!\n"
  exit 0
else
  printf "\n... sorry, some step fails!\nsome hints: %s... for more info see %s\n" "${status}" "${LOG}"
  exit 2
fi
