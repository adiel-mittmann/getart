require 'sqlite3'
require 'mechanize'
require 'socksify/http'
require 'json'

class GetArt

  SOURCES =
    [
     {
       :regexp => /ieeexplore\.ieee\.org/,
       :banner => "IEEE",
       :fetch => lambda do |mech, url|
         page = mech.get(url)
         metadata = page.body.lines.reject{|x| x !~ /global\.document\.metadata/}.first.gsub(/ *global\.document\.metadata=/, "").gsub(/;$/, "")
         metadata = JSON.parse(metadata)
         url = metadata["pdfUrl"]
         page = mech.get(url)
         page.frame_with(:src => /pdf/).content.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/, IEEE -.*/, "").gsub(/ - new TOC/, "").strip
       end
     },
     {
       :regexp => /sciencedirect\.com/,
       :banner => "SCIENCE DIRECT",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:id => "pdfLink").click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/ScienceDirect Publication: */, "")
       end
     },
     {
       :regexp => /link\.springer\.com/,
       :banner => "SPRINGER",
       :fetch => lambda do |mech, url|
         page = mech.get(url)
         link = page.link_with(:id => "action-bar-download-article-pdf-link")
         if link == nil
           link = page.link_with(:href => /\.pdf$/)
         end
         link.click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/Latest Results for /, "")
       end
     },
     {
       :regexp => /wiley\.com/,
       :banner => "WILEY",
       :fetch => lambda do |mech, url|
         y = mech.get(url).uri.to_s.gsub(/abstract;.*/, "pdf")
         x = mech.get(y).body
         x
       end,
       :transform => lambda do |journal|
         journal
       end
     },
     {
       :regexp => /mitpressjournals\.org/,
       :banner => "MIT PRESS",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/MIT Press Journals: /, "").gsub(/: Table of Contents/, "")
       end
     },
     {
       :regexp => /worldscientific\.com/,
       :banner => "WORLD SCIENTIFIC",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/World Scientific Publishing Company: /, "").gsub(/: Table of Contents/, "")
       end
     },
     {
       :regexp => /rss\.acm\.org/,
       :banner => "ACM",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /dwn=1/).click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/-Current Issue/, "")
       end,
     },
     {
       :regexp => /tandfonline\.com/,
       :banner => "TAYLOR AND FRANCIS",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Download full text").click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/Taylor and Francis: /, "").gsub(/: Table of Contents/, "")
       end,
     },
     {
       :regexp => /sagepub\.com/,
       :banner => "SAGE",
       :fetch => lambda do |mech, url|
         page = mech.get(url)
         link = page.link_with(:text => "Full Text (PDF)")
         page = link.click if link
         page.frame_with(:name => "ContentsPage").content.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/ current isue$/, "")
       end,
     },
     {
       :regexp => /iospress\.metapress\.com/,
       :banner => "IOS",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /fulltext\.pdf$/).click.body
       end,
       :transform => lambda do |journal|
         journal
       end,
     },
     {
       :regexp => /www\.plos[a-z]*\.org/,
       :banner => "PLOS",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Download PDF").click.body
       end,
       :transform => lambda do |journal|
         journal
       end,
     },
     {
       :regexp => /liebertpub\.com/,
       :banner => "LIEBERT",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
       :transform => lambda do |journal|
         journal.gsub(/ - Table of Contents/, "")
       end,
     },
     {
       :regexp => /feedburner\.com\/pnas\//,
       :banner => "PNAS",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Full Text (PDF)").click.body
       end,
       :transform => lambda do |journal|
         "PNAS"
       end,
     },
     {
       :regexp => /feeds\.nature\.com/,
       :banner => "NATURE",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\.pdf$/).click.body
       end,
       :transform => lambda do |journal|
         "Nature"
       end,
     },
     {
       :regexp => /sciencemag\.org/,
       :banner => "SCIENCE",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Full Text (PDF)").click.body
       end,
       :transform => lambda do |journal|
         "Science"
       end,
     },
     {
       :regexp => /oxfordjournals\.org/,
       :banner => "OXFORD",
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /full-text\.pdf$/).click.body
       end,
       :transform => lambda do |journal|
         journal
       end,
     },
     {
       :regexp => /arxiv\.org/,
       :banner => "ARXIV",
       :fetch => lambda do |mech, url|
         link = mech.get(url).link_with(:href => /\/pdf\//)
         if link == nil
           puts "There will be an error, probably because the submission was withdrawn from ARXIV"
           puts url
         end
         link.click.body
       end,
       :transform => lambda do |journal|
         journal
       end,
     },
    ]

  def run(cache_db_path, article_dir, socks_host = nil, socks_port = nil)

    @cache_db_path = cache_db_path
    @article_dir   = article_dir
    @socks_host    = socks_host
    @socks_port    = socks_port

    return if !self.setup

    begin
      self.execute
    rescue Net::HTTP::Persistent::Error
      STDERR.puts
      STDERR.puts "There was en error while trying to download a file: #{$!.message}"
    end

  end

  protected


  def setup

    if !File.exists?(@cache_db_path)
      STDERR.puts "#{@cache_db_path}: file does not exist."
      return false
    end

    @db = SQLite3::Database.new(@cache_db_path)

    if @socks_host && @socks_port
      TCPSocket::socks_server = @socks_host
      TCPSocket::socks_port   = @socks_port
    end

    @mech = Mechanize.new
    @mech.user_agent_alias = "Mac Safari"

    return true

  end

  def execute

    puts "= ARTICLE DOWNLOAD ="

    ignored_feeds = {}

    sql = %Q{
SELECT rss_item.id, rss_item.url, rss_item.feedurl, rss_item.title, rss_feed.title
FROM rss_item
JOIN rss_feed ON rss_item.feedurl = rss_feed.rssurl
WHERE rss_item.flags = "e"}

    @db.execute(sql).each do |row|

      id, url, feed, title, journal = row[0..4]

      found = false
      SOURCES.each do |source|
        if feed =~ source[:regexp]
          found = true
          print source[:banner]
          journal = source[:transform].call(journal)
          pdf = nil
          begin
            pdf = source[:fetch].call(@mech, url)
          rescue Mechanize::ResponseCodeError
            case
            when $!.response_code == "403"
              print " FORBIDDEN"
            else
              raise
            end
          rescue NoMethodError
            print " SOMETHING WRONG:"
            print $!
          end
          store_pdf id, journal, title, pdf if pdf
          puts
          break
        end
      end

      if !found
        case
        when !ignored_feeds.has_key?(feed)
          ignored_feeds[feed] = 1
        else
          ignored_feeds[feed] += 1
        end
      end

    end

    if ignored_feeds.size > 0
      puts "= IGNORED FEEDS ="
      puts "count url"
      ignored_feeds.each do |feed, count|
        puts "% 5d %s" % [count, feed]
      end
    end

  end

  protected

  def store_pdf(id, journal, title, pdf)

    if pdf[0..3] != "%PDF"
      print " NOT A PDF"
      return
    end

    title = title.gsub(/\//, "-")
    journal   = journal  .gsub(/\//, "-")

    name = "#{journal}: #{title}"
    name = name[0..60] # TODO
    io = nil
    while io == nil
      begin
        io = File.open("#{@article_dir}/#{name.strip}.pdf", "wb")
      rescue Errno::ENAMETOOLONG
        name = name[0..-2]
      end
    end
    io.write pdf
    io.close
    @db.execute("UPDATE rss_item SET flags = NULL, unread = 0 WHERE id = #{id}")
    print " #{journal}: #{title}"
  end

end

case
when ARGV.size == 2 || ARGV.size == 4
  GetArt.new.run(ARGV[0], ARGV[1], ARGV[2], ARGV[3])
else
  STDERR.puts "USAGE: ruby getart.rb NEWSBEUTER-CACHE-DB ARTICLE-DIR [SOCKS-HOST] [SOCKS-PORT]"
end
