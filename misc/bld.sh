#!/bin/bash
#
# $Id: bld.sh,v 1.3 06/15/2013 bianjiang based (jlinoff)
#
# Author: Jiang Bian
#
# This script downloads, builds and installs the gcc-4.8.1 compiler
# and boost 1.53. It takes handles the dependent packages like
# gmp-5.1.12, mpfr-3.1.1, isl and cloog-0.18.0.
#
# To install gcc-4.8.1 in ~/local/bin you would run this
# script as follows:
#
#    % # Install in ~/local
#    % bld.sh ~/local>&1 | tee bld.log
#
# If the install directory is not specified, it will create a rtf folder and install gcc under the rtf folder
#
#
# This script creates 3 subdirectories under the current build folder:
#
#    Directory  Description
#    =========  ==================================================
#    archives   This is where the package archives are downloaded.
#    src        This is where the package source is located.
#    bld        This is where the packages are built from source.
#
# When the build is complete you can safely remove the archives, bld
# and src directory trees to save disk space.
#

# ================================================================
# Trim a string, remove internal spaces, convert to lower case.
# ================================================================
function get-platform-trim {
    local s=$(echo "$1" | tr -d '[ \t]' | tr 'A-Z' 'a-z')
    echo $s
}

# ================================================================
# Get the platform root name.
# ================================================================
function get-platform-root
{
    if which uname >/dev/null 2>&1 ; then
        # Greg Moeller reported that the original code didn't
        # work because the -o option is not available on solaris.
        # I modified the script to correctly identify that
        # case and recover by using the -s option.
        if uname -o >/dev/null 2>&1 ; then
            # Linux distro
            uname -o | tr 'A-Z' 'a-z'
        elif uname -s >/dev/null 2>&1 ; then
            # Solaris variant
            uname -s | tr 'A-Z' 'a-z'
        else
            echo "unkown"
        fi
    else
        echo "unkown"
    fi
}

# ================================================================
# Get the platform identifier.
#
# The format of the output is:
#   <plat>-<dist>-<ver>-<arch>
#   ^      ^      ^     ^
#   |      |      |     +----- architecture: x86_64, i86pc, etc.
#   |      |      +----------- version: 5.5, 4.7
#   |      +------------------ distribution: centos, rhel, nexentaos
#   +------------------------- platform: linux, sunos
#
# ================================================================
function get-platform
{
    plat=$(get-platform-root)
    case "$plat" in
        "gnu/linux")
            d=$(get-platform-trim "$(lsb_release -i)" | awk -F: '{print $2;}')
            r=$(get-platform-trim "$(lsb_release -r)" | awk -F: '{print $2;}')
            m=$(get-platform-trim "$(uname -m)")
            if [[ "$d" == "redhatenterprise"* ]] ; then
                # Need a little help for Red Hat because
                # they don't make the minor version obvious.
                d="rhel_${d:16}"  # keep the tail (e.g., es or client)
                x=$(get-platform-trim "$(lsb_release -c)" | \
                    awk -F: '{print $2;}' | \
                    sed -e 's/[^0-9]//g')
                r="$r.$x"
            fi
            echo "linux-$d-$r-$m"
            ;;
        "cygwin")
            x=$(get-platform-trim "$(uname)")
            echo "linux-$x"
            ;;
        "sunos")
            d=$(get-platform-trim "$(uname -v)")
            r=$(get-platform-trim "$(uname -r)")
            m=$(get-platform-trim "$(uname -m)")
            echo "sunos-$d-$r-$m"
            ;;
        "unknown")
            echo "unk-unk-unk-unk"
            ;;
        *)
            echo "$plat-unk-unk-unk"
            ;;
    esac
}

