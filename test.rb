require_relative 'article-downloader'

urls = %Q{
http://www.nature.com/news/early-career-researchers-need-fewer-burdens-and-more-support-1.20863
http://science.sciencemag.org/content/354/6311/398
http://dsh.oxfordjournals.org/cgi/content/short/fqw043v1
http://arxiv.org/abs/1611.00020
http://link.springer.com/10.1007/s10732-016-9314-9
http://jmlr.org/papers/v17/15-066.html
http://ieeexplore.ieee.org/document/6740844/
http://www.sciencedirect.com/science/article/pii/S0252960216300716
http://onlinelibrary.wiley.com/resolve/doi?DOI=10.1002%2Fcae.21726
http://www.mitpressjournals.org/doi/abs/10.1162/COLI_a_00258
http://www.worldscientific.com/doi/abs/10.1142/S0218488516500355
http://dl.acm.org/citation.cfm?id=2926718
http://tandfonline.com/doi/full/10.1080/21642583.2015.1119070
http://ivi.sagepub.com/cgi/content/abstract/15/4/301
http://content.iospress.com/articles/argument-and-computation/aac003
http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0165916
http://online.liebertpub.com/doi/abs/10.1089/biores.2016.0030
http://www.pnas.org/content/113/44/E6813.short
}

ad = ArticleDownloader.new
urls.lines.each do |url|
  url.strip!
  next if url.size == 0

  domain = url.gsub(/^https?:\/\/([^\/]+).*/, "\\1")
  print "#{domain}... "

  found, details = ad.get(url)

  if found
    puts "OK"
  else
    puts "error: #{details[:reason]}"
  end
end
