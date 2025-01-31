##################################################
#       SET UP THE MONGODB DATABASE
##################################################

download_exfor() {
    #echo "download of exfor deactivated, reactive in install_all.sh"
    curl -O "$1"
    tar -C text -xf "$(basename "$1")"
}

# install package required for MongoDB EXFOR creation
cd "$instpath_R"
instpkg_cust exforParser 09104fd60025c4d655d7fad1306a2afc2f049c6293136ed4e4a48652f80eba63

# create dirs for EXFOR master files
mkdir "$instpath_exfor"
chmod 777 "$instpath_exfor"
mkdir "$instpath_exfor_text"
chmod 777 "$instpath_exfor_text"
cd "$instpath_exfor"

download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_10001-10535.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_10536-11690.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_11691-13569.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_13570-13768.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_13769-14239.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_14240-20118.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_20119-21773.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_21774-22412.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_22413-22921.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_22922-23129.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_23130-23250.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_23251-23324.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_23325-23415.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_23416-A0099.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_A0100-C1030.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_C1031-D0487.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_D0488-E1841.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_E1842-F1045.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_F1046-O0678.tar.xz"
download_exfor "http://www.nucleardata.com/storage/repos/exfor/entries_O0679-V1002.tar.xz"

# populate the database

# the directory where the data is stored need to be writable
mkdir -p "/data/db"
#chmod -R 777 /data/db # according to https://git.embl.de/grp-bio-it/singularity-service-example

# start the mongodb server
mongod --fork --logpath /var/log/mongod.log

# download and run MongoDB EXFOR creation script
mkdir "$instpath_R2"
chmod 777 "$instpath_R2"
cd "$instpath_R2"

Rfile="$instpath_R2/createExforDb/create_exfor_mongodb.R"
download_git_cust createExforDb 10c618b46ef402be1fc82a0e6583ea09fccae23003c23f99b1448fedc027c29f
chmod -R 777 "$instpath_R2"
sed -i -e "s|<PATH TO DIRECTORY WITH EXFOR ENTRIES>|$instpath_exfor_text|" "$Rfile"
Rscript --no-save --vanilla "$Rfile" 

if [ "$keep_Rcodes" != "yes" ]; then
    rm -rf "$instpath_R2"
fi

# delete EXFOR master files if requested
if [ "$keep_exfor" != "yes" ]; then
    rm -rf "$instpath_exfor"
else
    mv "$instpath_exfor_text" "$instpath/exfortmp"
    rm -rf "$instpath_exfor"
    mv "$instpath/exfortmp" "$instpath_exfor"
fi

# now we're done with creating the data-base, so shutdown the mongod
# we shoudl do this so we can restart it when starting the container
mongod --shutdown