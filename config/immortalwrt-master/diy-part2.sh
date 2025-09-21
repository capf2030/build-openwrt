#!/bin/bash
#========================================================================================================================
# Build script for MTK7981/360T7 router
# Description: Automatically Build OpenWrt for MTK7981 platform (360T7)
#========================================================================================================================

# ------------------------------- Core System Customization -------------------------------
#
# Set root password (change from empty to 'password')
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set build version information
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_TARGET='mediatek/filogic'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_DEVICE='360-t7'" >>package/base-files/files/etc/openwrt_release

# Modify default IP (360T7 typically uses 192.168.2.1 or 192.168.1.1)
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# Modify default hostname
sed -i 's/OpenWrt/360T7-Router/g' package/base-files/files/bin/config_generate

# Set timezone to Asia/Shanghai
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate

# Set timezone name
sed -i "s/'UTC'/'Beijing Time'/g" package/base-files/files/bin/config_generate

# ------------------------------- MTK7981 Specific Configuration -------------------------------
#
# Add MTK7981 specific packages and drivers
svn co https://github.com/openwrt/openwrt/trunk/package/kernel/mt7981-firmware package/mt7981-firmware

# Add wireless configuration for MTK7981
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
    option ssid '360T7-5G'
    option encryption 'psk2'
    option key '12345678'

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
    option ssid '360T7-2.4G'
    option encryption 'psk2'
    option key '12345678'
EOF

# ------------------------------- Essential Packages for Router -------------------------------
#
# Add luci-theme-argon (Modern theme)
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# Add luci-app-openclash (Clash client)
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash

# Add luci-app-adguardhome (AD Guard Home)
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome

# Add ddns-scripts (Dynamic DNS)
svn co https://github.com/openwrt/packages/trunk/net/ddns-scripts feeds/packages/net/ddns-scripts

# Add automount (Auto mount USB drives)
svn co https://github.com/openwrt/packages/trunk/utils/automount feeds/packages/utils/automount

# Add diskman (Disk management)
svn co https://github.com/lisaac/luci-app-diskman/trunk/applications/luci-app-diskman package/luci-app-diskman

# Add fullconenat for MTK (NAT acceleration)
svn co https://github.com/openwrt/openwrt/trunk/package/network/utils/fullconenat package/fullconenat

# ------------------------------- Hardware Specific Packages -------------------------------
#
# Add MTK hardware acceleration packages
svn co https://github.com/openwrt/openwrt/trunk/package/kernel/mtk-drivers package/mtk-drivers

# Add hwnat support
svn co https://github.com/openwrt/openwrt/trunk/package/network/config/hwnat package/hwnat

# ------------------------------- Remove Unnecessary Packages -------------------------------
#
# Remove packages not needed for router to save space
rm -rf feeds/luci/applications/luci-app-vlmcsd
rm -rf feeds/luci/applications/luci-app-aria2
rm -rf feeds/luci/applications/luci-app-qbittorrent

# Remove some themes to save space
rm -rf feeds/luci/themes/luci-theme-bootstrap
rm -rf feeds/luci/themes/luci-theme-material

# ------------------------------- System Optimization -------------------------------
#
# Enable hardware acceleration in network config
cat >> package/base-files/files/etc/config/network << EOF

config switch
    option name 'switch0'
    option reset '1'
    option enable_vlan '1'

config switch_vlan
    option device 'switch0'
    option vlan '1'
    option ports '0 1 2 3 6'

config interface 'wan'
    option proto 'dhcp'
    option device 'eth0.2'

config interface 'lan'
    option proto 'static'
    option ipaddr '192.168.2.1'
    option netmask '255.255.255.0'
    option device 'eth0.1'
EOF

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

# ------------------------------- Build Configuration -------------------------------
#
# Add to final Makefile if needed
# sed -i "/DEFAULT_PACKAGES/ s/$/ kmod-mt7981-firmware kmod-hwnat/" target/linux/mediatek/Makefile

echo "MTK7981/360T7 customization completed successfully!"
