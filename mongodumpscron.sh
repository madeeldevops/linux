#!binbash

# MongoDB Connection Details
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DATABASE=your database name
MONGO_USER=your mongo username
MONGO_PASS=your mongo username password
URI=mongodb${MONGO_USER}${MONGO_PASS}@${MONGO_HOST}${MONGO_PORT}

# AWS S3 Details
S3_BUCKET=s3your bucket name
S3_PREFIX=staging

# Backup Directory , or path of your directory
BACKUP_DIR=homeubuntumongodumps

# Date and Timestamp
DATE=$(date +%Y%m%d_%H%M%S)

# Backup Filename
BACKUP_FILENAME=${MONGO_DATABASE}_${DATE}

# Perform MongoDB Backup
mongodump --uri $URI --db $MONGO_DATABASE --out $BACKUP_DIR

# Upload Backup to S3
aws s3 cp $BACKUP_DIR$MONGO_DATABASE $S3_BUCKET$S3_PREFIX$BACKUP_FILENAME --recursive

# Cleanup - Remove Local Backup File
rm -rf $BACKUP_DIR$MONGO_DATABASE