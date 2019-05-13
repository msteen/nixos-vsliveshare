# -*- coding: utf-8 -*-
# Based on: http://www.velvetcache.org/2010/06/14/python-unix-sockets

from __future__ import print_function
import atexit
import os
import re
import socket
import subprocess
import sys

DEV_LOG = '/dev/log'
SYSTEMD_JOURNAL_LOG = '/run/systemd/journal/dev-log'
VSLS_AGENT_LOG = '/run/vsls-agent-log'

def print_err(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

if not os.path.exists(SYSTEMD_JOURNAL_LOG):
    print_err("systemd journal log UNIX socket '{}' does not exist".format(SYSTEMD_JOURNAL_LOG))
    exit(1)

if not os.path.islink(DEV_LOG) or os.readlink(DEV_LOG) != SYSTEMD_JOURNAL_LOG:
    print_err("path '{}' is not a symlink to path '{}'".format(DEV_LOG, SYSTEMD_JOURNAL_LOG))
    exit(1)

if os.path.exists(VSLS_AGENT_LOG):
    print("removing existing path '{}'...".format(VSLS_AGENT_LOG))
    os.remove(VSLS_AGENT_LOG)

print("binding VSLS Agent log UNIX socket to path '{}'...".format(VSLS_AGENT_LOG))
vsls_agent_log = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
vsls_agent_log.bind(VSLS_AGENT_LOG)
os.chmod(VSLS_AGENT_LOG, 0o666)

@atexit.register
def close_vsls_agent_log():
    print("closing VSLS Agent log UNIX socket...")
    vsls_agent_log.close()
    print("unbinding VSLS Agent log UNIX socket from path '{}'...".format(VSLS_AGENT_LOG))
    os.remove(VSLS_AGENT_LOG)

print("moving the symlink for path '{}' to '{}'...".format(DEV_LOG, VSLS_AGENT_LOG))
os.unlink(DEV_LOG)
os.symlink(VSLS_AGENT_LOG, DEV_LOG)

@atexit.register
def restore_symlink_dev_log():
    print("restoring the symlink for path '{}' back to '{}'...".format(DEV_LOG, SYSTEMD_JOURNAL_LOG))
    os.unlink(DEV_LOG)
    os.symlink(SYSTEMD_JOURNAL_LOG, DEV_LOG)

print("connecting to systemd journal log UNIX socket...")
systemd_journal_log = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
systemd_journal_log.connect(SYSTEMD_JOURNAL_LOG)

@atexit.register
def close_dev_log():
    print("closing systemd journal log UNIX socket...")
    systemd_journal_log.close()

# <15>Nov 14 18:41:09 vsls-agent-wrapped: Agent.Rpc.Auth Verbose: 0 :
from_vsls_agent_pat = re.compile('<[0-9]+>[a-zA-Z]+ [0-9]{1,2} [0-9]{1,2}:[0-9]{2}:[0-9]{2} vsls-agent-wrapped:.*')

print("listening to VSLS Agent log UNIX socket...")
try:
    while True:
        line = vsls_agent_log.recv(4096)
        if not from_vsls_agent_pat.match(line):
            systemd_journal_log.send(line)
except KeyboardInterrupt:
    pass
