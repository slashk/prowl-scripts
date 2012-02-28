#Prowl Scripts

##What Is Prowl ?

Prowl is "is the Growl client for iOS. Push to your iPhone, iPod touch, or iPad your notifications from a Mac or Windows computer, or from a multitude of apps and services."

It is wonderful.


##What are these ?

This project contains a variety of scripts, mostly written in Ruby or Python, that allows you to send specialized messages to Prowl on your iPhone/iPad/iPad Touch through the Prowl API.


##Scripts

In each of the folders within this repository, you'll find scripts and some meager documentation to automate some trivial notification task.

* transmission: if you use transmission, you know that you can [set a "completed-script" that runs once a bit torrent download has finished](https://trac.transmissionbt.com/wiki/Scripts). I use this script to send myself a prowl with the filename that has completed.

* google-adsense: to keep tabs on my blogging empire, I have this script run out of crontab twice a day. It sends you a prowl with your daily and monthly earnings.

* google_analytics: this runs through your google analytics account and send a prowl with today's visitors and pageviews.

* woot: if you hate to miss a valuable gadget on woot (or wine woot, or sellout woot), you should set this up in crontab to run every fifteen minutes or so. It will prowl you whenever a particular woot site changes
items.

##Configuration

Each of these scripts require, at a minimum, your Prowl API Key in a yaml file located at ~/.prowl.yml

    $ cat ~/.prowl.yml
    prowl_api_key: b57c51d2e51cfd64316153da473f5283db4752fc`

Most of these scripts are designed to be run out of cron on your server throughout the day. 


#Author

<ken.pepple@rabbityard.com>

