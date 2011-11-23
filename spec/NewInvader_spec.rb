$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'spec_helper'

describe 'NewInvader' do
  before(:each) do
    @bot = NewInvader.new
  end



end

describe 'InvaderMath' do
  before(:each) do
    @bot = NewInvader.new
    @math = InvaderMath.new(@bot)
  end

  it 'should find shortest path to turn between 45 and 315' do
    result = @math.turn_toward(45,315)
    result.should == -90
  end
  it 'should find shortest path to turn between 315 and 45' do
    result = @math.turn_toward(315,45)
    result.should == 90
  end
end