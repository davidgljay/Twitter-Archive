require 'twitter'

class Hashtag < ActiveRecord::Base

#before_save :default_values

has_many :links, :foreign_key => "hashtag_id",
                           :dependent => :destroy
has_many :tweets, :through => :links, :source => :tweet


validates :name, :presence => true,
                      :uniqueness => true

default_scope :order => 'hashtags.numtweets DESC'

#Get tweets for a given hashtag.
  def get_tweets 
   Twitter::Search.new.containing(self.name).per_page(100).each do |tweet|
     #Can I add location data here?
     Tweet.create(:t_id => tweet.id, :text => tweet.text, :user => tweet.from_user, :timestamp => tweet.created_at).derive_hashtags if Tweet.find_by_t_id(tweet.id.to_s).nil?
     self.numtweets = self.tweets.count
     self.save
   end
  end

# Create an array of related hashtags.
   def get_related_hashtags
     map_a = self.tweets.map{|tweet| tweet.hashtags.map{|hash| hash.name}}
     map_a.flatten!.delete_if{|tag| tag == self.name} unless map_a.count == 0
     hash_matrix = Array.new
     map_a.uniq.each do |tag|
         hash_matrix << [tag, map_a.count(tag)]
     end
     hash_matrix.sort_by{|hash| hash[1]}.reverse
   end     

#Trim this for the wordcloud. I'm keeping this seperate in case we want the full array at some point.
   def related_hashtag_cloud
     cloud = get_related_hashtags
     #Get rid of the ones that only intersect once.
     cloud.delete_if{|tag| tag[1] == 1}
     cloud = cloud.reverse.drop(cloud.count - 30).reverse if cloud.count > 30
     cloud
   end

end
