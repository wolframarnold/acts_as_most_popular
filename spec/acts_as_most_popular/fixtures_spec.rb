require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'Fixtures' do
  it 'should have 10 Item instances' do
    Item.count.should == 10
  end

  describe 'setup viewing data' do
    it 'should create [3,9,3,1,11,4,3,7,2,2] viewings' do
      $viewings_fixture_count.should == [3,9,3,1,11,4,3,7,2,2]
      $viewings_fixture_count.each_with_index do |count, i|
        Item.find(i+1).viewings.count.should == count
      end
    end
  end

  describe 'most popular items' do
    it 'should be in this order: [5,2,8,6,1,3,7,9,10,4]' do
      $expected_most_popular_index_order.uniq.should == [5,2,8,6,1,3,7,9,10,4]
      $expected_most_popular_list.all?{|item| item.is_a?(Item)}.should be_true
    end
    it 'should be in the same order as direct database lookup' do
      $expected_most_popular_index_order.should ==
        Viewing.all(Item.aamp_db_finder_args.merge(:order => 'activity_count DESC')).map(&:item_id)
    end
  end
end