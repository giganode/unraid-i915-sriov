# Create the necessary directories and clone repository
mkdir -p /i915SRIOV/lib/modules/${UNAME}/kernel/drivers/gpu/drm/i915
cd ${DATA_DIR}
git clone https://github.com/strongtz/i915-sriov-dkms
cd ${DATA_DIR}/i915-sriov-dkms
git checkout tags/2025.07.22
PLUGIN_VERSION="$(git log -1 --format="%cs" | sed 's/-//g')"

# Compile custom i915 SR-IOV module and copy it over to temporary location
make -j${CPU_COUNT} -C ${DATA_DIR}/linux-$UNAME M=${DATA_DIR}/i915-sriov-dkms
cp ${DATA_DIR}/i915-sriov-dkms/i915.ko /i915SRIOV/lib/modules/${UNAME}/kernel/drivers/gpu/drm/i915/

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
