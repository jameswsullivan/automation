logFileName = "YOUR_LOG_FILE_NAME"

with open(logFileName, "r") as inputFile:
    lines = inputFile.readlines()

with open("open_oni_load_batch_errors.log", "w") as outputFile:
   for line in lines:
      if line.strip("\n").startswith("[INFO]") or line.strip("\n").startswith("[WARNING]"):
        continue
      else:
        outputFile.write(line)