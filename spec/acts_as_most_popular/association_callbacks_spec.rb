require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe 'has_many callbacks' do
  it 'should add :after_add hook' do
    Item.reflect_on_association(:viewings).options[:after_add].should == :incr_activity_count
  end
  it 'should add :after_remove hook' do
    Item.reflect_on_association(:viewings).options[:after_remove].should == :decr_activity_count
  end
  # TODO: Add tests for when assn hooks are array or single string
end
