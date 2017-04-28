#!/usr/bin/env python

import logging
import yaml
import signal
from argparse import ArgumentParser

from magi.orchestrator.parse import *
from magi.messaging import api

# quiet the magi logging.
logging.getLogger('magi').setLevel(logging.CRITICAL)

done = False
messaging = None

def handler(signum, frame):
    global done
    print "shutting down ..."
    done = True
    messaging.poisinPill()

if __name__ == '__main__':
    ap = ArgumentParser()
    ap.add_argument("-c", "--control", dest="control", 
                    help="The control node to connect to (i.e. control.exp.proj)")
    ap.add_argument("-p", "--port", dest="port", type=int, 
                    help="The control port to connect to (default: 18808)", default=18808)
    ap.add_argument("-g", "--group", action='append', dest="group", help="A group to listen to. May be repeated.")
    args = ap.parse_args()

    signal.signal(signal.SIGINT, handler)
    messaging = api.ClientConnection("pypassive", args.control, args.port)

    # We probably don't want to see all methods called in the group, esp. bookkeeping ones.
    ignore_methods = ['loadAgent', 'groupPing']

    for g in args.group:
        messaging.join(g)

    while not done:
        # without at least some timeout main thread stops receiving signals
        message = messaging.nextMessage(True, sys.maxint)  

        # are any of our groups in the dstgroups?
        msggroups = ','.join([e for e in args.group if e in message.dstgroups])
        if not msggroups:
            continue

        msgdata = getattr(message, 'data', None)
        if not msgdata:
            continue

        data = yaml.safe_load(msgdata)
        if 'method' in data:
            method = data['method']
            if method in ignore_methods:
                continue 

            trigger = data['trigger'] if 'trigger' in data else ''
            methodargs = ''
            if 'args' in data:
                methodargs += ','.join(['{}:{}'.format(k, v) for k, v in data['args'].iteritems()])

            print('{}|{}|{}|{}'.format(msggroups, method, methodargs, trigger))
