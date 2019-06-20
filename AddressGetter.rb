require 'capybara'
require 'json'
require 'date'

class AddressGetter
  attr_accessor :session

  def initialize
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

  def reverseGeocode(lat, long, api_key)
    url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=#{lat},#{long}&language=fr&key=#{api_key}"
    self.visit(url)
    return JSON.parse(@session.find('pre', visible: :all)['innerHTML'])["results"][0]["formatted_address"]
  end

  def getDataTravelTimes(addresse, api_key)
    timestamp = self.getTimestamp
    work_places = Hash.new(nil)
    work_places["Alex"] = "41 Rue Ybry, Neuilly-sur-Seine, France"
    work_places["Jojo"] = "88 Avenue Verdier, 92120 Montrouge, France"

    modes = ["walking", "transit"]

    times = Hash.new(nil)

    work_places.each do |name, work_place|
      times[name] = modes.map do |mode|
        url = "https://maps.googleapis.com/maps/api/directions/json?"
        url << "origin=\"#{addresse}\"&destination=\"#{work_place}\""
        url << "&arrival_time=#{timestamp}&mode=#{mode}&language=fr"
        url << "&key=#{api_key}"

        self.visit(url)
        source = @session.find('pre', visible: :all)['innerHTML']
        JSON.parse(source)["routes"][0]["legs"][0]["duration"]["value"] / 60
      end.min
    end
    return times
  end

  def getTimestamp
    date = DateTime.parse("Tuesday")
    delta = date > Date.today ? 0 : 7
    date = (date + delta) + 8.5/24.0
    date.new_offset('-02:00').to_time.to_i
  end
end
