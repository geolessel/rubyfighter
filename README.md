RubyFighter
===========

## DESCRIPTION

RubyFighter is a simple utility designed to output the text of the current
week's Bible memory verse. The method of memorization is based on Desiring
God Ministry's Fighter Verses system.

Currently, the links to download the plan and also the text of the verses
themselves (in ESV) are hard-coded into the code.


## INSTALLATION

RubyFighter depends on the following gem:

  1. Hpricot

To initialize the verse database, you can either copy the included
verses.yml file into your ~/.fv directory or start up RubyFighter with the
following option:

    $ ruby fighter.rb --setup

## RUNNING


To print the current week's verse, simply run the executable:

    $ ruby fighter.rb

To get more information regarding usage, type:
    
    $ ruby fighter.rb --help


## USAGE

Run RubyFighter during your shell startup script to print today's verse
before you get started on your day's work.