# Execute command with decorations and status testing.
# Usage  : docmd $ar <cmd>
# Example: docmd $ar ls -l
function docmd {
    local ar=$1
    shift
    local cmd=($*)
    echo 
    echo " # ================================================================"
    if [[ "$ar" != "" ]] ; then
	echo " # Archive: $ar"
    fi
    echo " # PWD: "$(pwd)
    echo " # CMD: "${cmd[@]}
    echo " # ================================================================"
    ${cmd[@]}
    local st=$?
    echo "STATUS = $st"
    if (( $st != 0 )) ; then
	exit $st;
    fi
}

# Report an error and exit.
# Usage  : doerr <line1> [<line2> .. <line(n)>]
# Example: doerr "line 1 msg"
# Example: doerr "line 1 msg" "line 2 msg"
function doerr {
    local prefix="ERROR: "
    for ln in "$@" ; do
	echo "${prefix}${ln}"
	prefix="       "
    done
    exit 1
}

# Extract archive information.
# Usage  : ard=( $(extract-ar-info $ar) )
# Example: ard=( $(extract-ar-info $ar) )
#          fn=${ard[1]}
#          ext=${ard[2]}
#          d=${ard[3]}
function extract-ar-info {
    local ar=$1
    local fn=$(basename $ar)
    local ext=$(echo $fn | awk -F. '{print $NF}')
    local d=${fn%.*tar.$ext}
    echo $ar
    echo $fn
    echo $ext
    echo $d
}

# Print a banner for a new section.
# Usage  : banner STEP $ar
# Example: banner "DOWNLOAD" $ar
# Example: banner "BUILD" $ar
function banner {
    local step=$1
    local ard=( $(extract-ar-info $2) )
    local ar=${ard[0]}
    local fn=${ard[1]}
    local ext=${ard[2]}
    local d=${ard[3]}
    echo
    echo '# ================================================================'
    echo "# Step   : $step"
    echo "# Archive: $ar"
    echo "# File   : $fn"
    echo "# Ext    : $ext"
    echo "# Dir    : $d"
    echo '# ================================================================'
}

# Make a group directories
# Usage  : mkdirs <dir1> [<dir2> .. <dir(n)>]
# Example: mkdirs foo bar spam spam/foo/bar
function mkdirs {
    local ds=($*)
    #echo "mkdirs"
    for d in ${ds[@]} ; do
	#echo "  testing $d"
	if [ ! -d $d ] ; then
	    #echo "    creating $d"
	    mkdir -p $d
	fi
    done
}

# ================================================================
# Check the current platform to see if it is in the tested list,
# if it isn't, then issue a warning.
# ================================================================
function check-platform
{
    local plat=$(get-platform)
    local tested_plats=(
	'linux-centos-5.5-x86_64'
	'linux-centos-5.8-x86_64'
	'linux-centos-6.3-x86_64')
    local plat_found=0

    echo "PLATFORM: $plat"
    for tested_plat in ${tested_plats[@]} ; do
	if [[ "$plat" == "$tested_plat" ]] ; then
	    plat_found=1
	    break
	fi
    done
    if (( $plat_found == 0 )) ; then
	echo "WARNING: This platform ($plat) has not been tested."
    fi
}

