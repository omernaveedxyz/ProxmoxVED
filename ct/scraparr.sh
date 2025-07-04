#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: JasonGreenC
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thecfu/scraparr

APP="Scraparr"
var_tags="${var_tags:-arr;monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -d /opt/scraparr/ ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL https://api.github.com/repos/thecfu/scraparr/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f "${HOME}/.scrappar" ]] || [[ "${RELEASE}" != "$(cat "${HOME}"/.scrappar)" ]]; then
        msg_info "Stopping Services"
        systemctl stop scraparr
        msg_ok "Services Stopped"

        PYTHON_VERSION="3.12" setup_uv
        fetch_and_deploy_gh_release "scrappar" "thecfu/scraparr" "tarball" "latest" "/opt/scraparr"

        msg_info "Updating ${APP} to ${RELEASE}"
        cd /opt/scraparr || exit
        $STD uv venv /opt/scraparr/.venv
        $STD /opt/scraparr/.venv/bin/python -m ensurepip --upgrade
        $STD /opt/scraparr/.venv/bin/python -m pip install --upgrade pip
        $STD /opt/scraparr/.venv/bin/python -m pip install -r /opt/scraparr/src/scraparr/requirements.txt
        chmod -R 755 /opt/scraparr
        msg_ok "Updated ${APP} to v${RELEASE}"

        msg_info "Starting Services"
        systemctl start scraparr
        msg_ok "Services Started"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7100${CL}"
