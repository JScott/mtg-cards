#!/usr/bin/ruby

require 'pp'
require_relative 'card'

cards = MTG::Card.search ARGV[0]
cards.each do |card|
  puts card
  puts card.image_url
  puts card.cost
  puts card.converted_cost
  puts card.type
end
