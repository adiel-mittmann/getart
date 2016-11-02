require 'mechanize'
require 'json'

class ArticleDownloader

  def initialize()
    @mech = Mechanize.new
    @mech.user_agent_alias = "Mac Safari"
  end

  def get_from_source(source, url)
    pdf = nil
    begin
      pdf = source[:fetch].call(@mech, url)
    rescue Mechanize::ResponseCodeError
      case
      when $!.response_code == "403"
        return false, {:reason => :forbidden}
      else
        raise
      end
    rescue NoMethodError
      return false, {:reason => :no_access_or_old_code}
    end

    if pdf[0..3] != "%PDF"
      return false, {:reason => :not_a_pdf_file}
    end

    return true, {:pdf => pdf}
  end

  def get(url)
    SOURCES.each do |source|
      if url =~ source[:regexp]
        return get_from_source(source, url)
      end
    end
    return false, {:reason => :unknown_source}
  end

  SOURCES =
    [

     {
       :regexp => /ieeexplore\.ieee\.org/,
       :fetch => lambda do |mech, url|
         metadata = mech
                      .get(url)
                      .body
                      .lines
                      .reject{|x| x !~ /global\.document\.metadata/}
                      .first
                      .gsub(/ *global\.document\.metadata=/, "")
                      .gsub(/;$/, "")

         metadata = JSON.parse(metadata)

         return mech
                  .get(metadata["pdfUrl"])
                  .frame_with(:src => /pdf/)
                  .content
                  .body
       end,
     },

     {
       :regexp => /sciencedirect\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:id => "pdfLink").click.body
       end,
     },

     {
       :regexp => /wiley\.com/,
       :fetch => lambda do |mech, url|
         url  = mech.get(url).uri.to_s.gsub(/abstract;.*/, "pdf")
         return mech.get(url).body
       end,
     },

     {
       :regexp => /mitpressjournals\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
     },

     # Could not test it; no access.
     {
       :regexp => /worldscientific\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
     },

     {
       :regexp => /dl\.acm\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /dwn=1/).click.body
       end,
     },

     {
       :regexp => /tandfonline\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
     },

     {
       :regexp => /sagepub\.com/,
       :fetch => lambda do |mech, url|
         mech
           .get(url)
           .link_with(:text => "Full Text (PDF)")
           .click
           .frame_with(:name => "ContentsPage")
           .content
           .body
       end,
     },

     {
       :regexp => /iospress\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/download\//).click.body
       end,
     },

     {
       :regexp => /journals\.plos[a-z]*\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Download PDF").click.body
       end,
     },

     {
       :regexp => /liebertpub\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/doi\/pdf\//).click.body
       end,
     },

     # Could not test it; no access.
     {
       :regexp => /www\.pnas\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\.full\.pdf$/).click.body
       end,
     },

     # Could not test it; no access.
     {
       :regexp => /sciencemag\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:text => "Full Text (PDF)").click.body
       end,
     },

     {
       :regexp => /oxfordjournals\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /full-text\.pdf$/).click.body
       end,
     },

     {
       :regexp => /arxiv\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\/pdf\//).click.body
       end,
     },

     {
       :regexp => /link\.springer\.com/,
       :fetch => lambda do |mech, url|
         page = mech.get(url)
         link = page.link_with(:id => "action-bar-download-article-pdf-link")
         if link == nil
           link = page.link_with(:href => /\.pdf$/)
         end
         link.click.body
       end,
     },

     {
       :regexp => /jmlr\.org/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\.pdf/).click.body
       end,
     },

     {
       :regexp => /nature\.com/,
       :fetch => lambda do |mech, url|
         mech.get(url).link_with(:href => /\.pdf$/).click.body
       end,
     },
    ]

end
