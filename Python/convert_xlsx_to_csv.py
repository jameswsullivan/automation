# This script converts all the .xlsx files in the originalFolder into .csv files
# and place the converted files into the destFolder.

import os
import pandas
import csv

cwd = os.getcwd()

originalFolder = "Original"
destFolder = "Formatted"
logFilename = "convert.log"
logFile = open(logFilename, 'a+', newline='', encoding='utf-8')

for filename in os.listdir(originalFolder):
    originalFilename = "./" + originalFolder + "/" + filename
    readFile = pandas.read_excel(originalFilename)
    filenameCSV = filename.replace(".xlsx",".csv")
    readFile.to_csv(filenameCSV, index = None, header=True)

    with open(filenameCSV, 'r', newline='', encoding='utf-8') as infile, open('out.csv', 'w', newline='', encoding='utf-8') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile, delimiter=',', quoting=csv.QUOTE_ALL)
        writer.writerows(reader)

    firstLine = "replace_this_line_with_your_csv_header\n"

    with open('out.csv', 'r', newline='', encoding='utf-8') as infile, open('out1.csv', 'w', newline='', encoding='utf-8') as outfile:
        writer = csv.writer(outfile, delimiter=',', quoting=csv.QUOTE_ALL)
        for row in csv.reader(infile):
            writer.writerow(row[:-2])

    destinationFilename = "./" + destFolder + "/" + filenameCSV
    with open('out1.csv', 'r', newline='', encoding='utf-8') as infile, open(destinationFilename, 'w', newline='', encoding='utf-8') as outfile:
        data = infile.readlines()
        data[0] = firstLine
        outfile.writelines(data)

    os.remove(filenameCSV)
    os.remove("out.csv")
    os.remove("out1.csv")

    logMessage = filename + " converted.\n"
    logFile.write(logMessage)

logFile.close()