#!/bin/bash

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

SHELL_DIR=$(dirname $0)

REPOSITORY="timurgaleev/charts-versions"

CHARTS=${SHELL_DIR}/target/charts.txt

_verify_version() {
    CHART="$1"
    # CHART_URL="$2"

    REPO="$(echo ${CHART} | cut -d'/' -f1)"
    NAME="$(echo ${CHART} | cut -d'/' -f2)"

    touch ${SHELL_DIR}/versions/${NAME}
    NOW="$(cat ${SHELL_DIR}/versions/${NAME} | xargs)"

    NEW="$(cat ${CHARTS} | grep "\"${CHART}\"" | awk '{print $2" ("$3")"}' | xargs)"

    printf '# %-50s %-20s %-20s\n' "${CHART}" "${NOW}" "${NEW}"

    printf "${NEW}" > ${SHELL_DIR}/versions/${NAME}

    if [ "${NOW}" == "${NEW}" ]; then
        return
    fi

    echo
}

_init() {
    rm -rf ${SHELL_DIR}/target

    mkdir -p ${SHELL_DIR}/target
    mkdir -p ${SHELL_DIR}/versions

    cp -rf ${SHELL_DIR}/versions ${SHELL_DIR}/target/
}

_load() {
    helm version --client --short

    # add repos
    while read VAR; do
        helm repo add ${VAR}
    done < ${SHELL_DIR}/repos.txt
    echo

    helm search repo -o json | jq '.[] | "\"\(.name)\" \(.version) \(.app_version)"' -r > ${CHARTS}
}

_check() {
    printf '# %-50s %-20s %-20s\n' "NAME" "NOW" "NEW"

    # verify versions
    while read VAR; do
        _verify_version ${VAR}
    done < ${SHELL_DIR}/checklist.txt
    echo
}

_message() {
    # commit message
    printf "$(date +%Y%m%d-%H%M)" > ${SHELL_DIR}/target/commit_message.txt
}

_run() {
    _init

    _load

    _check

    _message
}

_run
