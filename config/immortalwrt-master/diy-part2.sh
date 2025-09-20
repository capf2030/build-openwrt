#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (After Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source started -------------------------------
#
# Add the default password for the 'root' user（Change the empty password to 'password'）
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Set etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release

# Modify default IP（FROM 192.168.1.1 CHANGE TO 192.168.6.1）
sed -i 's/192\.168\.1\.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# Modify default hostname (Change from 'OpenWrt' to 'Amlogical-Router')
sed -i 's/OpenWrt/Amlogical-Router/g' package/base-files/files/bin/config_generate

# Set timezone (Change to Asia/Shanghai)
sed -i "s/'UTC'/'CST-8'/g" package/base-files/files/bin/config_generate

# Set timezone name (Change to Beijing Time)
sed -i "s/'UTC'/'Beijing Time'/g" package/base-files/files/bin/config_generate
#
# ------------------------------- Main source ends -------------------------------

# ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic (Amlogic device management interface)
# svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic package/luci-app-amlogic

# Add luci-theme-argon (Modern theme)
git clone https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon

# Add luci-app-openclash (Clash client)
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash

# Add luci-app-adguardhome (AD Guard Home)
git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome

# Add ddns-scripts_cloudflare (DDNS support)
svn co https://github.com/openwrt/packages/trunk/net/ddns-scripts_cloudflare feeds/packages/net/ddns-scripts_cloudflare

# Add automount (Auto mount USB drives)
svn co https://github.com/openwrt/packages/trunk/utils/automount feeds/packages/utils/automount

# Add diskman (Disk management)
svn co https://github.com/lisaac/luci-app-diskman/trunk/applications/luci-app-diskman package/luci-app-diskman

# Serverchan (WeChat notification)
svn co https://github.com/tty228/luci-app-serverchan/trunk package/luci-app-serverchan

# Add software package replacement options
# coolsnowwolf default software package replaced with Lienol related software package
# rm -rf feeds/packages/utils/{containerd,libnetwork,runc,tini}
# svn co https://github.com/Lienol/openwrt-packages/trunk/utils/{containerd,libnetwork,runc,tini} feeds/packages/utils

# Add third-party software packages (The entire repository)
# git clone https://github.com/libremesh/lime-packages.git package/lime-packages

# Add third-party software packages (Specify the package)
# svn co https://github.com/libremesh/lime-packages/trunk/packages/{shared-state-pirania,pirania-app,pirania} package/lime-packages/packages

# Add to compile options
# sed -i "/DEFAULT_PACKAGES/ s/$/ pirania-app pirania ip6tables-mod-nat ipset shared-state-pirania uhttpd-mod-lua/" target/linux/armvirt/Makefile

# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci

# Remove some default packages to save space
rm -rf feeds/luci/applications/luci-app-vlmcsd
rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/applications/luci-app-aria2

# Add custom files to the image
# cp -rf ../files/* ./

#
# ------------------------------- Other ends -------------------------------
