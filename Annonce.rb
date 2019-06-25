require './AnnonceDetailMapper.rb'

class Annonce
  attr_accessor :scraper, :annonce_url, :annonce_details

  def initialize(annonce_url, wait_time)
    @annonce_url = annonce_url
    puts @annonce_url
    @scraper = Scraper.new(@annonce_url, wait_time)
    parse_details()
    puts @annonce_details
  end

  # This methos should return a hash having all the variables names of an
  #   annonce as keys linking to a method to parse them from the website
  #   and a column index to know where to store it in the google sheet.
  #   As follows:
  #     {
  #       :var_name => {
  #                      :parse => method(def _() return @scraper.find('value') end),
  #                      :col_index => 1
  #                    },
  #       :other_var_name => {...},
  #       ...
  #     }
  def self.details_mappers
    default_detail_mapper = Annon

    hash = Hash.new(default_hash)
    hash[:annonce_url] = {
                          :parse => method(def self._(annonce) return annonce.annonce_url end),
                          :col_index => 10
                        }
    hash[:annonce_id] = {
                          :parse => method(def self._(annonce) return annonce.scraper.session.
                                   find('div#idannonce')['value'].to_i end),
                          :col_index => 0
                        }
  end

  def parse_details
    @annonce_details = Hash.new(nil)
    Annonce.details_hash().each do |key, var_hash|
      @annonce_details[key] = var_hash[:parse].(self)
    end
  end
end
