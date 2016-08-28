#
# Author: Tomas Pop
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=shtc1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define KernelPackage/shtc1
  SUBMENU:=Other modules
  DEPENDS:=@!LINUX_3_3 +kmod-i2c-core +kmod-hwmon-core +kmod-i2c-gpio-custom
  TITLE:=Drivers needed for kernel integration with environmental data of shtc1 sensor
  FILES:=$(PKG_BUILD_DIR)/shtc1.ko
  AUTOLOAD:=$(call AutoLoad,30,shtc1,1)
  KCONFIG:=CONFIG_PACKAGE_kmod-hwmon-core=m
endef

define KernelPackage/shtc1/description
 This package adds support for reading environmental data from following sensors:
 1) Sensirions SHTC1

 Instead of generating input events (like in-kernel drivers do) it generates
 uevent-s and broadcasts them. This allows disabling input subsystem which is
 an overkill for OpenWrt simple needs.
endef

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)"

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,shtc1))
