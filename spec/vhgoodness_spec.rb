$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe 'VHGoodness' do
  describe VHGoodness do
    before(:each) do
      @vh_goodness = VHGoodness.new
    end
    it 'should be able to find the relative angle of 45 deg (0,0) and (1,1)' do
      @vh_goodness.angle_give_two_points(0, 0, 1, 1).should == 45
    end
    it 'should be able to find the relative angle of 135 deg (0,0) and (-1,1)' do
      @vh_goodness.angle_give_two_points(0, 0, -1, 1).should == 135
    end
    it 'should be able to find the relative angle of 225 deg (10,10) (0, 0)' do
      @vh_goodness.angle_give_two_points(10, 10, 0, 0).should == 225
    end
    it 'should be able to find the relative angle of 315 deg (0, 5) to (5, 0)' do
      @vh_goodness.angle_give_two_points(0, 5, 5, 0).should == 315
    end
    it 'should return true if gun_angle (45) is within pre-determined range of given angle (45)' do
      @vh_goodness.is_within_fifteen_degree_range?(45, 45).should be_true
    end

    it 'should return false if gun_angle (45) is within pre-determined range of given angle (61)' do
      @vh_goodness.is_within_fifteen_degree_range?(45, 61).should be_false
    end
  end
end