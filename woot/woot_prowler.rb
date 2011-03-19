#!/usr/bin/env ruby
# created by admin AT mtbcalendar D0T com on 09-02-2010.

#### CHANGE THE VARIABLE BELOW
ANNOUNCED_FILE = ".woots" # this can be any WRITEABLE file location
WOOT_SITES = Hash["Wine" => "http://wine.woot.com", 
                  "Main" => "http://www.woot.com", 
                  "Shirt" => "http://shirt.woot.com", 
                  "Sellout" => "http://sellout.woot.com"] # these are the woot! URLs to check.
### DON'T CHANGE ANYTHING BELOW HERE

# install these gems with:
#        $ gem install mechanize prowly yaml
require 'rubygems'
require "mechanize"
require 'prowly'
require 'yaml'

DEBUG = false  # change this for testing -- doesn't prowl just "puts" to screen

begin
  config = YAML::load(File.open(".prowl.yml"))
rescue
  puts "ERROR: Cannot open .prowl.yml configuration file"
  exit
end

class Woot
  attr_accessor :site, :price, :item, :status, :url, :last_update_time

  def initialize(site, price, item, status, url)
      @site = site
      @price = price
      @item = item
      @status = status
      @url = url
      @last_update_time = Time.now
  end
  
  def to_s
    "#{item} (#{price}) at #{url}"
  end    
end

new_woots = Array.new
woot_thread = Hash.new

def prowlify(woot)
  puts "received woot: #{woot.to_s}"  if DEBUG
  # send prowl notification to iphone (log to screen if fails)
  unless DEBUG
    notif = Prowly::Notification.new(
      :apikey => PROWL_API_KEY,
      :application => "#{woot.site} Woot!",
      :event => "Info",
      :priority => Prowly::Notification::Priority::MODERATE,
      :description => woot.to_s)
    response = Prowly.notify(notif)
    puts response.message if response.status == "error"
  else
    puts "cannot woot: #{woot.to_s}" if DEBUG
  end
end

def soldout?(woot)
  woot.status.eql?("SOLD OUT")
end

def already_announced?(woot, old_woot_items)
  old_woot_items.include?(woot.item)
end

def isthisawootoff?(text)
  text.split(":")[0].match("%")
end

#BEGIN MAIN

# load announced file
begin 
  old_woots = YAML.load_file( ANNOUNCED_FILE )
  old_woot_items = old_woots.map {|m| m.item } 
rescue
  old_woots = nil
  old_woot_items = []
end
puts YAML.dump(old_woots) if DEBUG

# main loop to check urls then prowl results if new && not sold out
WOOT_SITES.keys.each do |site|
  woot_thread[site] = Thread.new(site) do |s|
    # get current woots via microsummary page
    agent = Mechanize.new
    begin
      page = agent.get WOOT_SITES[s] + "/DefaultMicrosummary.ashx"
      if isthisawootoff?(page.body)
        (status, price, item) = page.body.split(":") 
      else 
        (price, item, status) = page.body.split(":")
      end
      # create new woot with results
      status.strip! unless status.nil?
      x = Woot.new(site, price.strip, item.strip, status, WOOT_SITES[site])
      # compare woot to last check
      unless soldout?(x) || already_announced?(x, old_woot_items)
        prowlify(x)
      end
      new_woots << x
    rescue
      puts "ERROR: #{s} is unavailable."
    rescue Timeout::Error => e
      puts "ERROR: #{s} is timed out."
    end
  end
end

# since each of the checks are their own thread, 
# we need to join to wait for them to finish
woot_thread.keys.each {|t| woot_thread[t].join}
puts YAML.dump(new_woots) if DEBUG

# dump new_woots to announced file
begin
  File.open( ANNOUNCED_FILE, 'w' ) do |out|
      YAML.dump( new_woots, out )
  end
rescue
  puts "ERROR: Cannot write to ANNOUNCED_FILE ! Please configure the script to write to a writeable file location."
end