set -e

ZEPTO_VER=$(cat src/VERSION | tr -s '\n')
KERNEL_VER=$(cat src/KERNEL | tr -s '\n')

sed -i 's/CONFIG_LOCALVERSION="-zepto_current"/CONFIG_LOCALVERSION="-zepto_$ZEPTO_VER"/' src/.config


ID="linux-"

if [ -d "${ID}"* ] 2>/dev/null; then
  echo "Linux folder already available"
else
  set +e
  ls "${ID}"* >/dev/null 2>&1
  ret=$?
  set -e

  if [ $ret -ne 0 ]; then
    echo "downloading kernel $VER ..."
    wget -q --show-progress https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-"$KERNEL_VER".tar.xz -O linux.tar.xz

    echo "extracting kernel ..."
    tar -xf linux.tar.xz
  else
    echo "More than one Linux revision folders exists! Remove all or keep only one and execute this script again."
    ls ${ID}*
    exit -1
  fi
fi


echo "building kernel ..."
cd linux-*
#make mrproper
cp ../src/.config .
make olddefconfig
make -j$(grep -c ^processor /proc/cpuinfo)
cd -

echo "creating image ..."
chmod +x mkimg.sh
./mkimg.sh

echo "testing with qemu :)"
chmod +x test.sh
./test.sh

#qemu-kvm -drive file=~/zepto/zepto.img,media=disk,if=virtio -m 512M # -kernel arch/x86/boot/bzImage \
#  -append "console=ttyS0" -nographic -bios /usr/share/qemu/ovmf-x86_64.bin
#  -append "root=/dev/vda2 console=ttyS0" -nographic
