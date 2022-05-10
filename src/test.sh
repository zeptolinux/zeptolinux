#!/bin/sh

echo "[TEST] start"

echo "[TEST] mounting proc ..."
toybox mount -t proc proc proc

echo "[TEST] remount / rw ..."
toybox mount -o remount,rw /
echo $? >> /test.log

echo "[TEST] done!"
