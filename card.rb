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
      cost: 'div#ctl00_ctl00_ctl00_MainContent_SubContent_SubContent_manaRow div.value',
      converted_cost: 'div#ctl00_ctl00_ctl00_MainContent_SubContent_SubContent_cmcRow div.value',
      type: 'div#ctl00_ctl00_ctl00_MainContent_SubContent_SubContent_typeRow div.value'
    }
  end
  
  class Card
    include WebConstants
    attr_accessor :id, :name, :expansion, :rarity, :sets, :number, :artist, :rating
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
      @data = mech.get @@url[:data].call(@id)
    end
    
    def cost
      img_tags = @data.search @@selector[:cost]
      parse_cost_from img_tags
    end
    
    def converted_cost
      cost = text_from_element :converted_cost
      cost.to_i
    end
    
    def type
      text_from_element :type
    end
  
    def text(flavour=false)
      flavour ? flavour_text : text
    end
    
    def text_from_element(selector_symbol)
      element = @data.search @@selector[selector_symbol]
      element.text.strip
    end
  
    def parse_cost_from(node_set)
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
