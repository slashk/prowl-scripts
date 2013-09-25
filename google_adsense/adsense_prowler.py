#!/usr/bin/python

"""Simple command-line prowl script for Google AdSense"""

import sys
import time

try:
  import yaml
  import gflags
  import httplib2
  from apiclient.discovery import build
  from apiclient.errors import HttpError
  from oauth2client.client import AccessTokenRefreshError
  from oauth2client.client import OAuth2WebServerFlow
  from oauth2client.file import Storage
  from oauth2client.tools import run
  import prowlpy
except:
  print "ERROR: you need to install the necessary python eggs."
  print "$ sudo easy_install pyYAML python-gflags httplib2 \ "
  print "       google-api-python-client prowlpy"
  sys.exit(1)

FLAGS = gflags.FLAGS
gflags.DEFINE_string('prowl_api_key', '.prowl.yml', 'prowl api key file')
gflags.DEFINE_string('adsense_oauth', '.adsense.yml', 'adsense oauth file')
gflags.DEFINE_string('token_file', '.adsense.dat', 'oauth token file')
FLAGS.auth_local_webserver = False

# load adsense oauth credentials
try:
  f = open(FLAGS.adsense_oauth)
  config = yaml.load(f)
  f.close()
except:
  print "ERROR: Cannot open %s configuration file" % FLAGS.adsense_oauth
  sys.exit(1)

FLOW = OAuth2WebServerFlow(
  client_id=config['client_id'],
  client_secret=config['client_secret'],
  scope='https://www.googleapis.com/auth/adsense.readonly',
  user_agent=config['user_agent'])

x = time.localtime()
# remember to make these two digits (i.e. 01 not 1)
today = str(x.tm_year) + "-" + str(x.tm_mon).zfill(2) + "-" + str(x.tm_mday).zfill(2)
first_of_month = str(x.tm_year) + "-" + str(x.tm_mon) + "-" + "01"


def prowl_message(message):
  try:
    f = open(FLAGS.prowl_api_key)
    config = yaml.load(f)
    f.close()
  except:
    print "ERROR: Cannot open %s configuration file" % FLAGS.prowl_api_key
    sys.exit(1)

  # prowl api info
  prowl_key = config["prowl_api_key"]
  prowl_app = 'AdSense'
  prowl_event = 'Info'
  prowl_description = message
  prowl_priority = 0
  p = prowlpy.Prowl(prowl_key)
  try:
    p.add(prowl_app, prowl_event, prowl_description, prowl_priority)
  except Exception, msg:
    print msg


def main(argv):
  try:
    argv = FLAGS(argv)
  except gflags.FlagsError, e:
    print '%s\nUsage: %s ARGS\n%s' % (e, argv[0], FLAGS)
    sys.exit(1)
  # Manage re-using tokens.
  storage = Storage(FLAGS.token_file)
  credentials = storage.get()
  if not credentials or credentials.invalid:
    # Get a new token.
    credentials = run(FLOW, storage)

  # Build an authorized service object.
  http = httplib2.Http()
  http = credentials.authorize(http)
  service = build('adsense', 'v1.2', http=http)

  # Traverse the Management hiearchy and print results.
  try:
    result = service.reports().generate(startDate=first_of_month,
                                        endDate=today,
                                        metric='EARNINGS',
                                        dimension='DATE',
                                        sort='DATE'
                                ).execute()
  except HttpError, error:
    print ('Arg, there was an API error : %s %s : %s' %
            (error.resp.status, error.resp.reason, error._get_reason()))
  except AccessTokenRefreshError:
    print ('The credentials have been revoked or expired, please re-run'
           'the application to re-authorize')

  # form the message and prowl it
  todays_haul = result['rows'].pop()[1]
  monthly_haul = result['totals'][1]
  message = ('Daily haul: $%s\n' % todays_haul)
  message = message + ('Monthly haul: $%s' % monthly_haul)
  prowl_message(message)


if __name__ == '__main__':
  main(sys.argv)
