#!/bin/sh

LMTXSERVER=lmtx.contextgarden.net,lmtx.pragma-ade.com,lmtx.pragma-ade.nl
LMTXINSTANCE=install-lmtx
LMTXEXTRAS=

SYSTEM=`uname -s`
CPU=`uname -m`
PLATFORM="unknown"

case "$SYSTEM" in
    # linux
    Linux)
        if command -v ldd >/dev/null && ldd --version 2>&1 | grep -E '^musl' >/dev/null
        then
            libc=musl
        else
            libc=glibc
        fi
        case "$CPU" in
            i*86)
                case "$libc" in
                    glibc)
                        PLATFORM="linux" ;;
                    musl)
                        PLATFORM="linuxmusl" ;;
                esac ;;
            x86_64|ia64)
                case "$libc" in
                    glibc)
                        PLATFORM="linux-64" ;;
                    musl)
                        PLATFORM="linuxmusl" ;;
                esac ;;
            mips|mips64|mipsel|mips64el)
                PLATFORM="linux-mipsel" ;;
            aarch64)
                PLATFORM="linux-aarch64" ;;
            armv7l)
                PLATFORM="linux-armhf"
                if $(which readelf >/dev/null 2>&1); then
                    readelf -A /proc/self/exe | grep -q '^ \+Tag_ABI_VFP_args'
                    if [ ! $? ]; then
                        PLATFORM="linux-armel"
                    fi
                elif $(which dpkg >/dev/null 2>&1); then
                    if [ "$(dpkg --print-architecture)" = armel ]; then
                        PLATFORM="linux-armel"
                    fi
                fi
                ;;
        esac ;;
            Darwin|darwin)
        case "$CPU" in
            i*86)
                PLATFORM="osx-intel" ;;
            x86_64)
                PLATFORM="osx-64" ;;
            arm64)
                PLATFORM="osx-arm64" ;;
            *)
                PLATFORM="unknown" ;;
        esac ;;
            FreeBSD|freebsd)
        case "$CPU" in
            i*86)
                PLATFORM="freebsd" ;;
            amd64)
                PLATFORM="freebsd-amd64" ;;
            *)
                PLATFORM="unknown" ;;
        esac ;;
            OpenBSD|openbsd)
            version=`uname -r`
        case "$CPU" in
            i*86)
                PLATFORM="openbsd${version}" ;;
            amd64)
                PLATFORM="openbsd${version}-amd64" ;;
            *)
                PLATFORM="unknown" ;;
        esac ;;
esac

if test "$PLATFORM" = "unknown" ; then
    echo ""
    echo "Your system \"$SYSTEM $CPU\" is not supported (yet). You can ask"
    echo "on the ConTeXt mailing-list: ntg-context@ntg.nl."
    echo ""
    exit
fi

# "" are needed for WLS because of (86) in the variable

export PATH="$PWD/bin:$PWD/tex/texmf-$PLATFORM/bin:$PATH"

chmod +x bin/mtxrun

if test "$SYSTEM" = "Darwin" ; then
   if [ `uname -r | cut -f1 -d"."` -gt 18 ]; then
      xattr -d com.apple.quarantine bin/mtxrun
   fi
fi

$PWD/bin/mtxrun --script ./bin/mtx-install.lua --update --server="$LMTXSERVER" --instance="$LMTXINSTANCE" --platform="$PLATFORM" --erase --extras="$LMTXEXTRAS" $@

cp $PWD/tex/texmf-$PLATFORM/bin/mtxrun                        $PWD/bin/mtxrun
cp $PWD/tex/texmf-context/scripts/context/lua/mtxrun.lua      $PWD/bin/mtxrun.lua
cp $PWD/tex/texmf-context/scripts/context/lua/mtx-install.lua $PWD/bin/mtx-install.lua

# echo "  export PATH=$PWD/tex/texmf-$PLATFORM/bin:$PATH"

echo ""
echo "If you want to run ConTeXt everywhere, you need to adapt the path, like:"
echo ""
echo "  export PATH=$PWD/tex/texmf-$PLATFORM/bin:"'$PATH'
echo ""
echo "If you run from an editor you can specify the full path to mtxrun:"
echo ""
echo "  $PWD/tex/texmf-$PLATFORM/bin/mtxrun --autogenerate --script context --autopdf ..."
echo ""
echo "The following settings were used:"
echo ""
echo "  server   : $LMTXSERVER"
echo "  instance : $LMTXINSTANCE"
echo "  extras   : $LMTXEXTRAS"
echo "  ownpath  : $PWD"
echo "  platform : $PLATFORM"
echo ""
