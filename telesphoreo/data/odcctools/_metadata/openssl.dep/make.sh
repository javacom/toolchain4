pkg:setup
./Configure -D__DARWIN_UNIX03 "$(echo "${PKG_TARG}" | sed -e 's/\(.*\)-\(.*\)-\(.*\)/\3-\1/')-gcc" --prefix=/usr --openssldir=/usr/lib/ssl shared
make AR="${PKG_TARG}-ar -r"
make install INSTALL_PREFIX="${PKG_DEST}"
pkg: rm -rf /usr/lib/man /usr/lib/ssl/man
pkg: mkdir -p /etc/ssl
mv "${PKG_DEST}"/usr/lib/ssl/{certs,openssl.cnf,private} "${PKG_DEST}"/etc/ssl
ln -s /etc/ssl/{certs,openssl.cnf,private} "${PKG_DEST}"/usr/lib/ssl
rm -rf "${PKG_DEST}"/usr/lib/*.a
