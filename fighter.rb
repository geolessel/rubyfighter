#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'yaml'
require 'fileutils'

STDOUT.sync = true

module FighterVerses
  class Plan
    SAVE_DIRECTORY = File.expand_path("~/.fv")
    SAVE_FILENAME  = "verses.yml"

    attr_accessor :verses, :start_date

    def initialize
      @verses = Array.new
      time = Time.now
      @start_date = Time.mktime(time.year, time.month, time.day)
    end

    def download_plan
      print "Opening reading plan from 'http://www.fighterverses.com/the-verses/fighter-verses/'... "
      p = Hpricot(open("http://www.fighterverses.com/the-verses/fighter-verses/"))
      print "done.\nParsing verse references "
      p.search("//tr").each do |r|
        verse = FighterVerses::Verse.new
        verse.set = r.search("//td[@class='column-1']").text
        verse.set_order = r.search("//td[@class='column-2']").text
        verse.reference = r.search("//td[@class='column-3']").text
        verse.category = r.search("//td[@class='column-4']").text
        verse.bible_order = r.search("//td[@class='column-5']").text
        @verses << verse unless verse.set.empty?
        print "."
      end
      print " done.\n"
    end

    def download_verses
      @verses.each_with_index do |v,i|
        print "(#{i+1}/#{@verses.size}) "
        v.download_verse_text
        sleep(2)
      end
    end

    def current_verse
      week_number = ((Time.now - @start_date) / 24 / 60 / 60).to_i / 7
      return "\"#{@verses[week_number].text}\" [#{@verses[week_number].reference}]".gsub(/(.{1,78})(\s+|\Z)/, "\\1\n")
    end

    def save
      print "Saving verse data to #{File.join(SAVE_DIRECTORY, SAVE_FILENAME)}... "
      data = Hash.new
      FileUtils.mkdir_p(SAVE_DIRECTORY)
      File.open(File.join(SAVE_DIRECTORY, SAVE_FILENAME), 'w') do |f|
        data["verses"] = @verses
        data["start_date"] = @start_date
        YAML.dump(data, f)
      end
      print "done.\n"
    end

    def load
      path = File.join(SAVE_DIRECTORY, SAVE_FILENAME)
      if File.exists?(path)
        data = YAML::load_file(path)
        @verses = data["verses"]
        @start_date = data["start_date"]
      else
        raise "verses.yml file does not exist. Please either copy the included\nverses.yml file to ~/.fv/verses.yml or use fighter.rb --setup"
      end
    end
  end

  class Verse
    attr_accessor :set, :set_order, :reference, :category, :bible_order, :text

    def download_verse_text
      print "Downloading verse text for #{@reference}... "
      bible = EsvBible.new("IP")
      url = "http://www.esvapi.org/v2/rest/passageQuery?key=IP&include-passage-references=0&output-format=plain-text&include-verse-numbers=0&include-footnotes=0&include-headings=0&include-subheadings=0&include-short-copyright=0&include-first-verse-numbers=0"
      url += "&passage=#{@reference.gsub(/\s/, '+').gsub(/\[(\d+)\]/, ",#{$1}")}"
      doc = open(url).read
      # doc = Hpricot(bible.verse @reference, {:output_format => :plain_text, :include_headings => false, 
      #         :include_passage_references => false, :include_first_verse_numbers => false, :include_subheadings => false,
      #         :include_short_copyright => false, :include_verse_numbers => false, :include_footnotes => false})

      @text = doc.gsub(/=/,'').gsub(/\n/,' ').gsub(/\s{1,}/,' ').gsub(/_/,'').strip.chomp
      #@text = doc.search('//text()').text.chomp.strip.gsub(/\n/, '')
      print "done.\n"
    end
  end
end

def print_options
  puts "--setstartdate  Set the starting date of the plan"
  puts "--settings      Print current variable settings"
  puts "--setup         Set up verse data"
end

if option = ARGV[0]
  case option
  when "--setup"
    puts "Setting up verse data"
    plan = FighterVerses::Plan.new
    plan.download_plan
    plan.download_verses
    plan.save
  when "--setstartdate"
    case ARGV[1]
    when /(\d\d\d\d)-(\d\d)-(\d\d)/
      puts "Setting start date"
      year, month, day = $1, $2, $3
      plan = FighterVerses::Plan.new
      plan.load
      plan.start_date = Time.mktime(year, month, day)
      plan.save
    else
      puts "Need date format in YYYY-MM-DD"
    end
  when "--settings"
    plan = FighterVerses::Plan.new
    plan.load
    puts "Start Date: #{plan.start_date.to_s}"
    puts "Verses: #{plan.verses.count}"
  when "--help"
    print_options
  else
    plan = FighterVerses::Plan.new
    plan.load
    puts plan.current_verse
  end
else 
  plan = FighterVerses::Plan.new
  plan.load
  puts plan.current_verse
end
