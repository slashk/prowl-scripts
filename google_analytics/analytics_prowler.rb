#!/usr/bin/env ruby

# To configure, create a .prowl.yml file that looks like this:
#
# prowl_api_key: b57500d2f56cfd63316153da47355283db4752ff
# analytics_login: my.email@gmail.com
# analytics_password: yourpassword
# web_properties: ['UA-sample-1', 'UA-sample-2', 'UA-sample-3']
# 
# you can find your web property ids on your google analytics dashboard
#

require "rubygems"
require "garb"
require "prowly"

class Pageviews
  extend Garb::Model

  metrics :pageviews, :visitors
end

class Domis
  extend Garb::Model
  
  metrics :pageviews
  dimensions :networkDomain
end

begin
  config = YAML::load(File.open(".prowl.yml"))
rescue
  puts "ERROR: Cannot open .prowl.yml configuration file"
  exit
end

message = ""
session = Garb::Session.login(config["analytics_login"], config["analytics_password"])

config["web_properties"].each do |property_id|
  profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == property_id}
  views = Pageviews.results(profile, :start_date => Date.today, :end_date => Date.today)
  begin
    message << "#{profile.title}: #{views.first.visitors}/#{views.first.pageviews} from "
  rescue
  end
  isps = Domis.results(profile, :start_date => Date.today, :end_date => Date.today)
  tr = isps.sort_by {|x| x.pageviews}.reverse
  top_referrers = tr[0..2].map {|z| "#{z.network_domain} (#{z.pageviews})" unless z.nil?} 
  message << top_referrers.join(', ') + "\n"
end

notif = Prowly::Notification.new(
  :apikey => config["prowl_api_key"],
  :application => "google analytics",
  :event => "Info",
  :priority => Prowly::Notification::Priority::MODERATE,
  :description => message)
response = Prowly.notify(notif)
