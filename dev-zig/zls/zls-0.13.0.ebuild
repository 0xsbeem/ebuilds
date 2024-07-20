# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo

DESCRIPTION="The officially unofficial Ziglang language server"
HOMEPAGE="https://github.com/zigtools/zls"

KNOWN_FOLDERS_COMMIT="47076c6b11214a218e9244471d8762310820911a"
TRACY_COMMIT="20d67a1bc804256ba62a4a8ea0b17cb58f1f67fe"
SRC_URI="
	https://github.com/ziglibs/known-folders/archive/${KNOWN_FOLDERS_COMMIT}.tar.gz -> known-folders-${KNOWN_FOLDERS_COMMIT}.tar.gz
	https://github.com/wolfpld/tracy/archive/${TRACY_COMMIT}.tar.gz -> tracy-${TRACY_COMMIT}.tar.gz
	https://github.com/zigtools/zls/archive/refs/tags/${PV}.tar.gz -> zls-${PV}.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

EZIG_MIN="0.13.0"
EZIG_MAX_EXCLUSIVE="0.13.0"

DEPEND="|| ( dev-lang/zig-${EZIG_MIN} dev-lang/zig-bin-${EZIG_MIN} )"
RDEPEND="${DEPEND}"

# see https://github.com/ziglang/zig/issues/3382
# For now, Zig Build System doesn't support CFLAGS/LDFLAGS/etc.
QA_FLAGS_IGNORED="usr/bin/zls"

# : copied from sys-fs/ncdu :
# Many thanks to Florian Schmaus (Flowdalic)!
# Adapted from https://github.com/gentoo/gentoo/pull/28986
# Set the EZIG environment variable.
zig-set_EZIG() {
	[[ -n ${EZIG} ]] && return

	if [[ -n ${EZIG_OVERWRITE} ]]; then
		export EZIG="${EZIG_OVERWRITE}"
		return
	fi

	local candidates candidate selected selected_ver

	candidates=$(compgen -c zig-)

	for candidate in ${candidates}; do
		if [[ ! ${candidate} =~ zig(-bin)?-([.0-9]+) ]]; then
			continue
		fi

		local ver
		if (( ${#BASH_REMATCH[@]} == 3 )); then
			ver="${BASH_REMATCH[2]}"
		else
			ver="${BASH_REMATCH[1]}"
		fi

		if [[ -n ${EZIG_EXACT_VER} ]]; then
			ver_test "${ver}" -ne "${EZIG_EXACT_VER}" && continue

			selected="${candidate}"
			selected_ver="${ver}"
			break
		fi

		if [[ -n ${EZIG_MIN} ]] \
			   && ver_test "${ver}" -lt "${EZIG_MIN}"; then
			# Candidate does not satisfy EZIG_MIN condition.
			continue
		fi

		if [[ -n ${EZIG_MAX_EXCLUSIVE} ]] \
			   && ver_test "${ver}" -ge "${EZIG_MAX_EXCLUSIVE}"; then
			# Candidate does not satisfy EZIG_MAX_EXCLUSIVE condition.
			continue
		fi

		if [[ -n ${selected_ver} ]] \
			   && ver_test "${selected_ver}" -gt "${ver}"; then
			# Candidate is older than the currently selected candidate.
			continue
		fi

		selected="${candidate}"
		selected_ver="${ver}"
	done

	if [[ -z ${selected} ]]; then
		die "Could not find (suitable) zig installation in PATH"
	fi

	export EZIG="${selected}"
	export EZIG_VER="${ver}"
}

# Invoke zig with the optionally provided arguments.
ezig() {
	zig-set_EZIG

	# Unfortunately, we cannot add more args here, since syntax is different
	# for every subcommands. Yes, even target/cpu :( f.i. :
	# -target/-mcpu for zig build-exe vs -Dtarget/-Dcpu for zig build-
	# -OReleaseSafe for zig build-exe vs -DReleaseSafe for zig build
	# (or even none, if hardcoded by upstream so choice is -Drelease=true/false)
	# Ofc we can patch this, but still...

	edo "${EZIG}" "${@}"
}

src_prepare() {
	rm -r src/known-folders || die
	mv "../known-folders-${KNOWN_FOLDERS_COMMIT}" src/known-folders || die
	rm -r src/tracy || die
	mv "../tracy-${TRACY_COMMIT}" src/zinput || die

	default
}

src_compile() {
	ezig build -Drelease-safe -Ddata_version=0.13.0 --verbose || die
}

src_test() {
	ezig build test -Drelease-safe -Ddata_version=0.13.0 --verbose || die
}

src_install() {
	DESTDIR="${ED}" ezig build install --prefix /usr -Drelease-safe -Ddata_version=0.13.0 --verbose || die
	dodoc README.md
}

pkg_postinst() {
	elog "You can find more information about options here https://github.com/zigtools/zls#configuration-options"
}
