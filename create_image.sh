#!/bin/bash
while getopts ":n:t:v:p:h" opt; do
    case $opt in
        n)
            NAME=$OPTARG
            ;;
        t)
            TYPE=$OPTARG
            ;;
        v)
            VARIANT=$OPTARG
            ;;
        p)
            PACKAGES=$OPTARG
            ;;
        h)
            echo "Usage: $0 -n <directory name> -t <image type> -h (help) -p <packages> -v <variant>"
            echo "  -n: Specify the name of the directory to create (default: rootfs)"
            echo "  -v: Specify the variant for debootstrap (e.g., buildd, minbase)"
            echo "  -t: Specify the type of image to create (e.g., noble, noble-dev)"
            echo "  -p: Specify additional packages to include in the image (comma-separated)"
            echo "  -h: Display this help message"
            exit 1
            ;;
    esac
done

#-----------------------------------------------------------------------------
# Set default values if variables are not provided
#-----------------------------------------------------------------------------
if [ -z "$NAME" ]; then
    DIR_NAME="image"
else
    DIR_NAME="$NAME"
fi

#-----------------------------------------
if [ -z "$TYPE" ]; then
    IMAGE_TYPE="noble"
else
    IMAGE_TYPE="$TYPE"
fi

#-----------------------------------------
if [ -z "$VARIANT" ]; then
    DEBOOTSTRAP_VARIANT="buildd"
else
    DEBOOTSTRAP_VARIANT="$VARIANT"
fi

#-----------------------------------------
if [ -z "$PACKAGES" ]; then
    DEBOOTSTRAP_PACKAGES=""
else
    DEBOOTSTRAP_PACKAGES="--include=$(echo $PACKAGES | tr ',' ',')"
fi


#-----------------------------------------------------------------------------
#                       Check if the directory exists
#-----------------------------------------------------------------------------
if [ -d "$DIR_NAME" ]; then
    echo "Directory $DIR_NAME already exists. Removing and recreating it."
    rm -rf "$DIR_NAME"
fi

printf "\nCreating the directories for the new image"
mkdir -p $DIR_NAME/image/blobs/sha256
cp oci-layout $DIR_NAME/image/oci-layout
touch $DIR_NAME/index.json
touch $DIR_NAME/config.json
touch $DIR_NAME/manifest.json


#------------------------------------------------------------------------------
#                       create rootfs
#------------------------------------------------------------------------------
printf "\nBeginning Debootstrap for $DEBOOTSTRAP_VARIANT"

debootstrap --variant=$DEBOOTSTRAP_VARIANT $DEBOOTSTRAP_PACKAGES $IMAGE_TYPE $DIR_NAME/rootfs

printf "\nCreating tar file for $DIR_NAME"
tar -cf $DIR_NAME/rootfs.tar $DIR_NAME/rootfs/
TAR_SHA=$(sha256sum $DIR_NAME/rootfs.tar | cut -d " " -f1)
printf "\nSHA HASH: $TAR_SHA\n"

printf "\nZipping the tar file\n"
gzip --keep $DIR_NAME/rootfs.tar
TAR_GZ_SHA=$(sha256sum $DIR_NAME/rootfs.tar.gz | cut -d " " -f1)

printf "\nSHA HASH: $TAR_GZ_SHA"
printf "\nMoving tar.gz to the sha256 folder and renaming to the above hash."
cp $DIR_NAME/rootfs.tar.gz $DIR_NAME/image/blobs/sha256/$TAR_GZ_SHA

#-----------------------------------------------------------------------------
#                           config.json
#-----------------------------------------------------------------------------
cat <<JSON > $DIR_NAME/config.json
{
  "created": "$(date --iso-8601=ns)",
  "author": "Novaic_Solutions",
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [ "PATH=/usr/bin:/bin" ],
    "Entrypoint": [ "/usr/bin/bash" ]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:$TAR_SHA"
    ]
  }
}
JSON

CONFIG_SHA=$(sha256sum $DIR_NAME/config.json | cut -d " " -f1)
printf "\nconfig.json created, sha: $CONFIG_SHA.   Moving to sha256 folder"
cp $DIR_NAME/config.json $DIR_NAME/image/blob/sha256/$CONFIG_SHA

#-----------------------------------------------------------------------------
#                           manifest.json
#-----------------------------------------------------------------------------
cat <<JSON > $DIR_NAME/manifest.json
{
  "schemaVersion": 2,
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": $(du --bytes $DIR_NAME/config.json | grep -oE "[[:digit:]]+"),
    "digest": "sha256:$CONFIG_SHA"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": $(du --bytes $DIR_NAME/rootfs.tar.gz | grep -oE "[[:digit:]]+"),
      "digest": "sha256:$TAR_GZ_SHA"
    }
  ]
}
JSON

MANIFEST_SHA=$(sha256sum $DIR_NAME/manifest.json | cut -d " " -f1)
printf "\nCreated manifest.json with sha: $MANIFEST_SHA.  Moving to sha256 directory"
cp $DIR_NAME/manifest.json $DIR_NAME/image/blobs/sha256/$MANIFEST_SHA

#-----------------------------------------------------------------------------
#                           index.json
#-----------------------------------------------------------------------------
cat <<JSON > $DIR_NAME/index.json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "size": $(du --bytes $DIR_NAME/manifest.json | grep -oE "[[:digit:]]+"),
      "digest": "sha256:$MANIFEST_SHA",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    }
  ]
}
JSON

printf "\nCreated index.json\n\n"