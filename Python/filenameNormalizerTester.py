import os
import sys

if len(sys.argv) != 2:
    print("Usage: python filenameNormalizerTester.py <folder_path>")
    sys.exit(1)

folder_path = os.path.abspath(sys.argv[1])

if not os.path.isdir(folder_path):
    print(f'Error: "{folder_path}" is not valid folder.')
    sys.exit(1)

for old_filename in os.listdir(folder_path):
    print(f'{old_filename}')

