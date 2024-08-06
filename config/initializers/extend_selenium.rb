module ExtendSelenium
  def initialize(open_timeout: nil, read_timeout: nil)
    @open_timeout = open_timeout
    @read_timeout = read_timeout

    puts "### init selenium: #{@open_timeout} #{@read_timeout}"
    super()
  end
end

Selenium::WebDriver::Remote::Http::Default.prepend(ExtendSelenium)
