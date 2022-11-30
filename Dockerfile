FROM ubuntu:latest as build

ARG ZEPTO_VER
ARG KERNEL_VER

RUN echo "Building Kernel ${KERNEL_VER} with Zepto ${ZEPTO_VER}"

RUN apt-get update && apt-get install -y make gcc flex bison libelf-dev bc zstd wget dosfstools mtools xz-utils parted
RUN fallocate -l 3M root.ext2
RUN mkfs.ext2 root.ext2
COPY debugfs.cmd .
RUN wget "https://landley.net/toybox/downloads/binaries/0.8.8/toybox-x86_64" -O toybox && chmod u+x toybox
RUN for i in $(./toybox); do echo "ln /bin/toybox /bin/${i}" | tee -a debugfs.cmd > /dev/null; done
#RUN for i in $(./toybox); do echo "/bin/${i}"; done
#RUN cat /debugfs.cmd
RUN debugfs -w -f debugfs.cmd root.ext2
RUN debugfs -w -R ln /bin/sh /bin/init root.ext2 

# TODO: 
# cp src/test.sh root/bin/test.sh
# chmod +x root/bin/test.sh

RUN wget -q --show-progress https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-"$KERNEL_VER".tar.xz -O /linux.tar.xz
#RUN tar --list -f /linux.tar.xz
RUN tar -xvf linux.tar.xz

COPY src/.config .
RUN sed -i 's/CONFIG_LOCALVERSION="-zepto_current"/CONFIG_LOCALVERSION="-zepto_$ZEPTO_VER"/' .config

RUN cd linux-* && cp ../.config . && make olddefconfig && make -j$(nproc)

RUN ls -lsa linux-*/arch/x86/boot/bzImage

RUN fallocate -l 4M boot.vfat
RUN mkfs.vfat boot.vfat
RUN mmd -i boot.vfat ::EFI
RUN mmd -i boot.vfat ::EFI/boot
RUN mcopy -i boot.vfat linux-*/arch/x86/boot/bzImage ::EFI/boot/bootx64.efi

RUN fallocate -l 7M zepto.img
RUN parted --script ./zepto.img -- "mklabel gpt" "mkpart esp fat32 17408B 4211200B" "set 1 esp on" "mkpart root 4211712B 7322624B" # 4M efi boot partition, 3M linux root partition

RUN dd if=boot.vfat seek=17408 bs=1 count=$(du -bs boot.vfat | cut -f1) of=zepto.img

# something's wrong here ...:
RUN dd if=root.ext2 seek=4211712 bs=1 count=$(du -bs root.ext2 | cut -f1) of=zepto.img



FROM scratch as export

COPY --from=build /zepto.img /
COPY --from=build /boot.vfat /
COPY --from=build /root.ext2 /
