#!/bin/bash

# Setup temp files for use
IFS='%'
tfile1=$(mktemp /tmp/newCalXXXXXX)
tfile2=$(mktemp /tmp/newCalXXXXXX)
tfile3=$(mktemp /tmp/newCalXXXXXX)
to='cdracars@usao.edu, rvollmar@usao.edu, jjackson@usao.edu, karnold@usao.edu, kchambers@usao.edu'
#to='cdracars@usao.edu'
db='drupal'

# Select new calendar entries from database
calItems=$(mysql ${db} -t -e "SELECT node.title, node.nid FROM node node WHERE (DATE_FORMAT(ADDTIME(FROM_UNIXTIME(node.created), SEC_TO_TIME(-18000)), '%Y-%m-%d') > DATE_SUB(CURDATE(), INTERVAL 7 DAY)) AND (node.type in ('event')) ORDER BY node.created")

if [ -n "$calItems" ]; then
  echo ${calItems} > ${tfile1}
fi

# filter out any tables we don't really care about
cat ${tfile1} | grep [0-9] | sed -e 's/^|.//' \
                  -e 's/|.\([0-9]\)/http:\/\/usao\.edu\/node\/\1/' \
                                    -e 's/\([0-9]\).|/\1\/edit/' > ${tfile2}


# Generate a 'summary' of tables and rowcount
cat ${tfile2} | awk -F="http" 'BEGIN { print "<h2>Summary</h2><table border=1>" }
                {print "<tr><td>" $1 $2 "</td></tr>"}
                                END { print "</table>" }' > ${tfile3}

# Send an email to Cody with the summary body and details attached.
# the -n checks to see if there is anything in the variable and only sends out non empty messages.
if [ -n "$calItems" ]; then
cat <<EOF | mutt -e "set content_type=text/html" -s "Weekly New Calendar Items (New - D7)" ${to}
<html>
<p>Good Morning Media Team!

<p>Here is your weekly list of new calendar items.

<p>$(cat ${tfile3})
</html>
EOF
fi

rm -f ${tfile1}
rm -f ${tfile2}
rm -f ${tfile3}
unset IFS
