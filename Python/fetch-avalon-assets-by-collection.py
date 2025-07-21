# Install python libraries as needed:
# pip install ffmpeg-python
# pip install requests

import ffmpeg
import requests
import sys
import json
import csv
import os

# cURL equivalent:
# curl -H "Avalon-Api-Key:<API_KEY>" "https://<AVALON_URL>/admin/collections/<COLLECTION_ID>/items.json"

# Add your API KEY:
AVALON_API_KEY = r''

# Add your avalon host URL: e.g. AVALON_HOST_URL = r'https://myavalon.com'
AVALON_HOST_URL = r''

HEADERS = {
    "Avalon-Api-Key":f"{AVALON_API_KEY}"
}

# Declare variables:
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
fileItemQualityMedium = None
fileItemQualityHigh = None

for objectId, objectInfo in collectionItems.items():
    print(f"object_id: {objectId}")
    objectTitle = objectInfo["title"]
    fileId = objectInfo["files"][0]["id"]

    for fileItem in objectInfo["files"][0]["files"]:
        fileItemLabel = fileItem.get("label")
        if fileItemLabel == "quality-medium":
            fileItemQualityMedium = fileItem
        elif fileItemLabel == "quality-high":
            fileItemQualityHigh = fileItem

    # Retrieve medium quality files:
    if fileItemQualityMedium is not None:
        print("Downloading medium quality media files, please wait ...")

        file_uid = fileItemQualityMedium['id']
        hls_url = fileItemQualityMedium['hls_url']
        derivativeFile = fileItemQualityMedium['derivativeFile']

        (mediaFileName, mediaFileExtension) = os.path.splitext(derivativeFile)
        mediumQualityOutputFilepath = objectTitle + "-medium" + mediaFileExtension
        mediumQualityOutputFilepath = os.path.join(COLLECTION_ID, mediumQualityOutputFilepath)

        objectRow = {'collection_id': COLLECTION_ID, 'object_id': objectId,
                     'object_title': objectTitle, 'file_id': fileId, 'file_uid': file_uid,
                     'file_quality': 'quality-medium', 'hls_url': hls_url,
                     'derivativeFile': derivativeFile}
        
        with open(f"{CSV_FILEPATH}", mode='a', newline='') as csvFile:
            csvWriter = csv.DictWriter(csvFile, fieldnames=CSV_HEADERS)

            if csvFile.tell() == 0:
                csvWriter.writeheader()
            
            csvWriter.writerow(objectRow)

        ffmpeg.input(hls_url).output(mediumQualityOutputFilepath).run()

        print("Finished downloading medium quality media files.")

    # Retireve high quality files:
    elif fileItemQualityMedium is None:
        print("Downloading high quality media files, please wait ...")

        file_uid = fileItemQualityHigh['id']
        hls_url = fileItemQualityHigh['hls_url']
        derivativeFile = fileItemQualityHigh['derivativeFile']

        (mediaFileName, mediaFileExtension) = os.path.splitext(derivativeFile)
        highQualityOutputFilepath = objectTitle + "-high" + mediaFileExtension
        highQualityOutputFilepath = os.path.join(COLLECTION_ID, highQualityOutputFilepath)

        objectRow = {'collection_id': COLLECTION_ID, 'object_id': objectId,
                     'object_title': objectTitle, 'file_id': fileId, 'file_uid': file_uid,
                     'file_quality': 'quality-medium', 'hls_url': hls_url,
                     'derivativeFile': derivativeFile}
        
        with open(f"{CSV_FILEPATH}", mode='a', newline='') as csvFile:
            csvWriter = csv.DictWriter(csvFile, fieldnames=CSV_HEADERS)

            if csvFile.tell() == 0:
                csvWriter.writeheader()
            
            csvWriter.writerow(objectRow)

        ffmpeg.input(hls_url).output(highQualityOutputFilepath).run()

        print("Finished downloading high quality media files.")

    else:
        print(f"No quality found.")

# END - download video files.

