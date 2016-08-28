SHTC1 Temperature and Humidity sensor support package for OpenWRT  14.07 (Barier Braker)
===============================================================================

In order to include sensor driver with i2c interface, you need to 
* either build our kernel and build driver against it and than build your image (the hard way)
* or use OpenWRT SDK to build your kernel module package.

First option is not trivial, since including the driver in main kernel tree changes the version magic of the kernel and thus breaks dependencies of other packages.
Rebuilding all packages is pain - I takes a lot of time and usually something fails.On the other hand, building driver out of the tree makes nontrivial to include it in the image.


Option 1: Building your own image (the hard way): you want to:
=====================
* Build original kernel
* Build driver as out-of thre module
* Make OpnWRT package out of it
* Build custom OpenWRT image
* Flash it

This means:

* Download sources/feeds/tools (http://wiki.openwrt.org/doc/howto/build)
* Download config file and configure (.config, they are using kernel like configuration) (DO NOT CHANGE CONFIGURATION of kernel, otherwise you will break dependencies for prebuilt packages !!)
* Build tools and toolchain ( http://wiki.openwrt.org/doc/howtobuild/single.package)
* Compile kernel
* prepare package with our driver
* Run make olconfig/menuconfig to add our package
* Build our package and packages, our driver is dependent on
* Make image index
* Download image builder
* Configure image builder repository files
* Build custom image
* Flash the image (i.e., follow the instructions https://wiki.openwrt.org/doc/howto/generic.flashing)

Option 2: Use SDK (The easy way)

* Donwload SDK (e.g, https://downloads.openwrt.org/chaos_calmer/15.05.1/ramips/rt305x/OpenWrt-SDK-15.05.1-ramips-rt305x_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2)
* Make directory /package/kernel/<YOUR-PACKAGE-NAME>/
* Put there package sources
* Build only this package
* Build image && Flash image or Install the package

Fundamental steps (Option 1 and 2 - for option 2 only steps from "building package are necessary)"
==================================================================================================

HOW TO:
<pre>
# make workspace
mkdir xxx
cd xxx
# this directory I call in the next BUILDROOT, but it is not necessary to define this var
BUILDROOT=`pwd`/
 
# Download feeds
###################
git clone git://git.openwrt.org/14.07/openwrt.git
# choose the right version of the kernel, to be sure we will not break dependencies and we will make package, that can be used 
# by users with downloaded OpenWRT
git checkout tags/14.07

cd openwrt/
./scripts/feeds update -a
./scripts/feeds install -a
 
# Download config file
###################
# !! DO NOT CHANGE CONFIGURATION of kernel, otherwise you will break dependencies for prebuild packages !!

# For OpenWRT 14.07: 
wget  https://downloads.openwrt.org/chaos_calmer/15.05/ramips/rt305x/.config

# For Open WRT 15.05 on ramips (modify the path for your architecture):
wget  https://downloads.openwrt.org/chaos_calmer/15.05/ramips/rt305x/config.diff 
mv config.diff .config
make defconfig
 
#build tools/toolchain
###################
make tools/install
make toolchain/install
 
#build kernel
###################
make target/linux/compile
 
# prepare this driver package
############################
# ~ make a directory in $BUILDROOT/packages/kernel, with content of the following zip file (makefile and sources)
git clone https://github.com/tpcz/openwrt-shtc1.git
git checkout 14.07
mv openwrt-shtc1 $BUILDROOT/package/kernel/shtc1
# now, there should be directory $BUILDROOT/packages/kernel/shtc1 with Makefile and src subdir
# presence of Makefile will update Ktree on the next make invocation, so run make olconfig and allow kmod-shtc1
make oldconfig
# say yes
# or use menuconfig to be sure, you have shtc1 enabled.
 
# build our package
############################
make package/shtc1/compile V=s
# 'shtc1' is the mane of directory in package subdirectory created previously
# this will build all the dependencies
 
#build our package
###################
make package/kmod-shtc1/compile
# replace DEPENDS=... line with the line from gpio-custom package.
make package/shtc1/ compile
 
# make package index
###################
make package/index
# this will create package list
# if you experience "staging_dir/bin/usign: No such file" error, you will need to run "make"
# to the phase, when you will see line "make -C packages/usign host-compile"

#Download image builder
########################
cd ../
wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
tar -xjf OpenWrt-ImageBuilder-*.tar.bz2
mv OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64 image-builder
cd image-builder
 
# Configre repositories, to include repository with our package
################################################################
# insert the following into image-builder/repositories.conf
 
#------------------------------------------------------------------------------------------------------------------------
## Place your custom repositories here, they must match the architecture and version
 
## our feature
src/gz custom file://<HERE PUT YOUR $BUILDROOT>/openwrt/bin/<YOUR-ARCHITECTURE>/packages/base
 
## prebuild repositories
src/gz barrier_breaker_base http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/base
src/gz barrier_breaker_luci http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/luci
src/gz barrier_breaker_management http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/management
src/gz barrier_breaker_oldpackages http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages
src/gz barrier_breaker_packages http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/packages
src/gz barrier_breaker_routing http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/routing
src/gz barrier_breaker_telephony http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/telephony
 
## This is the local package repository, do not remove!
src imagebuilder file:packages
#------------------------------------------------------------------------------------------------------------------------
 
#build image with our packages
#############################################################33
cd $BUILDROOT/image-builder/
 
# part of files that are prepared in the repository are preconfigured config files, FILES="../files" will add them to image.
# for details, see other subpages from this documentation
 
# flavour with web interface
#make image PROFILE=Default PACKAGES="kmod-i2c-gpio-custom kmod-hwmon-sht21 kmod-shtc1 luci luci-i18n-english " FILES="../files"
# flavour without web iterface, but including curl, so nothing as downloaded after restart...
make image PROFILE=Default PACKAGES="kmod-i2c-gpio-custom kmod-hwmon-sht21 kmod-shtc1 curl httpd" FILES="../files"
 
 
# flash the image
#############################################################33
# A) For the very first time (re-flashing original firmware)
# have a look at router package, you will find there login information.
# log in web interface -> System -> Update firmware
 
# B re-flashing openWRT image.
# B1) if you have luci (web interface on your open WRT image)
#   1) open luci on 192.168.1.1
#   2) put pwd 'kopretina', user is root
#   3) Software-> update firmware
# B2 if you dont have interface
# copy it to roouter with scp and use mtr tool (described in FAilsafe mode section here: http://wiki.openwrt.org/toh/tp-link/tl-mr3020#downgrade.attitute.adjustment.from.trunk)
#   1) cd IMAGE_BUILDER_HOME
#   2) scp ./bin/ar71xx/openwrt-ar71xx-generic-tl-mr3020-v1-squashfs-factory.bin root@192.168.100.1:/tmp/
#   3) connect with ssh
#   4) mtd -r write /tmp/openwrt-ar71xx-generic-tl-mr3020-v1-squashfs-factory.bin firmware
</pre>
