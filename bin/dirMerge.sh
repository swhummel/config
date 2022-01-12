#! /bin/bash
grep -- -d `/bin/ls -rt findmerge.log.* | tail -1` | sed 's?-merg.*$?-nc -gm?' | bash
