class Annonce
  attr_accessor :session, :address_getter

def initialize(arg)
    # Initialisation des drivers de navigation
    Capybara.register_driver :selenium_chrome_headless_morph do |app|
      Capybara::Selenium::Driver.load_selenium
      browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
        opts.args << '--headless'
        opts.args << '--disable-gpu' if Gem.win_platform?
        # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?
        #   id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
        opts.args << '--disable-site-isolation-trials'
        opts.args << '--no-sandbox'
      end
      browser_options.add_emulation(user_agent: "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3) Gecko/20090305 Firefox/3.1b3 GTB5")
      Capybara::Selenium::Driver.
        new(app, browser: :chrome, options: browser_options)
    end

    # Open a Capybara session with the Selenium web driver for Chromium headless
    @session = Capybara::Session.new(:selenium_chrome_headless_morph)
    @address_getter = AddressGetter.new

    self.visit(arg) unless arg.nil?
  end

  def visit(arg)
    if arg.class == String then
      annonceURL = arg
    else
      annonceURL = arg.find('a.c-pa-link.link_AB')['href'].split('?')[0]
    end
    @session.driver.browser.manage.delete_all_cookies
    @session.visit(annonceURL)
  end

  def getPreciseLocation
    @session.find('h1.detail-title.title1').text.sub(/.*\-\s(.*)$/, '\1')
  end

  def getNbPieces
    @session.find('ul.criterion').text.scan(/\d+/)[0].to_i
  end

  def getNbChambres
    @session.find('ul.criterion').text.scan(/\d+/)[1].to_i
  end

  def getNumAgence
    @session.first('button.btn-phone.b-btn.b-second.fi.fi-phone.tagClick', visible: false)['data-phone']
  end

  def get_coordinates
    if @session.find('head', visible: false)['innerHTML'].
    scan(/mapBoundingboxNortheastLatitude\', {\s+value: "(\d+\.\d+)/m).
    length > 0 then
      north_east_lat = @session.find('head', visible: false)['innerHTML'].
      scan(/mapBoundingboxNortheastLatitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f
      north_east_long = @session.find('head', visible: false)['innerHTML'].
      scan(/mapBoundingboxNortheastLongitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f

      south_west_lat = @session.find('head', visible: false)['innerHTML'].
      scan(/mapBoundingboxSouthwestLatitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f
      south_west_long = @session.find('head', visible: false)['innerHTML'].
      scan(/mapBoundingboxSouthwestLongitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f

      lat = (north_east_lat + south_west_lat)/2
      long = (north_east_long + south_west_long)/2

    elsif @session.find('head', visible: false)['innerHTML'].
    scan(/mapCoordonneesLatitude\', {\s+value: "(\d+\.\d+)/m).
    length > 0 then
      lat = @session.find('head', visible: false)['innerHTML'].
      scan(/mapCoordonneesLatitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f
      long = @session.find('head', visible: false)['innerHTML'].
      scan(/mapCoordonneesLongitude\', {\s+value: "(\d+\.\d+)/m)[0][0].to_f

    else
      return nil
    end

    return {:lat => lat, :long => long}
  end

  def getAddress
    coordinates = self.get_coordinates
    if coordinates.nil? then
      return self.getPreciseLocation
    else
      return @address_getter.reverseGeocode(coordinates[:lat], coordinates[:long], 'AIzaSyDIUew1PV5qEJqinlmSjafbZg9ZAwBoeoY')
    end
  end

  def get_travel_times(address)
    return @address_getter.getDataTravelTimes(address, 'AIzaSyDIUew1PV5qEJqinlmSjafbZg9ZAwBoeoY')
  end

  def getAnnonceDetails

    return nil if @session.current_url.match(/#expiree$/) || @session.has_css?("div.annonce_expire.info_box.active")

    annonceDetails = Hash.new(nil)

    @session.find('form.form-contact.jsLockSubmit').
    find_all('input', visible: false).each do |input|
      champs = input[:name].to_sym
      if CHAMPS_PARAMETERS[champs][:to_keep] then
        annonceDetails[champs] = CHAMPS_PARAMETERS[champs][:decode].
        (input[:value])
      end
    end

    annonceDetails[:nb_pieces] = self.getNbPieces
    annonceDetails[:nb_chambres] = self.getNbChambres
    annonceDetails[:preciseLocation] = self.getAddress
    annonceDetails[:tel_agence] = self.getNumAgence

    times = get_travel_times(annonceDetails[:preciseLocation])
    times.each do |name, time|
      key = ("travel_time_#{name}").to_sym
      annonceDetails[key] = time
    end

    annonceDetails[:prix_par_personne] = annonceDetails[:prix] / 3.0
    annonceDetails[:prix_par_metrecarre] = annonceDetails[:prix] / annonceDetails[:surface].to_f
    annonceDetails[:travel_time_Martin] = '?'
    annonceDetails[:travel_time_moyenne] = (annonceDetails[:travel_time_Alex] + annonceDetails[:travel_time_Jojo]) / 2.0
    annonceDetails[:site] = "seLoger"
    annonceDetails[:dispo] = "Oui"

    return annonceDetails
  end
end
