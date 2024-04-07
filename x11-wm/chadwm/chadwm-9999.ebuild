EAPI=8
inherit git-r3

EGIT_REPO_URI="https://github.com/siduck/chadwm.git"


DESCRIPTION="dwm, but pretty out of the box."

LICENSE="MIT"

SLOT="0"

KEYWORDS="amd64"
IUSE="xinerama"

BDEPEND=">=x11-misc/rofi-1.7.5
>=media-gfx/feh-3.10.2
>=media-libs/imlib2-1.9.1-r1
>=x11-misc/picom-10.2
>=sys-power/acpi-1.7-r1
>=app-shells/dash-0.5.12
>=x11-apps/xsetroot-1.1.3
xinerama? ( >=x11-libs/libXinerama-1.1.5 )"

src_install() {
	dodir /etc/chadwm
	cd chadwm
	if ! use xinerama ; then
		# Turn off xinerama
		sed -i 's/^\(XINERAMALIBS\|XINERAMAFLAGS\)/#\1/' config.mk
	fi
	emake DESTDIR="${D}" install
	cd ..
	cp -r "${S}/scripts" "${ED}/etc/chadwm/" || die "Failed to copy scripts."
	cp -r "${S}/rofi" "${ED}/etc/chadwm/" || die "Failed to copy rofi."
	cp -r "${S}/eww" "${ED}/etc/chadwm/" || die "Failed to copy eww."
}

pkg_postinst() {
	elog "Chadwm is installed, but you still need the scripts to run it easily."
	elog "The chadwm supplements have been installed to /etc/chadwm."
	elog "To use them, run cp -r /etc/chadwm ~/.config/chadwm"
}

pkg_postrm() {
	if [ -d "/etc/chadwm" ]; then
		elog "Removing supplements from /etc/chadwm"
		rm -rf /etc/chadwm
	else
		elog "/etc/chadwm not found. Nothing to remove."
	fi
}
