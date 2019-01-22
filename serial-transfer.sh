#/bin/sh

SED=$(which sed)
XXD=$(which xxd)

usage() {
  cat <<EOF
Usage: $0 <filename> <serial device>
  filename: the file to transfer
  serial device: the device file used to transfer the file (example: /dev/ttyUSB0)
EOF
}

SRC_PATH=$1
DEV=$2

if [ -z "$SRC_PATH" ]; then
  echo Please give the file to transfer!
  usage
  exit
fi

if [ ! -f "$SRC_PATH" ]; then
  echo The file to transfer does not exist or is not accessible!
  usage
  exit
fi

if [ -z "$DEV" ]; then
  echo Please give the serial device!
  usage
  exit
fi

SRC_FILE=$(basename "$1")

DST=/root/${SRC_FILE}
TMP=/tmp/${SRC_FILE}.xxd

# Convert binary to text
$XXD -g1 "${SRC_PATH}" > "$TMP"
$SED -i 's/^\(.\)\{10\}//g' "$TMP"
$SED -i 's/\(.\)\{18\}$//g' "$TMP"

# Transfer file
cat "$TMP" | while read line; do
  echo "echo \"${line}\" >> ${TMP};" > $DEV;
done;

# Convert back to binary
echo "for i in \$(cat ${TMP}); do printf \"\x\$i\"; done > $DST" > $DEV;

# Clean up local temporary file
rm "${TMP}"
# Clean up remote temporary file
echo "rm \"${TMP}\";" > $DEV;
