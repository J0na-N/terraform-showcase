#!/bin/bash

cat > index.html <<EOF
<h1>${server-text} :D</h1>
<p>Single EC2 Instance Web Server</p>
EOF

nohup busybox httpd -f -p ${server_port} &