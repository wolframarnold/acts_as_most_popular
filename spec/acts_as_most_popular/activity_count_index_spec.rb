require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'store_activity_count_index' do

  it 'sets cache value to [item_id, activity_count] for each item up to limit' do
    4.times do |i|
      mock(Item).set("activity_count_index/#{i}", [$expected_most_popular_list[i].id, $expected_most_popular_list[i].viewings.count])
    end
    Item.store_activity_count_index
  end
  
end
# TODO: Handle case where there are fewer viewings than limit