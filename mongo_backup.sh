#!/bin/bash

# ১. পাথ ও তারিখ ফরম্যাট
BACKUP_DIR="/tmp/mongo_backups"
DATE_FOLDER=$(date +%Y-%m-%d)
TIME=$(date +%H-%M-%S)
BACKUP_NAME="backup_$TIME"
DUMP_DIR="$BACKUP_DIR/$BACKUP_NAME"

# গুগল ড্রাইভে তারিখের ফোল্ডারের পাথ
RCLONE_REMOTE="gdrive:MongoDB_Backups/$DATE_FOLDER"

# ২. MongoDB Atlas কানেকশন স্ট্রিং
MONGO_URI="mongodb+srv://<username>:<password>@cluster0.your_cluster.mongodb.net/<database_name>?appName=Cluster0"

# লোকাল টেম্পোরারি ফোল্ডার তৈরি
mkdir -p "$DUMP_DIR"

# ৩. ডাটাবেস ডাম্প নেওয়া (BSON ফরম্যাটে)
mongodump --uri="$MONGO_URI" --out="$DUMP_DIR"

# ৪. BSON ফাইলগুলোকে JSON এ কনভার্ট করা এবং অপ্রয়োজনীয় BSON ফাইল মুছে ফেলা
find "$DUMP_DIR" -type f -name "*.bson" | while read -r bson_file; do
    json_file="${bson_file%.bson}.json"
    bsondump "$bson_file" > "$json_file"
    rm -f "$bson_file"
done

# ৫. সব JSON ফাইল নিয়ে ZIP তৈরি করা
cd "$BACKUP_DIR"
zip -r "$BACKUP_NAME.zip" "$BACKUP_NAME"

# ৬. Google Drive-এ .zip ফাইল আপলোড
rclone copy "$BACKUP_DIR/$BACKUP_NAME.zip" "$RCLONE_REMOTE"

# ৭. লোকাল টেম্পোরারি ফাইল ও ফোল্ডার ডিলিট
rm -rf "$DUMP_DIR"
rm -f "$BACKUP_DIR/$BACKUP_NAME.zip"

# ৮. ৩০ দিনের পুরোনো ফাইল ও খালি ফোল্ডার রিমুভ করা
rclone delete --min-age 30d "gdrive:MongoDB_Backups"
rclone rmdirs --leave-root "gdrive:MongoDB_Backups"
