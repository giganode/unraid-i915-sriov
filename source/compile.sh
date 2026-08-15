# Create the necessary directories and clone repository
mkdir -p /i915SRIOV/lib/modules/${UNAME}/kernel/drivers/gpu/drm/i915
cd ${DATA_DIR}
git clone https://github.com/strongtz/i915-sriov-dkms
cd ${DATA_DIR}/i915-sriov-dkms

# Upstream master tracks the current mainline snapshot and requires kernel v6.17+.
# Older unRAID kernels (6.12.x ... 6.16.x) need the maintained older release
# 2026.03.05.6, which contains the pci_resize_resource() 4-argument conftest fix
# (strongtz/i915-sriov-dkms commit 65fd1a7 / release 2026.03.05.3, issue #467).
KERNEL_SHORT="${UNAME%%-*}"
case "${KERNEL_SHORT}" in
    6.12.*|6.13.*|6.14.*|6.15.*|6.16.*)
        git checkout 2026.03.05.6
        ;;
    *)
        git checkout master
        ;;
esac

PLUGIN_VERSION="$(git log -1 --format="%cs" | sed 's/-//g')"

# Compile custom i915 SR-IOV module and copy it over to temporary location
make -j${CPU_COUNT} -C ${DATA_DIR}/linux-$UNAME M=${DATA_DIR}/i915-sriov-dkms
cp ${DATA_DIR}/i915-sriov-dkms/i915.ko /i915SRIOV/lib/modules/${UNAME}/kernel/drivers/gpu/drm/i915/
mkdir -p /i915SRIOV/lib/modules/${UNAME}/updates/compat
cp ${DATA_DIR}/i915-sriov-dkms/compat/intel_sriov_compat.ko /i915SRIOV/lib/modules/${UNAME}/updates/compat/

# Compress modules
while read -r line
do
  xz --check=crc32 --lzma2 $line
done < <(find /i915SRIOV/lib/modules/${UNAME}/kernel/drivers/gpu/drm/i915 -name "*.ko")

# Create Slackware package
PLUGIN_NAME="i915-sriov"
BASE_DIR="/i915SRIOV"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"
mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME Package contents:
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://github.com/strongtz/i915-sriov-dkms
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-$PLUGIN_VERSION-$UNAME-1.txz.md5
