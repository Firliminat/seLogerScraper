require "capybara"
require "selenium-webdriver"
require "user_agent_randomizer"

MIN_WAIT_TIME = 2

class Scraper
  attr_accessor :session, :wait_time, :current_url, :user_agent

  def initialize(target_url, wait_time)
    @wait_time = [MIN_WAIT_TIME, wait_time].max
    @user_agent = UserAgentRandomizer::UserAgent.fetch(type: "desktop_browser")

    @session = initiate_session()
    visit(target_url)
  end

  def visit(target_url)
    sleep(@wait_time)
    @session.driver.browser.manage.delete_all_cookies
    @current_url = target_url
    @session.visit(target_url)
  end

  private

  # Initialisation des drivers de navigation
  def initiate_session()
    Capybara.register_driver :selenium_chrome_headless_morph do |app|
      Capybara::Selenium::Driver.load_selenium
      browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
        # opts.args << '--headless'
        opts.args << '--disable-gpu' if Gem.win_platform?
        opts.args << '--ignore-certificate-errors'
        # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?
        #   id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
        opts.args << '--disable-site-isolation-trials'
        opts.args << '--no-sandbox'
      end
      browser_options.add_emulation(user_agent: @user_agent)
      Capybara::Selenium::Driver.
        new(app, browser: :chrome, options: browser_options)
    end

    # Open a Capybconcatara session with the Selenium web driver for Chromium headless
    return Capybara::Session.new(:selenium_chrome_headless_morph)
  end

end
