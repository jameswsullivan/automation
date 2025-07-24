# Run this script in this format: python script_name.py <COLLECTION_ID>
# e.g. python fetch-avalon-assets-by-collection-via-ssh.py abcd1234

# Retrieve items from a collection using cURL:
# curl -H "Avalon-Api-Key:<API_KEY>" "https://<AVALON_URL>/admin/collections/<COLLECTION_ID>/items.json"

import paramiko
import ffmpeg
import requests
import sys
import json
import csv
import os

# BEGIN - Script Setup:
# Install python libraries as needed:
# pip install ffmpeg-python
# pip install requests
# pip install paramiko

# Provide your Avalon API KEY:
AVALON_API_KEY = r''

# Provide your avalon host URL: e.g. AVALON_HOST_URL = r'https://myavalon.com'
AVALON_HOST_URL = r''

# Provide your SSH credentials and connection info:
SSH_HOSTNAME = ''
SSH_PORT = 22
SSH_USERNAME = ''
SSH_PASSWORD = ''

# Provide your Avalon asset mount location on the server:
AVALON_MOUNT_PATH = ''

# END - Script Setup.
# -------------------

# Define functions:
def DownloadViaSSH(localPath, remotePath):
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(SSH_HOSTNAME, username=SSH_USERNAME, password=SSH_PASSWORD)

        sftp = ssh.open_sftp()
        sftp.get(remotePath, localPath)
        sftp.close()
        ssh.close()

# Declare variables:
HEADERS = {
    "Avalon-Api-Key":f"{AVALON_API_KEY}"
}
COLLECTION_ID = ""
COLLECTION_ITEMS_URL = ""
COLLECTION_ITEMS_RESPONSE = ""
COLLECTION_ITEMS_JSON_FILEPATH = ""

collectionItems = ""

# Pass Collection ID as an arg to the script:
if __name__ == "__main__":
    if len(sys.argv) > 1:
        COLLECTION_ID = sys.argv[1]


# BEGIN - fetch collection items from API:

# Create a folder named as the Collection ID:
print(f"Collection ID: {COLLECTION_ID}")
os.makedirs(COLLECTION_ID, exist_ok=True)

COLLECTION_ITEMS_JSON_FILEPATH = os.path.join(COLLECTION_ID, f"collection-{COLLECTION_ID}.json")
COLLECTION_ITEMS_URL = f"{AVALON_HOST_URL}/admin/collections/{COLLECTION_ID}/items.json"

print(f"Collection Items API URL: {COLLECTION_ITEMS_URL}")
print(f"Caling API to fetch items info, please wait ...")

COLLECTION_ITEMS_RESPONSE = requests.get(f"{COLLECTION_ITEMS_URL}", headers=HEADERS)
collectionItems = COLLECTION_ITEMS_RESPONSE.json()

print(f"Completed fetching items API call.")
print(f"Writing items JSON to {COLLECTION_ITEMS_JSON_FILEPATH}")

with open(f"{COLLECTION_ITEMS_JSON_FILEPATH}", "w") as collectionItemsJsonFile:
    json.dump(collectionItems, collectionItemsJsonFile, ensure_ascii=False, indent=2)

print(f"Items JSON written to {COLLECTION_ITEMS_JSON_FILEPATH}\n")
# END - fetch collection items from API.


# BEGIN - download video files:

# Create CSV file:
CSV_FILEPATH = os.path.join(COLLECTION_ID, f"items-{COLLECTION_ID}.csv")

CSV_HEADERS = [
    'collection_id', 'object_id', 'object_title',
    'file_id', 'file_uid', 'file_quality', 'hls_url',
    'derivativeFile'
    ]

with open(f"{CSV_FILEPATH}", mode='a', newline='') as csvFile:
    csvWriter = csv.DictWriter(csvFile, fieldnames=CSV_HEADERS)

    if csvFile.tell() == 0:
        csvWriter.writeheader()

print(f"\"{CSV_FILEPATH}\" created.")

# Get medium or high quality files:
selectedQuality = None

for objectId, objectInfo in collectionItems.items():

    print(f"object_id: ")
    objectTitle = objectInfo["title"]
    fileId = objectInfo["files"][0]["id"]

    if objectInfo["files"][0]["files"]:
        selectedQuality = objectInfo["files"][0]["files"][0]
    else:
        selectedQuality = None
    
    if (selectedQuality is not None) and (selectedQuality.get("label") != "quality-medium"):
        for fileItem in objectInfo["files"][0]["files"]:
            fileItemLabel = fileItem.get("label")
            if fileItemLabel == "quality-medium":
                selectedQuality = fileItem
                break

    selectedQualityLabel = selectedQuality.get("label")

    # Retrieve medium quality files:
    if selectedQuality is not None:
        print(f"Downloading \"{objectTitle}\" in \"{selectedQualityLabel}\" quality ...")

        file_uid = selectedQuality['id']
        file_url = selectedQuality['url']
        hls_url = selectedQuality['hls_url']
        derivativeFile = selectedQuality['derivativeFile']

        if selectedQualityLabel == "quality-medium":
            mediaQualitySuffix = "-medium"
        elif selectedQualityLabel == "quality-high":
            mediaQualitySuffix = "-high"
        else:
            mediaQualitySuffix = "-other"

        (mediaFileName, mediaFileExtension) = os.path.splitext(derivativeFile)

        outputFilepath = objectTitle + mediaQualitySuffix + mediaFileExtension
        outputFilepath = os.path.join(COLLECTION_ID, outputFilepath)

        objectRow = {'collection_id': COLLECTION_ID, 'object_id': objectId,
                     'object_title': objectTitle, 'file_id': fileId, 'file_uid': file_uid,
                     'file_quality': selectedQualityLabel, 'hls_url': hls_url,
                     'derivativeFile': derivativeFile}
        
        with open(f"{CSV_FILEPATH}", mode='a', newline='') as csvFile:
            csvWriter = csv.DictWriter(csvFile, fieldnames=CSV_HEADERS)

            if csvFile.tell() == 0:
                csvWriter.writeheader()
            
            csvWriter.writerow(objectRow)
        
        derivativeFileName = os.path.basename(derivativeFile)
        sshLocalFilePath = COLLECTION_ID + "/" + derivativeFileName
        sshRemoteFileFullPath = AVALON_MOUNT_PATH + "/masterfiles/" + file_url + mediaFileExtension

        DownloadViaSSH(sshLocalFilePath, sshRemoteFileFullPath)

        print(f"Finished downloading \"{objectTitle}\" in \"{selectedQualityLabel}\" quality.")

    else:
        print(f"No quality found.")

# END - download video files.

