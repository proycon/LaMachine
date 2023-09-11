#Github => Arch User Repository  Release Update script
# Updates PKGBUILD according to latest release on github
# Assumes releases are named like v0.1.2 (the v is mandatory)

source ./PKGBUILD
OLDVERSION="$pkgver"
echo "Old Version: ${OLDVERSION}"
if [ -z ${_gituser} ]; then
    echo "no _gituser set"
    exit 1
fi
if [ -z ${_gitname} ]; then
    echo "no _gitname set"
    exit 1
fi
NEWVERSION=$(curl https://api.github.com/repos/${_gituser}/${_gitname}/releases 2> /dev/null | jq -r '.[0].tag_name | match("\\d(\\.\\d+)+").string')
echo "New Version: ${NEWVERSION}"
if [ "$OLDVERSION" = "$NEWVERSION" ]; then
    echo "No update available, exiting...">&2
    exit 1
fi
SOURCE="https://github.com/${_gituser}/${_gitname}/archive/v${NEWVERSION}.tar.gz"
if [ ! -f "v${NEWVERSION}.tar.gz" ]; then
    wget $SOURCE
    if [ $? -ne 0 ]; then
        echo "Unable to download release from $SOURCE" >&2
        exit 2
    fi
fi
sed -i "s|source=.*|source=(${SOURCE})|g" PKGBUILD
MD5SUM=`md5sum v${NEWVERSION}.tar.gz | cut -d " " -f1`
sed -i "s/md5sums=.*/md5sums=(${MD5SUM})/g" PKGBUILD
sed -i "s/pkgver=.*/pkgver=${NEWVERSION}/g" PKGBUILD
sed -i "s/pkgrel=.*/pkgrel=1/g" PKGBUILD

#mksrcinfo
makepkg --printsrcinfo > .SRCINFO
git add PKGBUILD .SRCINFO


