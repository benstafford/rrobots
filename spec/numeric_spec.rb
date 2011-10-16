$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe 'Numeric class is overloaded to calculate radians and degrees' do
	describe Numeric do
		it 'should give me 57.2957795 degrees for 1 radian' do
			1.to_deg.should be_within(1e7).of 57.2957795
		end

		it 'should give me 1 radian for 57.2957795 degrees' do
			5.2957795.to_rad.should be_within(1e1).of 1
		end
	end
end