# ================================================================
# DATA
# ================================================================
# List of archives
# The order is important.
ARS=(
    http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
    ftp://ftp.gmplib.org/pub/gmp-5.1.2/gmp-5.1.2.tar.bz2
    http://www.mpfr.org/mpfr-current/mpfr-3.1.2.tar.bz2
    http://www.multiprecision.org/mpc/download/mpc-1.0.1.tar.gz
    ftp://ftp.linux.student.kuleuven.be/pub/people/skimo/isl/isl-0.11.2.tar.bz2
    #http://bugseng.com/products/ppl/download/ftp/releases/1.0/ppl-1.0.tar.bz2
    http://bugseng.com/products/ppl/download/ftp/snapshots/ppl-1.1pre9.tar.bz2
    http://www.bastoul.net/cloog/pages/download/cloog-0.18.0.tar.gz
    http://gcc.petsads.us/releases/gcc-4.8.1/gcc-4.8.1.tar.bz2
    http://ftp.gnu.org/gnu/binutils/binutils-2.23.2.tar.bz2
    http://sourceforge.net/projects/boost/files/boost/1.53.0/boost_1_53_0.tar.bz2
    http://www.cmake.org/files/v2.8/cmake-2.8.11.1.tar.gz
    #
    # Why glibc is disabled (for now).
    #
    # glibc does not work on CentOS because the versions of the shared
    # libraries we are building are not compatiable with installed
    # shared libraries.
    #
    # This is the run-time error: ELF file OS ABI invalid that I see
    # when I try to run binaries compiled with the local glibc-2.15.
    #
    # Note that the oldest supported ABI for glibc-2.15 is 2.2. The
    # CentOS 5.5 ABI is 0.
    # http://ftp.gnu.org/gnu/glibc/glibc-2.15.tar.bz2
)

# ================================================================
# MAIN
# ================================================================
umask 0

check-platform

# Read the command line argument, if it exists.
ROOTDIR=$(readlink -f .)
RTFDIR="$ROOTDIR/rtf"
if (( $# == 1 )) ; then
    RTFDIR=$(readlink -f $1)
elif (( $# > 1 )) ; then
    doerr "too many command line arguments ($#), only zero or one is allowed" "foo"
fi

# Setup the directories.
ARDIR="$ROOTDIR/archives"
SRCDIR="$ROOTDIR/src"
BLDDIR="$ROOTDIR/bld"
TSTDIR="$SRCDIR/LOCAL-TEST"

export PATH="${RTFDIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${RTFDIR}/lib:${LD_LIBRARY_PATH}"

echo
echo "# ================================================================"
echo '# Version    : $Id: bld.sh,v 1.2 2012/09/22 16:04:19 jlinoff Exp jlinoff $'
echo "# RootDir    : $ROOTDIR"
echo "# ArchiveDir : $ARDIR"
echo "# RtfDir     : $RTFDIR"
echo "# SrcDir     : $SRCDIR"
echo "# BldDir     : $BLDDIR"
echo "# TstDir     : $TSTDIR"
echo "# Gcc        : "$(which gcc)
echo "# GccVersion : "$(gcc --version | head -1)
echo "# Hostname   : "$(hostname)
echo "# O/S        : "$(uname -s -r -v -m)
echo "# Date       : "$(date)
echo "# ================================================================"

mkdirs $ARDIR $RTFDIR $SRCDIR $BLDDIR

# ================================================================
# Download
# ================================================================
for ar in ${ARS[@]} ; do
    banner 'DOWNLOAD' $ar
    ard=( $(extract-ar-info $ar) )
    fn=${ard[1]}
    ext=${ard[2]}
    d=${ard[3]}
    if [  -f "${ARDIR}/$fn" ] ; then
	echo "skipping $fn"
    else
	# get
	docmd $ar wget $ar -O "${ARDIR}/$fn"
    fi
done

# ================================================================
# Extract
# ================================================================
for ar in ${ARS[@]} ; do
    banner 'EXTRACT' $ar
    ard=( $(extract-ar-info $ar) )
    fn=${ard[1]}
    ext=${ard[2]}
    d=${ard[3]}
    sd="$SRCDIR/$d"
    if [ -d $sd ] ; then
	echo "skipping $fn"
    else
	# unpack
	pushd $SRCDIR
	case "$ext" in
	    "bz2")
		docmd $ar tar jxf ${ARDIR}/$fn
		;;
	    "gz")
		docmd $ar tar zxf ${ARDIR}/$fn
		;;
	    "tar")
		docmd $ar tar xf ${ARDIR}/$fn
		;;
	    *)
		doerr "unrecognized extension: $ext" "Can't continue."
		;;
	esac
	popd
	if [ ! -d $sd ] ;  then
	    # Some archives (like gcc-g++) overlay. We create a dummy
	    # directory to avoid extracting them every time.
	    mkdir -p $sd
	fi
    fi
