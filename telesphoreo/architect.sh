if [[ ! -e ${PKG_BASE}/arch/${PKG_ARCH}/target ]]; then
    echo "unknown PKG_BASE: ${PKG_BASE}" 1>&2
    echo "unknown architecture: ${PKG_ARCH}" 1>&2
    exit 1
fi

export PKG_TARG=$(cat "${PKG_BASE}/arch/${PKG_ARCH}/target")
