require 'picasync/request'
require 'picasync/session'
require 'picasync/call'
require 'picasync/image'

require 'rubygems'
require 'mechanize'
require 'hpricot'
require 'digest/sha2'

module Picasync

  class Album

    attr_reader :id, :title, :images, :updated_at, :edit_uri, :cover, :cover_uri, :asset_count
    attr_writer :images
    

    def initialize(title=nil,id=nil,edit_uri=nil,count=nil,cover=nil,images=[],updated_at=nil)
      @title = title
      @id = id
      @edit_uri = edit_uri
      @cover = "#{Digest::SHA2.hexdigest(cover).split('')[0..11].join('')}.jpg"
      @cover_uri = cover
      @asset_count = count
      @images = images
      @updated_at = updated_at
    end
    
    
    def self.find(param,param2=nil)
      case param
      when :all
        items = []
        doc = Call.new('get',"/data/feed/api/user/#{GOOGLE_USER}?kind=album").response
        if (doc/"link[@rel='edit']").nil?
          Session.new
          doc = Call.new('get',"/data/feed/api/user/#{GOOGLE_USER}?kind=album").response
        end
        (doc/:entry).each do |entry|
          item = {}
          item[:title] = entry.at(:title).inner_text
          item[:updated_at] = entry.at(:updated).inner_text
          item[:cover] = entry.at("media:thumbnail").attributes['url']
          item[:count] = entry.at("gphoto:numphotos").inner_text
          item[:id] = entry.at(:id).inner_text.gsub(/^.*\/|\?.*$/){}
          item[:edit_uri] = (doc/"link[@rel='edit']")[0].attributes['href']
          item[:images] = Image.find(:all, item[:id]) if param2 == :images
          items << item
        end
      end
      found = []
      items.each do |entry|
        found << Album.new(entry[:title],entry[:id],entry[:edit_uri],entry[:count],entry[:cover],entry[:images],entry[:updated_at])
      end
      found
    end
   

    def self.find_by_id(id)
      doc = Call.new('get',"/data/entry/api/user/#{GOOGLE_USER}/albumid/#{id}").response
      if doc == 404
        found = "Album #{id} not found on this account"
      else
        entry = {}
        entry[:title] = doc.at(:title).inner_text
        entry[:updated_at] = doc.at(:updated).inner_text
        entry[:cover] = doc.at("media:thumbnail").attributes['url']
        entry[:count] = doc.at("gphoto:numphotos").inner_text
        entry[:id] = doc.at(:id).inner_text.gsub(/^.*\/|\?.*$/){}
        entry[:edit_uri] = (doc/"link[@rel='edit']")[0].attributes['href']
        entry[:images] = Image.find(:all, entry[:id])
        found = Album.new(entry[:title],entry[:id],entry[:edit_uri],entry[:count],entry[:cover],entry[:images],entry[:updated_at])
      end
      found
    end
    
    def self.find_by_title(param)
      title = param.gsub(/\s/){}
      doc = Call.new('get',"/data/entry/api/user/#{GOOGLE_USER}/album/#{title}").response
      if doc == 404
        found = "Album #{title} not found on this account"
      else
        entry = {}
        entry[:title] = doc.at(:title).inner_text
        entry[:updated_at] = doc.at(:updated).inner_text
        entry[:id] = doc.at(:id).inner_text.gsub(/^.*\/|\?.*$/){}
        entry[:cover] = doc.at("media:thumbnail").attributes['url']
        entry[:count] = doc.at("gphoto:numphotos").inner_text
        entry[:edit_uri] = (doc/"link[@rel='edit']")[0].attributes['href']
        entry[:images] = Image.find(:all, entry[:id])
        found = Album.new(entry[:title],entry[:id],entry[:edit_uri],entry[:count],entry[:cover],entry[:images],entry[:updated_at])
      end
      found
    end

    def create!
      doc = XML::Req::Album.new(title).doc
      response = Call.new('post',doc).response
      @title = (response/"link")[1].attributes['href'].gsub(/^.*\//){}  
      @id = response.at(:id).inner_text.gsub(/^.*\//){}    
    end


    def delete!
      get_edit_uri
      Call.new('delete',"#{@edit_uri}") unless @edit_uri.nil?
    end


    private

    def get_edit_uri
      doc = Call.new('get',"/data/entry/api/user/#{GOOGLE_USER}/albumid/#{@id}").response
      unless (doc/"link[@rel='edit']")[0].nil?
        @edit_uri = (doc/"link[@rel='edit']")[0].attributes['href']
      end
      @edit_uri
    end


    def fetch_set
      items = []
      doc = Call.new('get',"/data/feed/api/user/#{GOOGLE_USER}?kind=album").response
      (doc/:entry).each do |entry|
        item = {}
        item[:title] = entry.at(:title).inner_text
        item[:updated_at] = entry.at(:updated).inner_text
        item[:id] = entry.at(:id).inner_text.gsub(/^.*\/|\?.*$/){}
        item[:edit_uri] = (doc/"link[@rel='edit']")[0].attributes['href']
        items << item
      end
      items
    end

  end

end
