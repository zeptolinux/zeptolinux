set -e

ZEPTO_VER=$(cat src/VERSION | tr -s '\n')
KERNEL_VER=$(cat src/KERNEL | tr -s '\n')

echo "Zepto Linux - v$ZEPTO_VER for Linux kernel v$KERNEL_VER"
echo

docker build . -t zepto-build:"$ZEPTO_VER"

echo "building container done! running the builder as PRIVILEGED CONTAINER! ..."

CONTAINER=$(docker run --privileged -it --detach -v /dev:/zepto/dev zepto-build:"$ZEPTO_VER" bash)

echo "Container id: $CONTAINER"

docker exec -it $CONTAINER bash -c "./build.sh"

echo "builder done! copying image ..."

docker cp $CONTAINER:/zepto/zepto.img ./zepto.img

echo "compressing image ..."

xz zepto.img

mkdir builds || true
mv zepto.img.xz builds/zeptolinux-"$ZEPTO_VER".img.xz

echo "DONE!"
