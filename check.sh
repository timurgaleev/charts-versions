#!/bin/bash

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

DIR_NAME=$(dirname $0)

REPOSITORY="timurgaleev/charts-versions"

CHARTS=${DIR_NAME}/target/charts.txt

_init() {
  rm -rf ${DIR_NAME}/target

  mkdir -p ${DIR_NAME}/target
  mkdir -p ${DIR_NAME}/versions

  cp -rf ${DIR_NAME}/versions ${DIR_NAME}/target/
}

_search() {
  helm version --client --short

  while read LINE; do
    helm repo add ${LINE}
  done <${DIR_NAME}/repos.txt
  echo

  helm search repo -o json | jq '.[] | "\"\(.name)\" \(.version) \(.app_version)"' -r >${CHARTS}
}

_check() {
  printf '# %-50s %-20s %-20s\n' "NAME" "NOW" "NEW"

  while read LINE; do
    _check_version ${LINE}
  done <${DIR_NAME}/checklist.txt
  echo
}

_check_version() {
  CHART="$1"
  CHART_URL="$2"

  REPO="$(echo ${CHART} | cut -d'/' -f1)"
  NAME="$(echo ${CHART} | cut -d'/' -f2)"

  touch ${DIR_NAME}/versions/${NAME}
  NOW="$(cat ${DIR_NAME}/versions/${NAME} | xargs)"

  NEW="$(cat ${CHARTS} | grep "\"${CHART}\"" | awk '{print $2" ("$3")"}' | xargs)"

  printf '# %-50s %-20s %-20s\n' "${CHART}" "${NOW}" "${NEW}"

  printf "${NEW}" >${DIR_NAME}/versions/${NAME}

  if [ "${NOW}" == "${NEW}" ]; then
    return
  fi

  if [ -z "${SLACK_TOKEN}" ]; then
    return
  fi
}

_message() {
  printf "$(date +%Y%m%d-%H%M)" >${DIR_NAME}/target/message.txt
}

_run() {
  _init

  _search

  _check

  _message
}

_run
