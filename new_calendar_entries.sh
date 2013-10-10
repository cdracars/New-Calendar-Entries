#!/bin/bash

# Setup temp files for use
tfile1=$(mktemp /tmp/newCalXXXXXX)
tfile2=$(mktemp /tmp/newCalXXXXXX)
tfile3=$(mktemp /tmp/newCalXXXXXX)
to='cdracars@usao.edu, rvollmar@usao.edu'
db='usaoedu'

# Select new calendar entries from database
mysql usaoedu -t -e "SELECT node.title, node.nid FROM node node WHERE (DATE_FORMAT(ADDTIME(FROM_UNIXTIME(node.created), SEC_TO_TIME(-18000)), '%Y-%m-%d') > DATE_SUB(CURDATE(), INTERVAL 7 DAY)) AND (node.type in ('calendar_item')) ORDER BY node.created" > $tfile1

# remove uneeded rows and rewrite the node id into a link to the node edit form
cat $tfile1 | grep [0-9] | sed -e 's/^|.//' \
                  -e 's/|.\([0-9]\)/http:\/\/usao\.edu\/node\/\1/' \
                  -e 's/\([0-9]\).|/\1\/edit/' > $tfile2


# Generate a 'summary' of the new entries by placing them in a easy to read table
cat $tfile2 | awk -F="http" 'BEGIN { print "<h2>Summary</h2><table border=1>" } 
                {print "<tr><td>" $1 $2 "</td></tr>"} 
                END { print "</table>" }' > $tfile3

# Send an email to Cody with the summary.
cat <<EOF | mutt -e "set content_type=text/html" -s "Weekly New Calendar Items (Legacy - D6)" $to
<html>
<p>Good Morning Rob!

<p>Here is your weekly list of new calendar items.

<p>$(cat $tfile3)
</html>
EOF

# Clean up
rm -f $tfile1
rm -f $tfile2
rm -f $tfile3
