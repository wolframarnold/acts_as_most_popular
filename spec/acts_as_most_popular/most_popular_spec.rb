require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'most_popular:' do

  describe 'when called for the first time' do
    it 'should call the database' do
      mock.proxy(Viewing).all(Item.aamp_db_finder_args.merge(:order => 'activity_count DESC', :limit => 4))
      Item.most_popular
    end
    it 'should return the expected results' do
      Item.most_popular.should == $expected_most_popular_list[0..3]
    end
  end

  describe 'when called at subsequent times' do
    before(:each) do
      Item.most_popular
    end
    it 'should not access the database for viewings nor items' do
      do_not_call(Item).connection
      do_not_call(Viewing).connection
      Item.most_popular
    end
    it 'should not add anything to index' do
      do_not_call(Item).add(/activity_count_index/, anything)
      Item.most_popular
    end
    it 'should return the expected results with limit' do
      Item.most_popular.should == $expected_most_popular_list[0..3]
    end
  end

  describe 'when order changes' do
    describe 'within limit' do
      before(:all) do
        @top_ct = $viewings_fixture_count[$expected_most_popular_list[0].id-1]
        @second_ct = $viewings_fixture_count[$expected_most_popular_list[1].id-1]
      end
      it 'updates index when item count grows > than predecessor' do
        incr = @top_ct - @second_ct + 1
        incr.times { |i| $expected_most_popular_list[1].viewings.create! }

        new_most_pop = Item.most_popular
        new_most_pop.first.should == $expected_most_popular_list.second
        new_most_pop.second.should == $expected_most_popular_list.first
        new_most_pop[2..-1].should == $expected_most_popular_list[2..3]
      end
      it "doesn't update index when new count == predecessor count" do
        incr = @top_ct - @second_ct
        incr.times { |i| $expected_most_popular_list[1].viewings.create! }

        Item.most_popular == $expected_most_popular_list[0..3]
      end
    end

    describe 'outside of limit' do
      before(:all) do
        @fourth_ct = $viewings_fixture_count[$expected_most_popular_list[3].id-1]
        @eighth_ct = $viewings_fixture_count[$expected_most_popular_list[7].id-1]
      end
      it "doesn't switch order on items with equal activity count" do
        (@fourth_ct - @eighth_ct).times { |i| $expected_most_popular_list[7].viewings.create! }

        Item.most_popular.should == $expected_most_popular_list[0..3]
      end
      it "updates index when last entry gets bumped off because its count is < the new item's count" do
        # bump off last entry
        (@fourth_ct - @eighth_ct + 1).times { |i| $expected_most_popular_list[7].viewings.create! }
        Item.most_popular[3].should == $expected_most_popular_list[7]
        Item.most_popular[0..2].should == $expected_most_popular_list[0..2]
      end
    end
#   TODO: for entities that can shrink, not typically viewings
#      it 'updates index when viewings are dropped' do
#
#      end
  end
end

