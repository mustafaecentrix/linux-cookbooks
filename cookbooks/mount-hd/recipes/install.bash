#!/bin/bash -e

function installDependencies()
{
    installAptGetPackages 'expect'
}

function install()
{
    local disk="$(formatPath "${1}")"
    local mountOn="$(formatPath "${2}")"

    # Create Partition

    local foundDisk="$(fdisk -l "${disk}" 2>/dev/null | grep -Eio "^Disk\s+$(escapeSearchPattern "${disk}"):")"

    if [[ "$(isEmptyString "${foundDisk}")" = 'true' ]]
    then
        fatal "\nFATAL: disk '${disk}' not found"
    fi

    if [[ "$(isEmptyString "${mountOn}")" = 'true' || -d "${mountOn}" ]]
    then
        fatal "\nFATAL: mounted file system '${mountOn}' found or undefined"
    fi

    createPartition "${disk}"
    mkfs --type "${mounthdFSType}" "${disk}1"
    mkdir "${mountOn}"
    mount --types "${mounthdFSType}" "${disk}1" "${mountOn}"

    # Config Static File System

    local fstabPattern="^\s*${disk}1\s+${mountOn}\s+${mounthdFSType}\s+defaults\s+0\s+2\s*$"
    local fstabConfig="${disk}1 ${mountOn} ${mounthdFSType} defaults 0 2"

    appendToFileIfNotFound '/etc/fstab' "${fstabPattern}" "${fstabConfig}" 'true' 'false'

    # Display File System

    df --human-readable --print-type
}

function createPartition()
{
    local disk="${1}"

    expect << DONE
        spawn fdisk "${disk}"
        expect "Command (m for help): "
        send -- "n\r"
        expect "Select (default p): "
        send -- "\r"
        expect "Partition number (1-4, default 1): "
        send -- "\r"
        expect "First sector (*, default *): "
        send -- "\r"
        expect "Last sector, +sectors or +size{K,M,G} (*, default *): "
        send -- "\r"
        expect "Command (m for help): "
        send -- "w\r"
        expect eof
DONE
}

function main()
{
    local appPath="$(cd "$(dirname "${0}")" && pwd)"

    source "${appPath}/../../../lib/util.bash" || exit 1
    source "${appPath}/../attributes/default.bash" || exit 1

    checkRequireSystem
    checkRequireRootUser

    header 'INSTALLING MOUNT-HD'

    installDependencies
    install "${@}"
    installCleanUp
}

main "${@}"