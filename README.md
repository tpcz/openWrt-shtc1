Building OpenWRT image 15.05 (Chaos Calmer) with SHTC1 humidity sensor support
===============================================================================

In order to include i2c driver, you need to to build our kernel and build driver against it.
This is not trivial, because including the driver in main kernel tree changes the version magic of the kernel and thus breaks dependencies of other packages.
On the other hand, building driver out of the tree makes nontrivial to include it in the image.

So you want to:
=====================
* Build original kernel
* Build driver as out-of thre module
* Make OpnWRT package out of it
* Build custom OpenWRT image
* Flash it nad enjoy

Fundamental steps
=====================
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
* Flash the image   http://wiki.openwrt.org/toh/tp-link/tl-mr3020

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
cd openwrt/
./scripts/feeds update -a
./scripts/feeds install -a
 
# Download config file
###################
# !! DO NOT CHANGE CONFIGURATION of kernel, otherwise you will break dependencies for prebuild packages !!
# For Open WRT 14.04:
wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/config.ar71xx_generic
mv config.ar71xx_generic .config
 
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
mv openwrt-shtc1 $BUILDROOT/packages/kernel/shtc1
# now, there should be directory $BUILDROOT/packages/kernel/shtc1 with Makefile and src subdir
# presence of Makefile will update Ktree on the next make invocation, so run make olconfig and allow kmod-shtc1
make oldconfig
# say yes
 
 
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
 
#Download image builder
########################
cd ../
wget http://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
# wget https://downloads.openwrt.org/chaos_calmer/15.05/ramips/mt7620/OpenWrt-ImageBuilder-15.05-ramips-mt7620.Linux-x86_64.tar.bz2
tar -xjf OpenWrt-ImageBuilder-*.tar.bz2
mv OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64 image-builder
cd image-builder
 
# Configre repositories, to include repository with our package
################################################################
# insert the following into image/builder/repositories.conf
 
#------------------------------------------------------------------------------------------------------------------------
## Place your custom repositories here, they must match the architecture and version
 
## our feature
src/gz custom file://<HERE PUT YOUR $BUILDROOT>/openwrt/bin/ar71xx/packages/base
 
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
