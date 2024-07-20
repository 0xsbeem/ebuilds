EAPI=8

DESCRIPTION="Language server for the Zig programming language"
HOMEPAGE="https://github.com/zigtools/zls"
SRC_URI="
	amd64? ( https://github.com/zigtools/zls/releases/download/${PV}/zls-x86_64-linux.tar.xz )
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

# src_unpack() {
# 	fy-sig_src_unpack
#
# 	mv "${WORKDIR}/"* "${S}" || die
# }

src_install() {
	insinto /opt/
	doins -r "${S}"
	fperms 0755 "/opt/${P}/zls"
	dosym -r "/opt/${P}/zls" "/usr/bin/zls-bin-${PV}"
}
