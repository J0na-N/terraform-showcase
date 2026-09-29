#!/bin/bash

cat > index.html <<EOF
<h1>${server-text} :D</h1>
EOF

nohup busybox httpd -f -p ${server_port} &