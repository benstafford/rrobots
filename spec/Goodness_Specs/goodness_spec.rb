$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')
require 'spec_helper'

describe 'Goodness' do
  describe Goodness do
    before :each do
      @goodness = Goodness.new 1
    end

    it 'should know about itself' do
      @goodness.id.should  == 1
    end

    it 'should know about its partner' do
      @partner = Goodness.new 2
      @goodness.get_partner
      @goodness.partner.id.should == 2
    end

    it 'should still have a reference to its partner after the team is nil' do
      @partner = Goodness.new 2
      @goodness.get_partner
      @goodness.reset_team
      @goodness.partner.change_id 3
      @goodness.partner.id.should == 3
    end
  end
end