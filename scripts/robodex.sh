PKG=@0x/contracts-asset-proxy yarn $1
PKG=@0x/contracts-robodex yarn $1

if [ "$1" == "build" -o "$1" == "rebuild" ]; then
    source ./scripts/copy_generated.sh
fi