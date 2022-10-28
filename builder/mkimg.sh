set -e # abort on error

rm zepto.img || true
truncate zepto.img -s 7M

#export DEV=$(losetup -f)
#docker : (needs --privileged=true as run param!)
export DEV="/zepto$(losetup -f)"
echo "dev=$DEV - $?"


cleanup() {
  echo "Cleanup!"
  umount root || true
  umount boot || true
  rm root -r
  rm boot -r
  losetup -d $DEV
}
#trap "cleanup" ERR
trap "cleanup" EXIT


echo "partitioning & formating image ..."
losetup $DEV zepto.img
parted --script $DEV -- "mklabel gpt" "mkpart esp fat32 17408B 4211200B" "set 1 esp on" "mkpart root 4211712B 7322624B" # 4M efi boot partition, 3M linux root partition
losetup -d $DEV # needs to be called again with -P param to create a sub-loop device for all partitions
sleep 2
losetup $DEV -P zepto.img
sleep 2

mkfs.vfat "$DEV"p1
mkfs.ext2 "$DEV"p2

rm ./boot ./root -r || true
mkdir boot
mkdir root


echo "mount image and copy compiled files ..."
mount "$DEV"p1 boot
mount "$DEV"p2 root

mkdir boot/EFI/boot -p
cp linux-*/arch/x86/boot/bzImage boot/EFI/boot/bootx64.efi


mkdir root/bin root/dev root/proc

if [[ ! -f "./toybox" ]]
then
  wget "https://landley.net/toybox/downloads/binaries/0.8.8/toybox-x86_64" -O toybox
fi

cp toybox root/bin/

cp src/test.sh root/bin/test.sh
chmod +x root/bin/test.sh


cd root/bin

chmod +x ./toybox
for i in $(./toybox); do ln -s toybox $i; done # create symlink for every toybox command

ln -s sh init

cd -

echo "DONE!"
