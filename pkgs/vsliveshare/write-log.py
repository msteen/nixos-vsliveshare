# -*- coding: utf-8 -*-
import socket
import sys

DEV_LOG = '/dev/log'
VSLS_AGENT_LOG = '/run/vsls-agent-log'

client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
client.connect(DEV_LOG)
client.send(sys.argv[1] if len(sys.argv) > 1 else "Hello World!")
client.close()
