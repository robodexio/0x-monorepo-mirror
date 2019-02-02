yarn $1

if [ "$1" == "build" -o "$1" == "rebuild" ]; then
    source ./scripts/copy_generated.sh
fi