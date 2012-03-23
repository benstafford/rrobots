$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../../')

require 'Simplicity'
require 'SimpleRadar_spec'
require 'SimpleGunner_spec'

def stub_actions
  stub_turns
  @simplicity.stub!(:accelerate)
  @simplicity.stub!(:fire)
  @simplicity.stub!(:broadcast)
  @simplicity.stub!(:say)
end

def stub_turns
  @simplicity.stub!(:turn)
  @simplicity.stub!(:turn_gun)
  @simplicity.stub!(:turn_radar)
end

def expect_turn_left(turn)
  @simplicity.should_receive(turn) do |turn_amount|
    should_be_positive(turn_amount)
  end
end

def should_be_positive(value)
  value.should be > 0
end

def expect_turn_right(turn)
  @simplicity.should_receive(turn) do |turn_amount|
    should_be_negative(turn_amount)
  end
end

def should_be_negative(value)
  value.should be < 0
end

def initialize_events
  @events = Hash.new { |hash, key| hash[key]=[] }
end

def add_scanned_robot
  @events['robot_scanned'] << [1]
end

def create_simplicity
  @simplicity = Simplicity.new
end

describe 'Simplicity' do
  before(:each) do
    create_simplicity
    initialize_events
    stub_actions
  end
  describe 'Basic Functionality' do
    it 'should perform actions on each tick' do
        @simplicity.should_receive(:fire)
        @simplicity.should_receive(:turn_radar)
        @simplicity.should_receive(:turn_gun)
        @simplicity.tick @events
    end
  end
  describe 'Radar Dish' do
    it 'should start out turning left' do
      expect_turn_left(:turn_radar)
      @simplicity.tick @events
    end
    describe 'It should scan directions based on what is seen' do
      before(:each) do
        @simplicity.tick @events
      end
    end
    it 'should turn the radar dish the same direction if no robots are seen' do
      expect_turn_left(:turn_radar)
      @simplicity.tick @events
    end
    it 'should turn the radar dish the opposite direction if robots are seen' do
      add_scanned_robot
      expect_turn_right(:turn_radar)
      @simplicity.tick @events
    end
  end
  describe 'Gun Turret' do
    before (:each) do
      @simplicity.tick @events
    end
    it 'should turn toward the scanned robot' do
      add_scanned_robot
      expect_turn_left(:turn_gun)
      @simplicity.tick @events
    end
  end
end

