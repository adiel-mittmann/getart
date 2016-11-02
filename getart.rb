require_relative 'newsbeuter'
require_relative 'article-downloader'

class GetArt

  def initialize(cache_db_path, article_dir)
    puts "# Starting"
    @newsbeuter = Newsbeuter.new(cache_db_path)
    @article_dir   = article_dir
    @article_downloader = ArticleDownloader.new
  end

  def run

    all_ok = true

    items = @newsbeuter.get_flagged_items

    puts "Found #{items.size} item(s) to download"

    items.each_with_index do |item, index|

      domain = item[:url].gsub(/^https?:\/\/([^\/]+).*/, "\\1")
      print "## Downloading item #{index + 1}/#{items.size}, from #{domain}... "

      found, spec = @article_downloader.get(item[:url])

      if found
        store_pdf item, spec[:pdf]
        @newsbeuter.clear_flags(item[:id])
        puts "done."
      else
        puts "error: #{spec[:reason]}"
        puts "URL: #{item[:url]}"
        all_ok = false
      end

    end

    if !all_ok
      puts "# Warning: some items could not be downloaded"
    end

  end

  protected

  def store_pdf(item, pdf)

    title   = item[:title]  .gsub(/\//, "-")
    journal = item[:journal].gsub(/\//, "-")

    # There must be a better way.
    journal = journal[0..30]
    title   = title[0..30]

    name = "#{journal}: #{title}"

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
  end

end

case
when ARGV.size == 2
  GetArt.new(ARGV[0], ARGV[1]).run
else
  STDERR.puts "USAGE: ruby getart.rb NEWSBEUTER-CACHE-DB ARTICLE-DIR"
end
