require 'rubygems'
require 'hpricot'
require 'generator'
require 'open-uri'

class Topic
  attr_accessor :title, :num, :video, :hqvideo, :version, :game, :teams, :extra, :shoutcast
  @@TITLE = "a"
  @@SC_REGEX = /^#(\d+)/i
  #@@SC_REGEX = /^#(1415)/i
  @@VIDEO_REGEX = /\[VIDEO\]/i
  @@HQVIDEO_REGEX = /\[HQ VIDEO\]/i
  @@VERSION = /\s*\[(\d+\.\d+)\]/i
  @@GAME_REGEX = /\[(.*)\]/i
  @@GAME_REGEX_SPLIT = /\[.*\]/i
  @@TEAM_REGEX = /(.*)\s+vs?\.?\s+(.*)/i
  @@REMAINDER_REGEX = /.*?(?:\s+(\[.+\]))?\s+(.*)\s+vs\s+(.*)/i
  
  def initialize(div, span)
    # title format
    # #1234 [VIDEO] [HQ VIDEO] [2.6] TEXT [OP/TOURNEY, etc.] TEXT vs TEXT
    @title = span.at(@@TITLE).inner_html
    
    @url = span.at(@@TITLE + "[href]")
    
    @created = ""
    @creator = ""
    @updated = ""
    
    
    if @title =~ @@SC_REGEX
      @shoutcast = true
      @num = $1

      str = @title.gsub(@@SC_REGEX, "").strip
      
      @video = (str =~ @@VIDEO_REGEX) != nil
      str = str.gsub(@@VIDEO_REGEX, "").strip
            
      @hqvideo = (str =~ @@HQVIDEO_REGEX) != nil
      str = str.gsub(@@HQVIDEO_REGEX, "").strip

      str =~ @@VERSION
      @version = $1
      if !@version
        @version = "?" 
      end
      str = str.gsub(@@VERSION, "").strip

      str =~ @@GAME_REGEX
      @game = $1
      parts = str.split(@@GAME_REGEX_SPLIT)
      if parts.length > 1
        @extra = parts[0].strip
        players = parts[-1].strip
      elsif parts.length == 1
        players = parts[0].strip
      else
        alert "extra parts length #{parts.length}"
      end

      players =~ @@TEAM_REGEX
      @teams = [$1, $2]        
    else
      @shoutcast = false
    end
    
  end
  
  def to_s
    "#{@title} ##{@num} video: #{@video} hqvideo: #{@hqvideo} version: #{@version} game: #{@game} teams: #{@teams} extra: #{@extra}" 
  end
end

class AfterActionReview < Shoes
  @@COH_SHOUTCAST_FORUM = 'http://www.gamereplays.org/community/index.php?showforum=1209'
  @@TOPIC_SPAN = "span[@class='topic_title']"
  @@DIVS = "//div"
  @@SHOUTCAST_TITLE_REGEX = //
  url '/', :index
  
  def shoutcasts
    return Generator.new do |g|
      doc = open(@@COH_SHOUTCAST_FORUM) { |f| Hpricot(f) }
      # <span class="topic_title" id='tid-span-542783'>
      # hpricot's xpath ain't so good...so have to perform
      # a nested search
      doc.search(@@DIVS).each do |div|
        span = div.at("/" + @@TOPIC_SPAN) 
        if span
          topic = parse_shoutcast(div, span)
          if topic.shoutcast
            g.yield topic
          end
        end
      end
    end
  end
  
  def parse_shoutcast(div, span)
    sc = Topic.new(div, span)
    return sc
  end
  
  def index
    g = shoutcasts
    stack do
      topics = Array.new
      while g.next?
      #for i in 1..10 do
        #topic_widget g.next
        topics << g.next
      end
      topics.sort! do |a, b|
        Integer(b.num) <=> Integer(a.num)
      end
      for topic in topics do
        topic_widget topic
      end
    end
  end
  
  def topic_widget(topic)
    return flow do
      stack :width => "100px", :align => "center", :center => true do
        para link("#{topic.num}", :click => "http://google.com"), :align => "center", :center => true 
        button "download replay", :width => "90px", :align => "center", :center => true 
        button "download shoutcast", :width => "90px", :align => "center", :center => true 
      end
      stack :width => "*" do
        para link("#{topic.teams[0]} vs #{topic.teams[1]}", :click => "http://google.com")
        inscription "video: #{topic.video} hqvideo: #{topic.hqvideo} version: #{topic.version} game: #{topic.game} extra: #{topic.extra}"
      end
    end
  end

  
end

Shoes.app :title => "Company of Heroes - After Action Report"