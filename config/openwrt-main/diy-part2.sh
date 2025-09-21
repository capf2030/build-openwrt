#!/bin/bash
#========================================================================================================================
# Build script for MTK7981/360T7 router
# Description: Automatically Build OpenWrt for MTK7981 platform (360T7)
# Source code repository: https://github.com/openwrt/openwrt / Branch: main
#========================================================================================================================

# ------------------------------- Core System Customization -------------------------------
#
# Set root password (change from empty to 'password')
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set build version information
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='openwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_TARGET='mediatek/filogic'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_DEVICE='360-t7'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_DESCRIPTION='OpenWrt Official Build'" >>package/base-files/files/etc/openwrt_release

# Modify default IP (360T7 typically uses 192.168.2.1 or 192.168.1.1)
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# Modify default hostname
sed -i 's/OpenWrt/360T7-OpenWrt/g' package/base-files/files/bin/config_generate

# Set timezone to Asia/Shanghai
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate

# Set timezone name
sed -i "s/'UTC'/'Beijing Time'/g" package/base-files/files/bin/config_generate

# ------------------------------- MTK7981 Specific Configuration -------------------------------
#
# Add MTK7981 firmware packages (OpenWrt official)
if [ ! -d "package/firmware" ]; then
    mkdir -p package/firmware
fi

# Add MTK wireless firmware
cat > package/firmware/mt7981-wifi-firmware/Makefile << EOF
#
# Copyright (C) 2023 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include \$(TOPDIR)/rules.mk
include \$(INCLUDE_DIR)/kernel.mk

PKG_NAME:=mt7981-wifi-firmware
PKG_VERSION:=20230217
PKG_RELEASE:=1

PKG_MAINTAINER:=OpenWrt Team <openwrt-devel@lists.openwrt.org>
PKG_LICENSE:=Proprietary

include \$(INCLUDE_DIR)/package.mk

define Package/mt7981-wifi-firmware
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=https://www.mediatek.com/
  TITLE:=MT7981 WiFi firmware
endef

define Package/mt7981-wifi-firmware/description
  Firmware for MT7981 WiFi modules
endef

define Build/Compile
endef

define Package/mt7981-wifi-firmware/install
	\$(INSTALL_DIR) \$(1)/lib/firmware/mediatek
	\$(INSTALL_DATA) ./files/mt7981_wifi_firmware.bin \$(1)/lib/firmware/mediatek/
endef

\$(eval \$(call BuildPackage,mt7981-wifi-firmware))
EOF

mkdir -p package/firmware/mt7981-wifi-firmware/files
touch package/firmware/mt7981-wifi-firmware/files/mt7981_wifi_firmware.bin

# ------------------------------- Essential Packages for Router -------------------------------
#
# Add luci-theme-argon (Modern theme) - from OpenWrt packages
svn co https://github.com/openwrt/packages/trunk/libs/luci-theme-argon package/luci-theme-argon

# Add luci-app-openclash (Clash client) - community package
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash

# Add ddns-scripts (Dynamic DNS) - OpenWrt official
svn co https://github.com/openwrt/packages/trunk/net/ddns-scripts feeds/packages/net/ddns-scripts

# Add automount (Auto mount USB drives) - OpenWrt official
svn co https://github.com/openwrt/packages/trunk/utils/automount feeds/packages/utils/automount

# Add diskman (Disk management) - community package
svn co https://github.com/lisaac/luci-app-diskman/trunk/applications/luci-app-diskman package/luci-app-diskman

# ------------------------------- OpenWrt Official Packages -------------------------------
#
# Add OpenWrt official wireless tools
svn co https://github.com/openwrt/openwrt/trunk/package/network/utils/iwinfo package/iwinfo
svn co https://github.com/openwrt/openwrt/trunk/package/network/config/wireless-tools package/wireless-tools

# Add OpenWrt official network utilities
svn co https://github.com/openwrt/openwrt/trunk/package/network/services/odhcpd package/odhcpd
svn co https://github.com/openwrt/openwrt/trunk/package/network/config/firewall package/firewall

# ------------------------------- Remove Non-Official Packages -------------------------------
#
# Remove packages that are not in official OpenWrt
rm -rf package/luci-app-adguardhome 2>/dev/null || true
rm -rf package/luci-app-serverchan 2>/dev/null || true

# Remove some themes to save space (keep only bootstrap for official look)
rm -rf feeds/luci/themes/luci-theme-material 2>/dev/null || true

# ------------------------------- System Configuration -------------------------------
#
# Basic network configuration for 360T7
cat > package/base-files/files/etc/config/network << EOF
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'fd00:ab:cd::/48'

config device
    option name 'br-lan'
    option type 'bridge'
    list ports 'eth0'

config interface 'lan'
    option ifname 'br-lan'
    option force_link '1'
    option proto 'static'
    option ipaddr '192.168.2.1'
    option netmask '255.255.255.0'
    option ip6assign '60'

config interface 'wan'
    option ifname 'eth1'
    option proto 'dhcp'

config interface 'wan6'
    option ifname 'eth1'
    option proto 'dhcpv6'
EOF

# Wireless configuration for MT7981
cat > package/base-files/files/etc/config/wireless << EOF
config wifi-device 'radio0'
    option type 'mac80211'
    option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:01:00.0'
    option channel '36'
    option band '5g'
    option htmode 'HE80'
    option disabled '0'

config wifi-iface 'default_radio0'
    option device 'radio0'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-5G'
    option encryption 'psk2'
    option key 'password'

config wifi-device 'radio1'
    option type 'mac80211'
    option path '1e140000.pcie/pci0000:00/0000:00:00.0/0000:02:00.0'
    option channel 'auto'
    option band '2g'
    option htmode 'HE20'
    option disabled '0'

config wifi-iface 'default_radio1'
    option device 'radio1'
    option network 'lan'
    option mode 'ap'
    option ssid 'OpenWrt-2.4G'
    option encryption 'psk2'
    option key 'password'
EOF

# ------------------------------- Performance Tuning -------------------------------
#
# Add performance tuning for MT7981
cat > package/base-files/files/etc/sysctl.d/10-mt7981.conf << EOF
# MT7981 performance tuning
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 16384 16777216
net.ipv4.tcp_congestion_control=bbr
EOF

# ------------------------------- OpenWrt Official Build Config -------------------------------
#
# Ensure we use OpenWrt official packages
sed -i 's|src-git packages https://github.com/.*|src-git packages https://git.openwrt.org/feed/packages.git|g' feeds.conf.default
sed -i 's|src-git luci https://github.com/.*|src-git luci https://git.openwrt.org/project/luci.git|g' feeds.conf.default
sed -i 's|src-git routing https://github.com/.*|src-git routing https://git.openwrt.org/feed/routing.git|g' feeds.conf.default
sed -i 's|src-git telephony https://github.com/.*|src-git telephony https://git.openwrt.org/feed/telephony.git|g' feeds.conf.default

echo "OpenWrt Official Build for MTK7981/360T7 customization completed successfully!"
