#!/usr/bin/env ruby
# created by Ken Pepple on 09-02-2010.

# install these gems with:
#        $ gem install mechanize prowly yaml
# see http://nokogiri.org/tutorials/installing_nokogiri.html if you issues installing mechanize

require 'rubygems'
require 'yaml'
require 'mechanize' 
require 'prowly'

begin
  config = YAML::load(File.open(".prowl.yml"))
rescue
  puts "ERROR: Cannot open .prowl.yml configuration file"
  exit
end

ADSENSE_LOGIN = config["adsense_login"]
ADSENSE_PASS = config["adsense_password"]
PROWL_API_KEY = config["prowl_api_key"]


SERVICE_LOGIN_BOX_URL = "https://www.google.com/accounts/ServiceLoginBox?service=adsense&ltmpl=login&ifr=true&rm=hide&fpui=3&nui=15&alwf=true&passive=true&continue=https%3A%2F%2Fwww.google.com%2Fadsense%2Flogin-box-gaiaauth&followup=https%3A%2F%2Fwww.google.com%2Fadsense%2Flogin-box-gaiaauth&hl=en_US"
TODAY_URL = "https://www.google.com/adsense/report/overview?timePeriod=today"
MONTH_URL = "https://www.google.com/adsense/report/overview?timePeriod=thismonth"

# go get google adsense login page
agent = Mechanize.new
page = agent.get SERVICE_LOGIN_BOX_URL

# fill in login page form with your credentials
form = page.forms.first
form.Email = ADSENSE_LOGIN
form.Passwd = ADSENSE_PASS

# submit login page, then click through the next page to get to account summary
page = agent.submit form
page = agent.get "https://www.google.com/accounts/CheckCookie?continue=https%3A%2F%2Fwww.google.com%2Fadsense%2Flogin-box-gaiaauth&followup=https%3A%2F%2Fwww.google.com%2Fadsense%2Flogin-box-gaiaauth&hl=en_US&service=adsense&ltmpl=login&chtml=LoginDoneHtml" 

# parse account summary page today's for booty
page = agent.get TODAY_URL
todays_booty = page.search("//div[@id='content']//table//h1//span//text()").to_s.match('\$[0-9]+\.[0-9][0-9]').to_s

# parse account summary page for this month's booty
page = agent.get MONTH_URL
months_booty = page.search("//table[@id='summarytable']//tfoot//td/text()").last

# send prowl notification to iphone (log to screen if fails)
notif = Prowly::Notification.new(
  :apikey => PROWL_API_KEY,
  :application => "Google AdSense",
  :event => "Info",
  :priority => Prowly::Notification::Priority::MODERATE,
  :description => "Today's haul is #{todays_booty}\nMonthly haul is #{months_booty}")
response = Prowly.notify(notif)
puts response.message if response.status == "error"