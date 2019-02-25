#!/bin/bash
#
# Script to unlock luks at boot in a dropbear server on busybox
#
# Based on gusennan's solution on github

PREREQ="dropbear"

prereqs() {
  echo "$PREREQ"
}

case "$1" in
  prereqs)
    prereqs
    exit 0
  ;;
esac

. "${CONFDIR}/initramfs.conf"
. /usr/share/initramfs-tools/hook-functions

if [ "${DROPBEAR}" != "n" ] && [ -r "/etc/crypttab" ] ; then
    mkdir -p "${DESTDIR}/lib/unlock"
    
    cat <<-EOF > "${DESTDIR}/bin/unlock"
        #!/bin/sh
        if PATH=/lib/unlock:/bin:/sbin /scripts/local-top/cryptroot; then
            # kill the remote shell right after the passphrase has been entered.
            kill \`ps | grep cryptroot | grep -v "grep" | awk '{print \$1}'\`
            kill -9 \`ps | grep "\-sh" | grep -v "grep" | awk '{print \$1}'\`
            exit 0
        fi
        exit 1
EOF

    cat <<-EOF > "${DESTDIR}/lib/unlock/plymouth"
        #!/bin/sh
        [ "\$1" == "--ping" ] && exit 1
        /bin/plymouth "\$@"
EOF

    chmod 700 "${DESTDIR}/bin/unlock"
    chmod 700 "${DESTDIR}/lib/unlock/plymouth"

    echo To unlock root-partition run "unlock" >> ${DESTDIR}/etc/motd  
fi