done

# ================================================================
# Build
# ================================================================
for ar in ${ARS[@]} ; do
    banner 'BUILD' $ar
    ard=( $(extract-ar-info $ar) )
    fn=${ard[1]}
    ext=${ard[2]}
    d=${ard[3]}
    sd="$SRCDIR/$d"
    bd="$BLDDIR/$d"
    if [ -d $bd ] ; then
	echo "skipping $sd"
    else
        # Build
	if [ $(expr match "$fn" 'gcc-g++') -ne 0 ] ; then
            # Don't build/configure the gcc-g++ package explicitly because
	    # it is part of the regular gcc package.
	    echo "skipping $sd"
	    # Dummy
	    continue
	fi

        # Set the CONF_ARGS
	in_bld=1 # build in the bld area
	run_conf=1
	run_bootstrap=0
    	run_cmake_bootstrap=0
	case "$d" in
	    binutils-*)
		# Binutils will not compile with strict error
		# checking on so I disabled -Werror by setting
		# --disable-werror.
		CONF_ARGS=(
		    --disable-cloog-version-check
		    --disable-werror
            	    --enable-cloog-backend=isl
		    --enable-lto
		    --enable-libssp
                    --enable-gold
		    --prefix=${RTFDIR}
		    --with-cloog=${RTFDIR}
		    --with-gmp=${RTFDIR}
		    --with-mlgmp=${RTFDIR}
		    --with-mpc=${RTFDIR}
		    --with-mpfr=${RTFDIR}	    
		    --with-ppl=${RTFDIR}
		    CC=${RTFDIR}/bin/gcc
		    CXX=${RTFDIR}/bin/g++
		)
		;;

	    boost_*)
		# The boost configuration scheme requires
		# that the build occur in the source directory.
		run_conf=0
		run_bootstrap=1
		in_bld=0
		CONF_ARGS=(
		    --prefix=${RTFDIR}
		    --with-python=python2.7
		)
		;;

	    cloog-*)
		GMPDIR=$(ls -1d ${BLDDIR}/gmp-*)
		CONF_ARGS=(
		    --prefix=${RTFDIR}
		    --with-gmp-builddir=${GMPDIR}
		    --with-gmp=build
		    ## --with-isl=system
		)
		;;

	    gcc-*)
		# We are using a newer version of CLooG (0.17.0).
		# I have also made stack protection available
		# (similar to DEP in windows).
		CONF_ARGS=(
		    --disable-cloog-version-check
		    --enable-gold
		    --enable-languages='c,c++'
		    --enable-lto
		    --enable-libssp
		    --prefix=${RTFDIR}
		    --with-cloog=${RTFDIR}
		    --with-gmp=${RTFDIR}
		    --with-mlgmp=${RTFDIR}
		    --with-mpc=${RTFDIR}
		    --with-mpfr=${RTFDIR}
            --with-isl=${RTFDIR}
            --with-system-zlib
            --enable-libstdcxx-time=yes
            --enable-stage1-checking
            --enable-checking=release
            --enable-plugin
		)
		;;

	    glibc-*)
		CONF_ARGS=(
		    --enable-static-nss=no
		    --prefix=${RTFDIR}
		    --with-binutils=${RTFDIR}
		    --with-elf
		    CC=${RTFDIR}/bin/gcc
		    CXX=${RTFDIR}/bin/g++
		)
		;;

	    gmp-*)
		CONF_ARGS=(
		    --enable-cxx
		    --prefix=${RTFDIR}
		)
		;;

	    libiconv-*)
		CONF_ARGS=(
		    --prefix=${RTFDIR}
		)
		;;

	    mpc-*)
		CONF_ARGS=(
		    --prefix=${RTFDIR}
		    --with-gmp=${RTFDIR}
		    --with-mpfr=${RTFDIR}
		)
		;;

	    mpfr-*)
		CONF_ARGS=(
		    --prefix=${RTFDIR}
		    --with-gmp=${RTFDIR}
		)
		;;

	    isl-*)
		CONF_ARGS=(
		    --prefix=${RTFDIR}
            --disable-dependency-tracking
		    --with-gmp-prefix=${RTFDIR}
		)
		;;
	
	ppl-*)
                CONF_ARGS=(
                    --prefix=${RTFDIR}
                    --with-gmp=${RTFDIR}
                )
                ;;

        boost_*)
        # The boost configuration scheme requires
        # that the build occur in the source directory.
        run_conf=0
        run_bootstrap=0
        run_cmake_bootstrap=1
        #in_bld=0
        CONF_ARGS=(
            --prefix=${RTFDIR}
            --no-qt-gui
        )
        ;;


	    *)
		doerr "unrecognized package: $d"
		;;
	esac

	if (( $in_bld )) ; then
	    mkdir -p $bd
	    pushd $bd
	else
	    echo "NOTE: This package must be built in the source directory."
	    pushd $sd
	fi
	if (( $run_conf )) ; then
	    docmd $ar $sd/configure --help
	    docmd $ar $sd/configure ${CONF_ARGS[@]}
	    docmd $ar make
	    docmd $ar make install
	fi
	if (( $run_cmake_bootstrap )) ; then
	    docmd $ar which g++
	    docmd $ar $sd/bootstrap.sh --help
	    docmd $ar $sd/bootstrap.sh ${CONF_ARGS[@]}
	    docmd $ar make
	    docmd $ar make install
	fi
    if (( $run_bootstrap )) ; then
        docmd $ar which g++
        docmd $ar $sd/bootstrap.sh --help
        docmd $ar $sd/bootstrap.sh ${CONF_ARGS[@]}
        docmd $ar ./b2
        docmd $ar ./b2 install
    fi

	# Redo the tests if anything changed.
	if [ -d $TSTDIR ] ; then
	    rm -rf $TSTDIR
	fi
	popd
    fi
