$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'NewInvader'

describe 'InvaderGunner' do
  before(:each) do
    @bot = NewInvader.new
    @bot.stub!(:time).and_return(0)
    @gunner = InvaderFiringEngine.new(@bot)
  end

  it 'should point gun towards opposite edge in normal search mode' do
    @bot.mode = InvaderMode::SEARCHING
    @bot.heading_of_edge = 90
    @bot.stub!(:gun_heading).and_return(240)
    @gunner.fire
    @gunner.turn_gun.should == 30
    @gunner.firepower.should == 0.1
  end



end
