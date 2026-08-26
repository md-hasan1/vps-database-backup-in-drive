# 🗄️ Automated MongoDB Backup to Google Drive (Daily Auto-Backup)

A complete and reliable solution to automatically back up your MongoDB database (Local or MongoDB Atlas) on a Linux VPS/Server and upload it daily into organized, date-stamped folders in Google Drive.

---

## 📑 Table of Contents
1. [Features](#-features)
2. [Prerequisites](#-prerequisites)
3. [Step 1: Install Required Tools on VPS](#step-1-install-required-tools-on-vps)
4. [Step 2: Google Cloud Console Configuration](#step-2-google-cloud-console-configuration)
5. [Step 3: Rclone Authorization & Google Drive Connection](#step-3-rclone-authorization--google-drive-connection)
6. [Step 4: Create the Backup Script](#step-4-create-the-backup-script)
7. [Step 5: Setup Scheduled Cron Job](#step-5-setup-scheduled-cron-job)
8. [Drive Folder Structure](#-drive-folder-structure)
9. [Database Restore Guide](#-database-restore-guide)
10. [Troubleshooting](#-troubleshooting)

---

## ✨ Features

* **Date-Based Folders:** Automatically creates date-stamped directories (`YYYY-MM-DD`) on Google Drive.
* **Compressed Archives:** Uses `.gz` format to minimize backup file size and bandwidth.
* **Disk Space Conservation:** Automatically removes local temporary dump files after upload.
* **Auto-Cleanup (Retention Policy):** Automatically removes backups older than 30 days from Google Drive.
* **Fully Automated:** Runs in the background via Linux Cron Job without requiring manual intervention.

---

## 💻 Prerequisites

* **Server:** Ubuntu / Debian Linux VPS (Root or Sudo access)
* **Database:** MongoDB (Local instance or MongoDB Atlas cluster)
* **Storage:** A Google Account (Google Drive)

---

## Step 1: Install Required Tools on VPS

SSH into your VPS server and run the following commands:

### 1. Install Rclone:
```bash
curl [https://rclone.org/install.sh](https://rclone.org/install.sh) | sudo bash

2. Install MongoDB Database Tools (mongodump):

sudo apt update
sudo apt install -y wget curl gnupg
wget [https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb](https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb)
sudo dpkg -i mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb
rm -f mongodb-database-tools-ubuntu2204-x86_64-100.9.4.deb


mongodump --version

Step 2: Google Cloud Console ConfigurationVisit the Google Cloud Console.Click Select a Project > New Project, name it (e.g., RcloneBackup), and click Create.Navigate to APIs & Services > Library, search for Google Drive API, and click Enable.Go to OAuth consent screen:Choose External and click Create.Fill in App Name, User support email, and Developer contact email, then click Save and Continue.Under the Test users tab, click + ADD USERS and enter your Google account email.Go to Credentials > Create Credentials > OAuth client ID:Application type: Select Desktop app (Crucial: Do not select Web application).Enter a name and click Create.Copy and save the generated Client ID and Client Secret.Step 3: Rclone Authorization & Google Drive Connection1. Start Rclone Configuration on VPS:Bashrclone config
Follow the prompts step-by-step:Enter n (New remote)Name: gdriveStorage type: driveclient_id> Paste your Google Client IDclient_secret> Paste your Google Client Secretscope> 1 (Full access)root_folder_id> Press Enter (leave blank)service_account_file> Press Enter (leave blank)Edit advanced config?> nUse auto config?> nThe VPS terminal will display a command formatted like:Plaintextrclone authorize "drive" "eyJjbGllbnRfaWQiOiI..."
2. Generate Auth Token on Local PC:Download and extract Rclone for Windows/macOS.Open CMD/Terminal inside the extracted Rclone folder and run the full rclone authorize ... command provided by your VPS.Your default browser will open. Log into your Google account and click Allow/Continue.Copy the output token starting with eyJ0b2tlbiI... from your local terminal.3. Save Token on VPS:Return to your VPS terminal and paste the copied token at the config_token> prompt.Configure this as a Shared Drive (Team Drive)?> nKeep this "gdrive" remote?> yEnter q to quit the configuration menu.Verify the connection:Bashrclone lsd gdrive:
Step 4: Create the Backup ScriptCreate a directory and the script file:Bashmkdir -p ~/scripts
nano ~/scripts/mongo_backup.sh
Paste the following bash script (replace MONGO_URI with your connection string if needed):Bash#!/bin/bash

# 1. Paths and Date formatting
BACKUP_DIR="/tmp/mongo_backups"
DATE_FOLDER=$(date +%Y-%m-%d)
TIME=$(date +%H-%M-%S)
BACKUP_NAME="backup_$TIME"

# Destination path on Google Drive
RCLONE_REMOTE="gdrive:MongoDB_Backups/$DATE_FOLDER"

# 2. MongoDB URI (Local or MongoDB Atlas)
MONGO_URI="mongodb+srv://akonhasan680_db_user:C4qpIm27ex1rBG8q@cluster0.ocrjeog.mongodb.net/chat-app?appName=Cluster0"

# Create local temporary directory
mkdir -p $BACKUP_DIR

# 3. Generate MongoDB dump archive (.gz compressed format)
mongodump --uri="$MONGO_URI" --archive=$BACKUP_DIR/$BACKUP_NAME.gz --gzip

# 4. Upload to Google Drive
rclone copy $BACKUP_DIR/$BACKUP_NAME.gz $RCLONE_REMOTE

# 5. Clean up local temporary file
rm -f $BACKUP_DIR/$BACKUP_NAME.gz

# 6. Delete backup files and empty folders older than 30 days from Google Drive
rclone delete --min-age 30d "gdrive:MongoDB_Backups"
rclone rmdirs --leave-root "gdrive:MongoDB_Backups"
Save and exit (CTRL + O -> Enter -> CTRL + X).Make the script executable and run a test backup:Bashchmod +x ~/scripts/mongo_backup.sh
~/scripts/mongo_backup.sh
Step 5: Setup Scheduled Cron JobAutomate the script to execute daily at 02:00 AM server time:Open Crontab:Bashcrontab -e
(If prompted to choose an editor, enter 1 for nano)Add this line at the bottom of the file:Bash0 2 * * * /bin/bash /root/scripts/mongo_backup.sh > /dev/null 2>&1
Save and exit (CTRL + O -> Enter -> CTRL + X).Ensure the cron service is active:Bashsystemctl status cron
📂 Drive Folder StructureAfter the backups run, files will be structured inside Google Drive as follows:PlaintextGoogle Drive
└── MongoDB_Backups/
    ├── 2026-08-25/
    │   └── backup_02-00-00.gz
    ├── 2026-08-26/
    │   └── backup_02-00-00.gz
    └── 2026-08-27/
        └── backup_02-00-00.gz
🔄 Database Restore GuideIn the event of data recovery, restore the database from a backup file:1. Download the archive from Google Drive:Bashrclone copy "gdrive:MongoDB_Backups/2026-08-26/backup_02-00-00.gz" /tmp/
2. Restore data into MongoDB:Bashmongorestore --uri="YOUR_MONGODB_URI" --archive=/tmp/backup_02-00-00.gz --gzip --drop
(Note: The --drop flag replaces existing collections with the data from the backup archive)🛠️ TroubleshootingError / IssueCauseResolutionmongodump: command not foundMongoDB Database Tools is not installedDownload the official .deb package via wget and install it with dpkg -i.Error 400: redirect_uri_mismatchApplication Type was set to "Web Application" in Google ConsoleRecreate credentials in Google Console using Desktop app.Error 403: access_deniedGoogle email is not added as a test userAdd your email under the Test users tab in OAuth Consent Screen.Error 403: Google Drive API has not been usedGoogle Drive API is disabledGo to Google Cloud Console and Enable the Google Drive API.Couldn't decode response - invalid character 'e'Mismatched Rclone versions between PC and VPSUpdate Rclone on VPS using curl https://rclone.org/install.sh | sudo bash.
