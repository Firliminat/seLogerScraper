require "./Scraper.rb"
require "./SearchParameters.rb"

class AnnoncesList
  attr_accessor :scraper, :search_parameters, :page, :nb_pages, :nb_annonces, :on_last_page, :liste_annonces_url

  def initialize(search_parameters, wait_time)

    @search_parameters = SearchParameters.new(search_parameters)
    search_url = @search_parameters.get_search_url()

    @scraper = Scraper.new(search_url, wait_time)
    @liste_annonces_url = Array.new()

    parse_pagination_infos()
    parse_nb_annonces()
    parse_annonces_url()
  end

  private

  def has_nextpage?()
    return @scraper.session.has_css?('a.pagination-next')
  end

  def get_next_page_url()
    return @scraper.session.find('a.pagination-next')['href']
  end

  def parse_pagination_infos()
    @page, @nb_pages = @scraper.session.
      find('.mobile-pagination-number', visible: false)['innerHTML'].
      scan(/\d+/)
  end

  def parse_nb_annonces()
    #################################
    # TODO: FIND ACTUAL NB_ANNONCES #
    #################################
    @nb_annonces = 30
  end

  def nextPage
    if has_nextpage?() then
      nextPageURL = get_next_page_url()
      @scraper.visit(nextPageURL)
      parse_pagination_infos()
    else
      @on_last_page = true
    end
  end

  def parse_annonces_url()
    while !@on_last_page do
      puts "  page #{@page}/#{@nb_pages}"
      @liste_annonces_url << @scraper.session.find_all('a.c-pa-link.link_AB').map do |elt|
        elt['href'].split('?')[0]
      end

      nextPage
    end
  end

end


puts AnnoncesList.new("", 0.001).liste_annonces_url
