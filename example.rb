#!/usr/bin/ruby

require 'pp'
require_relative 'card'

cards = MTG::Card.search ARGV[0]
cards.each do |card|
  pp card
  puts card.image_url
end