done

# ================================================================
# Test
# ================================================================
if [ -d $TSTDIR ] ; then
    echo "skipping tests"
else
    docmd "MKDIR" mkdir -p $TSTDIR
    pushd $TSTDIR
    docmd "LOCAL TEST  1" which g++
    docmd "LOCAL TEST  2" which gcc
    docmd "LOCAL TEST  3" which c++
    docmd "LOCAL TEST  4" g++ --version

    # Simple aliveness test.
    cat >test1.cc <<EOF
#include <iostream>
using namespace std;
int main()
{
  cout << "IO works" << endl;
  return 0;
}
EOF
    docmd "LOCAL TEST  5" g++ -O3 -Wall -o test1.bin test1.cc
    docmd "LOCAL TEST  6" ./test1.bin

    docmd "LOCAL TEST  7" g++ -g -Wall -o test1.dbg test1.cc
    docmd "LOCAL TEST  8" ./test1.dbg

    # Simple aliveness test for boost.
    cat >test2.cc <<EOF
#include <iostream>
#include <boost/algorithm/string.hpp>
using namespace std;
using namespace boost;
int main()
{
  string s1(" hello world! ");
  cout << "value      : '" << s1 << "'" <<endl;

  to_upper(s1);
  cout << "to_upper() : '" << s1 << "'" <<endl;

  trim(s1);
  cout << "trim()     : '" << s1 << "'" <<endl;

  return 0;
}
EOF
    docmd "LOCAL TEST  9" g++ -O3 -Wall -o test2.bin test2.cc
    docmd "LOCAL TEST 10" ./test2.bin

    docmd "LOCAL TEST 11" g++ -g -Wall -o test2.dbg test2.cc
    docmd "LOCAL TEST 12" ./test2.dbg

    docmd "LOCAL TEST" ls -l 
    popd
fi

