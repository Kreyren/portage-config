# shellcheck shell=bash
# shellcheck disable=SC2034 # Variables appear unused, FIXME point to a proper source

# STATUS: Portage doesn't allow bash '"/etc/portage/make.conf", line 9: Invalid token 'command' (not '=')'

# Prefixed with my to prevent injection in compilation (?)
myerr() { printf 'ERROR: %s\n' "$1" ;}
mydie() { printf 'FATAL: %s\n' "$1" ; exit 1 ;}

# Generate flags for compilation
if command -v gcc >/dev/null; then
	target="$(gcc -### -E - -march=native 2>&1 | grep Target)"
	CHOST="${target##Target: }"
	CBUILD="${target##Target: }"
	# Blocks POSIX compatibility
		COMMON_FLAGS="-O2 $(gcc -### -E - -march=native 2>&1 | sed -r '/cc1/!d;s/(\")|(^.* - )|( -mno-[^\ ]+)|( --param[^\s]+)//g') -pipe"
	CFLAGS="$COMMON_FLAGS"
	CXXFLAGS="$COMMON_FLAGS"
	FCLAGS="$COMMON_FLAGS"
	FFLAGS="$COMMON_FLAGS"
	FCFLAGS="$COMMON_FLAGS"
	LDFLAGS="-Wl,-O1 -Wl,--as-needed"
elif ! command -v gcc >/dev/null; then
	myerr "Unable to generate compilation flags dynamically"
	COMMON_FLAGS="-O2 -march=sandybridge -mmmx -msse -msse2 -msse3 -mssse3 -mcx16 -msahf -maes -mpclmul -mpopcnt -mavx -msse4.2 -msse4.1 -mfxsr -mxsave -mxsaveoptsize=32size=64size=8192 -mtune=sandybridge -fasynchronous-unwind-tables -pipe"
	CFLAGS="$COMMON_FLAGS"
	CXXFLAGS="$COMMON_FLAGS"
	FCLAGS="$COMMON_FLAGS"
	FFLAGS="$COMMON_FLAGS"
	FCFLAGS="$COMMON_FLAGS"
	LDFLAGS="-Wl,-O1 -Wl,--as-needed"
	CHOST="x86_64-pc-linux-gnu"
	CBUILD="x86_64-pc-linux-gnu"
else
	mydie "Unexpected result in generating compilation flags"
fi

# Adapts nproc in MAKEOPTS
if [ -n "$(nproc)" ]; then
	MAKEOPTS="-j$(nproc)"
elif [ -z "$(nproc)" ]; then
	MAKEOPTS="-j8"
else
	mydie "Unexpected happend in adapting nproc in MAKEOPTS"
fi

# Generate VIDEO_CARDS from glxinfo if present
if command -v glxinfo >/dev/null; then
	case $(glxinfo | grep "Device:") in
		'Device: AMD'*) VIDEO_CARDS="amdgpu radeonsi" ;;
		*) mydie "Unsupported GPU has been parsed: $(glxinfo | grep "Device:")"
	esac
elif command -v glxinfo >/dev/null; then
	VIDEO_CARDS="amdgpu radeonsi"
else
	mydie "Unexpected happend in generation VIDEO_CARDS"
fi

# Generate CPU_FLAGS_X86
if command -v cpuid2cpuflags >/dev/null; then
	CPU_FLAGS_X86="$(cpuid2cpuflags)"
	CPU_FLAGS_X86="${CPU_FLAGS_X86##CPU_FLAGS_X86: }"
elif ! command -v cpuid2cpuflags >/dev/null; then
	printf 'ERROR: %s\n' "Command 'cpuid2cpuflags' is not installed, using static CPU_FLAGS_X86"
	CPU_FLAGS_X86="aes avx mmx mmxext pclmul popcnt sse sse2 sse3 sse4_1 sse4_2 ssse3"
fi

# split-usr: why
# hppa: fix in profile required
USE='-* -hppa test threads amd64 split-usr ssl'

# Package configuration
ACCEPT_LICENSE="-* @FREE @KREYREN-APPROVED @FSF-APPROVED"
ACCEPT_KEYWORDS="amd64 ~amd64"
## https://bugs.gentoo.org/show_bug.cgi?id=695182
LANG='-* en_US.utf8'
LC_ALL="en_US.UTF-8"
ABI_X86="64"
USERLAND="GNU"
KERNEL="linux"
INPUT_DEVICES="libinput keyboard mouse"

: "
Portage directory structure

PORTAGE_OVERLAY is deprecated in favor of repos.conf (https://wiki.gentoo.org/wiki//etc/portage/make.conf#PORTDIR_OVERLAY)"
PKGDIR="/var/cache/binpkgs"
PORTAGE_LOGDIR='/var/log/portage'
PORTDIR_OVERLAY='/etc/portage/overlays/'
DISTDIR="/var/cache/distfiles"
PORTAGE_TMPDIR="/var/tmp" # Results in /var/tmp/portage
PORTAGE_CONFIGROOT="/"
CONFIG_PROTECT='/etc /usr/share/gnupg/qualified.txt'
PORTAGE_RSYNC_OPTS="--recursive --links --safe-links --perms --times --omit-dir-times --compress --force --whole-file --delete --stats --human-readable --timeout=180 --exclude=/distfiles --exclude=/local --exclude=/packages --exclude=/.git"

EMERGE_DEFAULT_OPTS="--jobs --autounmask-write --verbose-conflicts"
PORTAGE_NICENESS="19"
FEATURES="-* userpriv xattr"

# Toolchain
PHP_TARGETS='php5-6 php7-1'
POSTGRES_TARGETS='postgres9_5 postgres10'
PYTHON_SINGLE_TARGET='python2_7'
PYTHON_TARGETS='python2_7 python3_6'
RUBY_TARGETS='ruby24'
ELIBC='glibc'

# Additional
CURL_SSL='openssl'
FFTOOLS=''
XTABLES_ADDONS=''
LCD_DEVICES=''
LIBREOFFICE_EXTENSIONS=''
OFFICE_IMPLEMENTATION=''
ALSA_CARDS=''
APACHE2_MODULES=''
COLLECTD_PLUGINS=''
GPSD_PROTOCOLS=''
