require 'sqlite3'

class Newsbeuter

  def initialize(cache_db_path)
    @db = SQLite3::Database.new(cache_db_path)
  end

  def clear_flags(item_id)
    @db.execute("UPDATE rss_item SET flags = NULL, unread = 0 WHERE id = #{item_id}")
  end

  def get_flagged_items
    items = []

    sql = %Q{
SELECT rss_item.id, rss_item.url, rss_item.feedurl, rss_item.title, rss_feed.title
FROM rss_item
JOIN rss_feed ON rss_item.feedurl = rss_feed.rssurl
WHERE rss_item.flags = "e"
}
    
    @db.execute(sql).each do |row|

      id, url, feed, title, journal = row[0..4]
      item = {}
      item[:id]      = id
      item[:url]     = url
      item[:feed]    = feed
      item[:title]   = title
      item[:journal] = journal
      items << item
    end

    return items

  end

end
