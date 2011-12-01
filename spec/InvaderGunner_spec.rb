$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'NewInvader'

describe 'InvaderGunner' do
  before(:each) do
    @bot = NewInvader.new
    @bot.stub!(:time).and_return(0)
  end

  it 'should point gun towards opposite edge in normal search mode' do
    @gunner = InvaderGunnerSearching.new(@bot)
    @bot.mode = InvaderMode::SEARCHING
    @bot.heading_of_edge = 90
    @bot.stub!(:gun_heading).and_return(240)
    @gunner.fire
    @gunner.turn_gun.should == 30
    @gunner.firepower.should == 0.1
  end

  it 'should turn gun to point at opposite corner in search opposite corner mode' do
    @gunner = InvaderGunnerShootOppositeCorner.new(@bot)
    @bot.mode = InvaderMode::SEARCH_OPPOSITE_CORNER
    @bot.heading_of_edge = 90
    @bot.current_direction = -1
    @bot.stub!(:gun_heading).and_return(210)
    @gunner.fire
    @gunner.turn_gun.should == -30
  end

  it 'should fire ar opposite corner with a full power bolt in search opposite corner mode' do
    @gunner = InvaderGunnerShootOppositeCorner.new(@bot)
    @bot.mode = InvaderMode::SEARCH_OPPOSITE_CORNER
    @bot.heading_of_edge = 90
    @bot.current_direction = -1
    @bot.stub!(:gun_heading).and_return(180)
    @gunner.fire
    @gunner.turn_gun.should == 0
    @gunner.firepower.should == 3.0
  end

  it 'should aim at last known location of enemy in found enemy mode' do
    @gunner = InvaderGunnerFoundTarget.new(@bot)
    @bot.mode = InvaderMode::FOUND_TARGET
    @bot.found_enemy = InvaderPoint.new(600, 600)
    @bot.current_direction = -1
    @bot.stub!(:heading).and_return(0)
    @bot.stub!(:speed).and_return(-8)
    @bot.stub!(:time).and_return(0)
    @bot.stub!(:x).and_return(68)
    @bot.stub!(:y).and_return(60)
    @bot.stub!(:gun_heading).and_return(270)
    @gunner.fire
    @gunner.turn_gun.should == 30
    @gunner.firepower.should > 2.0
  end

  it 'should fire at last known location of enemy in provided target mode' do
    @gunner = InvaderGunnerProvidedTarget.new(@bot)
    @bot.mode = InvaderMode::PROVIDED_TARGET
    @bot.broadcast_enemy = InvaderPoint.new(600, 600)
    @bot.current_direction = -1
    @bot.stub!(:heading).and_return(0)
    @bot.stub!(:speed).and_return(-8)
    @bot.stub!(:time).and_return(0)
    @bot.stub!(:x).and_return(68)
    @bot.stub!(:y).and_return(60)
    @bot.stub!(:gun_heading).and_return(270)
    @gunner.fire
    @gunner.turn_gun.should == 30
    @gunner.firepower.should > 2.0
  end
end
