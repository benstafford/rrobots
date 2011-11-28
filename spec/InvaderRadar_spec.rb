$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'NewInvader'

describe 'InvaderRadar' do
  before(:each) do
    @bot = NewInvader.new
    @bot.mode = InvaderMode::SEARCHING
    @bot.heading_of_edge = 90
    @bot.move_engine.current_direction = -1
    @bot.stub!(:x).and_return(1540)
    @bot.stub!(:y).and_return(60)
    @radar = InvaderRadarEngine.new(@bot)
  end

  it 'bot should know its location' do
    @bot.stub!(:x).and_return(1540)
    @bot.stub!(:y).and_return(60)
    location = @bot.location
    location.x.should == 1540
    location.y.should == 60
  end

  it 'should locate enemy when in normal scan mode' do
    @radar.ready_for_metronome = true
    robots_scanned = [[1500]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 1409
    enemy.x.should < 1411
    enemy.y.should > 1554
    enemy.y.should < 1556
  end

  it 'should identify if there is no enemy in normal scan mode' do
    @radar.ready_for_metronome = true
     robots_scanned = []
     enemy = @radar.scan_radar(robots_scanned)
     enemy.should be_nil
  end

  it 'should weed out my friend as identified enemy in normal scan mode' do
    @radar.ready_for_metronome = true
    @bot.friend = InvaderPoint.new(1410, 1555)
    robots_scanned = [[1500]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.should be_nil
  end

  it 'should return closest enemy in normal scan mode' do
    @radar.ready_for_metronome = true
    @bot.friend = InvaderPoint.new(1410, 1555)
    robots_scanned = [[1500], [1400], [600]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 1487
    enemy.x.should < 1489
    enemy.y.should > 657
    enemy.y.should < 659
  end

  it 'should point its radar to opposite edge in normal scan mode' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(210)
    @radar.radar_sweep
    @radar.turn_radar.should == 60
  end
  it 'should point its radar towards opposite edge in normal scan mode' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(180)
    @radar.radar_sweep
    @radar.turn_radar.should == 60
  end
  it 'should begin metronome scanning when pointed correctly' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(270)
    @radar.radar_sweep
    @radar.turn_radar.should == -5
    @radar.ready_for_metronome.should be_true
  end
  it 'should continue metronome scanning once begun' do
    @radar.ready_for_metronome = true
    @bot.stub!(:radar_heading).and_return(265)
    @radar.radar_sweep
    @radar.turn_radar.should == 5
    @radar.ready_for_metronome.should be_true
  end

end

describe 'InvaderRadarEngineSearchOppositeCorner' do
  before(:each) do
    @bot = NewInvader.new
    @bot.mode = InvaderMode::SEARCH_OPPOSITE_CORNER
    @bot.heading_of_edge = 90
    @bot.move_engine.current_direction = -1
    @bot.stub!(:x).and_return(1540)
    @bot.stub!(:y).and_return(60)
    @radar = InvaderRadarEngineSearchOppositeCorner.new(@bot)
  end

  it 'should locate enemy along same edge when scanning it own edge' do
    @radar.ready_for_metronome = true
    robots_scanned = [[1500]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 39
    enemy.x.should < 41
    enemy.y.should > 59
    enemy.y.should < 61
  end

  it 'should identify if there is no enemy on the edge' do
    @radar.ready_for_metronome = true
     robots_scanned = []
     enemy = @radar.scan_radar(robots_scanned)
     enemy.should be_nil
  end

  it 'should weed out my friend as identified enemy on edge' do
    @radar.ready_for_metronome = true
    @bot.friend = InvaderPoint.new(40, 60)
    robots_scanned = [[1500]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.should be_nil
  end

  it 'should return closest enemy on edge' do
    @radar.ready_for_metronome = true
    @bot.friend = InvaderPoint.new(40, 60)
    robots_scanned = [[1500], [1400], [600]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 939
    enemy.x.should < 941
    enemy.y.should > 59
    enemy.y.should < 61
  end

  it 'should point its radar to opposite edge in scan edge mode' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(210)
    @radar.radar_sweep
    @radar.turn_radar.should == -30
  end

  it 'should point its radar towards opposite edge in scan edge mode' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(110)
    @radar.radar_sweep
    @radar.turn_radar.should == 60
  end
  it 'should begin metronome scanning when pointed correctly' do
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(180)
    @radar.radar_sweep
    @radar.turn_radar.should == 1
    @radar.ready_for_metronome.should be_true
  end
  it 'should continue metronome scanning once begun' do
    @radar.ready_for_metronome = true
    @bot.stub!(:radar_heading).and_return(181)
    @radar.radar_sweep
    @radar.turn_radar.should == -1
    @radar.ready_for_metronome.should be_true
  end

end

describe 'InvaderRadarEngineProvidedTarget' do
  before(:each) do
    @bot = NewInvader.new
    @bot.mode = InvaderMode::PROVIDED_TARGET
    @bot.stub!(:y).and_return(60)
    @bot.move_engine.target_enemy = InvaderPoint.new(600,600)
    @radar = InvaderRadarEngineProvidedTarget.new(@bot)
  end

  it 'should scan for friend-provided target' do
    @radar.ready_for_metronome = true
    @bot.stub!(:x).and_return(1540)
    robots_scanned = [[1083]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 599
    enemy.x.should < 601
    enemy.y.should > 599
    enemy.y.should < 601
  end

  it 'should identify if provided target is no longer seen' do
     @radar.ready_for_metronome = true
     @bot.stub!(:x).and_return(1540)
     robots_scanned = []
     enemy = @radar.scan_radar(robots_scanned)
     enemy.should be_nil
  end

  it 'should weed out my friend as identified enemy in provided target mode' do
    @radar.ready_for_metronome = true
    @bot.stub!(:x).and_return(1540)
    @bot.friend = InvaderPoint.new(600, 600)
    robots_scanned = [[1083]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.should be_nil
  end

  it 'should return closest enemy in provided target mode' do
    @radar.ready_for_metronome = true
    @bot.stub!(:x).and_return(1540)
    @bot.friend = InvaderPoint.new(600, 600)
    robots_scanned = [[1500], [1083], [600]]
    enemy = @radar.scan_radar(robots_scanned)
    enemy.x.should > 1019
    enemy.x.should < 1021
    enemy.y.should > 358
    enemy.y.should < 360
  end

  it 'should point its radar to enemy in provided target mode' do
    @bot.stub!(:x).and_return(60)
    @radar.ready_for_metronome = false
    @bot.stub!(:radar_heading).and_return(290)
    @radar.radar_sweep
    @radar.turn_radar.should == 30
  end

  it 'should point its radar towards enemy in provided target mode' do
    @radar.ready_for_metronome = false
    @bot.stub!(:x).and_return(60)
    @bot.stub!(:radar_heading).and_return(240)
    @radar.radar_sweep
    @radar.turn_radar.should == 60
  end
  it 'should begin metronome scanning when pointed correctly' do
    @radar.ready_for_metronome = false
    @bot.stub!(:x).and_return(60)
    @bot.stub!(:radar_heading).and_return(310)
    @radar.radar_sweep
    @radar.turn_radar.should == 10
    @radar.ready_for_metronome.should be_true
  end
  it 'should continue metronome scanning once begun' do
    @radar.ready_for_metronome = true
    @bot.stub!(:x).and_return(60)
    @bot.stub!(:radar_heading).and_return(320)
    @radar.radar_sweep
    @radar.turn_radar.should == -10
    @radar.ready_for_metronome.should be_true
  end
end
