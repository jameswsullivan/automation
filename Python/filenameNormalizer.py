import os
import sys

if len(sys.argv) != 2:
    print("Usage: python filenameNormalizer.py <folder_path>")
    sys.exit(1)

folder_path = os.path.abspath(sys.argv[1])

if not os.path.isdir(folder_path):
    print(f'Error: "{folder_path}" is not valid folder.')
    sys.exit(1)

for old_filename in os.listdir(folder_path):
    if ' ' in old_filename:
        new_filename = old_filename.replace(' ', '.')
        old_file_fullpath = os.path.join(folder_path, old_filename)
        new_file_fullpath = os.path.join(folder_path, new_filename)
        os.rename(old_file_fullpath, new_file_fullpath)
        print(f'"{old_file_fullpath}" has been renamed to "{new_file_fullpath}".')


