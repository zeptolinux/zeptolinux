FROM ubuntu

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC  apt-get -y install build-essential wget \
  flex bison libelf-dev bc zstd dosfstools parted udev qemu-system-x86

RUN mkdir /zepto
COPY builder/* /zepto/
RUN mkdir /zepto/src
COPY src/* /zepto/src/

RUN chmod +x /zepto/build.sh

WORKDIR /zepto

CMD bash
