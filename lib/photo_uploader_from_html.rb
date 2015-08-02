require "photo_uploader_from_html/version"
require 'mechanize'
require 'tumblife'
require 'yaml'

module PhotoUploaderFromHtml
  class UnknownContentType < StandardError; end

  extend self

  CONTENT_TYPES = {
    '.jpg' => 'image/jpeg',
    '.jpeg' => 'image/jpeg',
    '.gif' => 'image/gif',
    '.png' => 'image/png',
  }

  def run
    while string = STDIN.gets
      puts replace string
    end
  end

  def replace(string)
    string.gsub(/<img width=(\d+) src='(\S+)'>/) do
      width, src = $1, $2
      if /\A\d+\.media\.tumblr\.com/ =~ src
        %Q(<img width=#{width} src='#{src}'>)
      else
        %Q(<img width=#{width} src='#{upload(src)}'>)
      end
    end
  end

  def upload(uri)
    Tumblife.configure do |config|
      config.consumer_key       = choose_host['consumer_key']
      config.consumer_secret    = choose_host['consumer_secret']
      config.oauth_token        = choose_host['oauth_token']
      config.oauth_token_secret = choose_host['oauth_token_secret']
    end

    id = do_upload(uri)
    scrape(id)
  end

  def do_upload(uri)
    content_type = guess_content_type(uri)
    photo(uri, content_type)
  end

  def guess_content_type(uri)
    extname = File.extname(uri)
    extname = extname.split('?').first.to_s.split(':').first.to_s
    return 'image/jpeg' if extname.empty?
    CONTENT_TYPES[extname] || raise(UnknownContentType)
  end

  def photo(uri, content_type)
    mash = Tumblife.client.photo(host, source: uri, content_type: content_type)
    mash.id.to_s
  rescue => e
    $stderr.puts '[ERROR]'
    $stderr.puts uri
  end

  def scrape(id)
    uri = build_uri(id)
    try_scrape_three_times(uri)
  end

  def build_uri(id)
    "http://#{host}/#{id}"
  end

  def host
    choose_host['name']
  end

  def hosts
    YAML.load_file('./hosts.yml')
  end

  def host_index
    0
  end

  def choose_host
    hosts[host_index]
  end

  def try_scrape_three_times(uri)
    do_scrape(uri)
  rescue
    count ||= 0
    count += 1
    retry if count < 3
  end

  def do_scrape(uri)
    @agent ||= ::Mechanize.new
    @agent.get uri
    xpath1 = '//*[@id="posts"]/li/section[@class="top media"]/img'
    xpath2 = '//*[@id="posts"]/li/section[@class="top media"]/a/img'

    img = @agent.page/(xpath1)
    return img.last.attr('src') if !img.empty?
    img = @agent.page/(xpath2)
    return img.last.attr('src') if !img.empty?

    raise
  end
end
