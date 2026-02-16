#!/bin/bash
while getopts ":n:t" opt; do
    case $opt in
        n)
            NAME=$OPTARG
            ;;
        t)
            TYPE=$OPTARG
            ;;
        h)


#-----------------------------------------------------------------------------
#                       Get arguments
#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
#                       Check if the directory exists
#-----------------------------------------------------------------------------

#debootstrap --variant=buildd --include=python3 noble rootfs

#------------------------------------------------------------------------------
#                       create rootfs
#------------------------------------------------------------------------------
#   Run debootstrap to create the rootfs directory
#   tar -cf rootfs.tar rootfs/    to create the initial tar file
#   gzip --keep rootfs.tar        to create the compressed tar file
#   sha256sum rootfs.tar.gz | cut -d " " -f1   to get the sha hash of the compressed tarball, save as variable
#   sha256sum rootfs.tar | cut -d " " -f1  to get the sha hash of the tarball, save as variable
#   move root.tar.gz to blobs/sha256/<hash value>


#------------------------------------------------------------------------------------------
#                       image-config.json
#------------------------------------------------------------------------------------------
#   create tar file of rootfs
#   get sha hash of the rootfs.tar and place it in the image-config.json under rootfs.diff_ids
#   get the sha hash of image-config.json and hold in variable
#   cp image-config.json to sha256/<hash value>


#----------------------------------------------------------------------------
#                       image-manifest.json
#----------------------------------------------------------------------------
#   get the sha hash of image-config.json and place it in image-manifest.json under config.digest
#   take the entire image-config.json file as a string, base64 encode it, and put that in the image-manifest.json under config.data
#   use du --byte image-config.json | cut -f1 to get the size in byes, store value in config.size
#   take the sha hash of rootfs.tar.gz and place it in image-manifest.json under layers.digest
#   use du --bytes root.tar.gz | cut -f1   and place the bytes total in image-manifest.json under layers.size
#   get sha hash of image-manifest.json and store as variable
#   cp image-manifest.json to sha256/<hash value>


#-----------------------------------------------------------------------------
#                           index.json
#-----------------------------------------------------------------------------
#   take image-manifest.json's hash and place in manfiests.digest
#   use du --bytes blobs/image-manifest.json | cut -f1   and save value in manifests.size
#   get the entire image-manifests.json file as a string and base64 encode it. then place that value in manifests.data


#-----------------------------------------------------------------------------
#                           manifest.json
#-----------------------------------------------------------------------------
#   place value blobs/sha256/<hash for image-config.json> in Config
#   place value blobs/sha256/<hash for rootfs.tar.gz> in Layers

