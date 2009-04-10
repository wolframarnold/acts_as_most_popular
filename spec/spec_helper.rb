dir = File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(%W(#{dir} .. lib))

# Cache Money fails its own tests with memcache 1.7.x; for now require 1.5.1 (that comes with Rails 2.2.2)
$LOAD_PATH.unshift "/usr/lib/ruby/gems/1.8/gems/activesupport-2.2.2/lib/active_support/vendor/memcache-client-1.5.1"

require 'rubygems'
require 'spec'
require 'cache_money'
require 'memcache'
require File.join(%W(#{dir} .. config environment))
require File.join(%W(#{dir} .. init.rb))

Spec::Runner.configure do |config|
  config.mock_with :rr
  
  config.before :suite do
    load File.join(%W(#{dir} .. db schema.rb))
    config = YAML.load(IO.read(File.join(%W(#{dir} .. config memcached.yml))))['test']
    $memcache = MemCache.new(config)
    $memcache.servers = config['servers']
    $lock = Cash::Lock.new($memcache)
  end

  config.before :each do
    Viewing.delete_all
    $memcache.flush_all
    setup_viewing_data
  end

  config.before :suite do
    ActiveRecord::Base.class_eval do
      is_cached :repository => Cash::Transactional.new($memcache, $lock)
    end

    Item = Class.new(ActiveRecord::Base)
    Viewing = Class.new(ActiveRecord::Base)

    Item.class_eval do
      include ActsAsMostPopular
      has_many :viewings
      acts_as_most_popular :activity_association => :viewings,
      :limit => 4,
      :db_finder_args => { :select => 'item_id, COUNT(*) AS activity_count',  # only item_id is needed, really
                           :group => 'item_id'}
    end

    Viewing.class_eval do
      index :item_id
      belongs_to :item
    end

    10.times { |i| Item.create!(:title => "No. #{i+1}") }
  end
end

def setup_viewing_data
  $viewings_fixture_count = [3,9,3,1,11,4,3,7,2,2]
  $viewings_fixture_count.each_with_index do |count, idx|
    count.times { Item.find(idx+1).viewings.create! }
  end
  $expected_most_popular_index_order = [5,2,8,6,1,3,7,9,10,4]
  $expected_most_popular_list = $expected_most_popular_index_order.map {|idx| Item.find(idx)}
end