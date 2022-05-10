set -e

touch qemu-test.log

qemu-system-x86_64 \
  -drive file=/zepto/zepto.img,media=disk,if=virtio,format=raw -m 512M \
  -machine q35 \
  -kernel linux-*/arch/x86/boot/bzImage \
  -append "root=/dev/vda2 console=ttyS0 init=/bin/test.sh" -nographic > qemu-test.log &

qemuPid=$!
echo "qemu = $qemuPid"


cleanup() {
  echo "Cleanup!"
  kill -9 $qemuPid
}
trap "cleanup" ERR
trap "cleanup" EXIT



while :
do
 if grep -F "[TEST] done!" qemu-test.log; then
   echo "test script done"
   break
 fi

 if grep -F " end Kernel panic - " qemu-test.log; then
   echo "test script failed! kernel panic!"
   exit -1
 fi

 echo "test not done... waiting..."
 i=$((i+1))

 if [ "$i" -gt 60 ]; then
   echo "TIMEOUT! :("
   exit -1
 fi

 sleep 1
done



echo "TODO: now check for the 'test.log' file in the root directory of root"



echo "DONE!"


