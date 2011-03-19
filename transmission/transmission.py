#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Send Ken a prowl notification

"""
Send prowl notification on transmission completion
This script requires the yaml and prowlpy libraries
"""

import sys
import os
import prowlpy
import yaml

def usage():
  print "usage: transmission.py"  

def main():
    try:
        f = open('.prowl.yml')
        config = yaml.load(f)
        f.close()
    except:
        print "ERROR: Cannot open .prowl.yml configuration file"
        sys.exit(1)

    # prowl api info
    prowl_key = config["prowl_api_key"]
    prowl_app = 'Transmission'
    prowl_event = 'Download'
    try:
      prowl_description = os.environ['TR_TORRENT_NAME']
    except:
      prowl_description = 'generic event'
    prowl_priority = 0
    p = prowlpy.Prowl(prowl_key)
    try:
        p.add(prowl_app,prowl_event,prowl_description,prowl_priority)
    except Exception,msg:
        print msg


if __name__ == "__main__":
    main()
