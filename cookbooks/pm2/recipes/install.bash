#!/bin/bash -e

function installDependencies()
{
    if [[ "$(existCommand 'node')" = 'false' || "$(existCommand 'npm')" = 'false' || ! -d "${PM2_NODE_INSTALL_FOLDER_PATH}" ]]
    then
        "$(dirname "${BASH_SOURCE[0]}")/../../node/recipes/install.bash" "${PM2_NODE_VERSION}" "${PM2_NODE_INSTALL_FOLDER_PATH}"
    fi
}

function resetOwnerAndSymlinkLocalBin()
{
    chown -R "$(whoami):$(whoami)" "${PM2_NODE_INSTALL_FOLDER_PATH}"
    symlinkUsrBin "${PM2_NODE_INSTALL_FOLDER_PATH}/bin"
}

function install()
{
    umask '0022'

    # Install

    npm install -g --prefix "${PM2_NODE_INSTALL_FOLDER_PATH}" 'pm2@latest'

    # Reset Owner And Symlink Local Bin

    resetOwnerAndSymlinkLocalBin

    # Add User

    addUser "${PM2_USER_NAME}" "${PM2_GROUP_NAME}" 'true' 'true' 'true'

    local -r userHome="$(getUserHomeFolder "${PM2_USER_NAME}")"

    checkExistFolder "${userHome}"

    # Config Profile

    createFileFromTemplate \
        "$(dirname "${BASH_SOURCE[0]}")/../templates/pm2.sh.profile" \
        '/etc/profile.d/pm2.sh' \
        '__HOME_FOLDER__' "${userHome}/.pm2"

    # Config Log Rotate

    createFileFromTemplate \
        "$(dirname "${BASH_SOURCE[0]}")/../templates/pm2.logrotate" \
        '/etc/logrotate.d/pm2' \
        '__HOME_FOLDER__' "${userHome}/.pm2"

    # Clean Up

    local -r userHomeFolderPath="$(getCurrentUserHomeFolder)"

    rm -f -r "${userHomeFolderPath}/.cache" \
             "${userHomeFolderPath}/.npm"

    # Start

    export PM2_HOME="${userHome}/.pm2"
    pm2 startup 'linux' --hp "${userHome}/.pm2" --user "${PM2_USER_NAME}"
    pkill -f 'PM2'
    chown -R "${PM2_USER_NAME}:${PM2_GROUP_NAME}" "${userHome}/.pm2"
    service 'pm2-init.sh' start

    # Display Version

    displayVersion "Node Version : $(node --version)\nNPM Version  : $(npm --version)\nPM2 Version  : $(pm2 --version)"

    umask '0077'
}

function main()
{
    source "$(dirname "${BASH_SOURCE[0]}")/../../../libraries/util.bash"
    source "$(dirname "${BASH_SOURCE[0]}")/../attributes/default.bash"

    header 'INSTALLING PM2'

    checkRequireLinuxSystem
    checkRequireRootUser

    installDependencies
    install
    installCleanUp
}

main "${@}"