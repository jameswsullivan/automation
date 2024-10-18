# scp
scp -r <source> <destination>
scp -r <username@server>:<source file path> <username@server>:<destination file path>

# ln
ln -s target_file symbolic_link

# ls
ls -alh
ls -A1

# awk
ls -A1 | awk '{print "scp " $0 " user@server:/remote/directory/"}'
ls -A1 | awk '{print "scp -r user@server:/remote/directory/" $0 "/*" " /destination/directory/" $0} END {print ""}' | tee /output-file.txt
ls -A1 | awk '{print "cp -a /source/directory/" $0 " /destination/directory/"} END {print ""}' | tee /output-file.txt
ls -A1 | awk '{print "du -sh " $0}'

# df
df -h --output=source,size,used,avail,pcent

# find :
find / -name <STUFF_TO_FIND>

# history :
history -c && history -w
