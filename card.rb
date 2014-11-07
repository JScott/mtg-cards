#!/usr/bin/ruby

require 'mechanize'
require 'json'

module MTG
  module WebConstants
    @@url = {
      base: 'http://gatherer.wizards.com',
      image: lambda { |id| "#{@@url[:base]}/Handlers/Image.ashx?multiverseid=#{id}&type=card" },
      data: lambda { |id| "#{@@url[:base]}/Pages/Card/Details.aspx?multiverseid=#{id}" },
      search: lambda { |query| "#{@@url[:base]}/Handlers/InlineCardSearch.ashx?nameFragment=#{query}" }
    }

    @@selector = {
      cost: 'div#ctl00_ctl00_ctl00_MainContent_SubContent_SubContent_manaRow div.value'
    }
  end
  
  class Card
    include WebConstants
    attr_accessor :id, :name, :cost, :converted_cost, :type, :expansion, :rarity, :sets, :number, :artist, :rating
    attr_writer :text, :flavour_text

    def initialize(id, name)
      @id = id
      @name = name
      fetch_data
    end
  
    def image_url
      @@url[:image].call @id
    end
  
    def fetch_data
      mech = Mechanize.new
      mech.get @@url[:data].call(@id) do |page|
        @cost = parse_cost page.search(@@selector[:cost])
      end
    end
  
    def text(flavour=false)
      flavour ? @flavour_text : @text
    end
  
    def parse_cost(node_set)
      cost = {}
      node_set.search('img').each do |tag|
        value = tag.attribute('alt').text
        if value.to_i != 0
          cost["Colourless"] = value
        else
          cost[value.to_sym] ||= 0
          cost[value.to_sym] += 1
        end
      end
      return cost
    end
    
    def self.search(query_string)
      mech = Mechanize.new
      cards = []
      mech.get @@url[:search].call(query_string) do |page|
        search_results = JSON.parse(page.content)["Results"]
        search_results.each do |result|
          card = Card.new result["ID"], result["Name"]
          cards.push card
        end
      end
      return cards
    end
  end
end
