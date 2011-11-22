$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'old_kinney_bot'
require 'robot'

describe KinneyBot do
  before(:each) do
    @bot = KinneyBot.new
    @events = {'broadcasts' => [["loc|5|10", "east"]], 'robot_scanned' => [[10.0]]}
  end

  it 'should recalculate y to a usable trig number' do
    @bot.stub!(:battlefield_height).and_return(20)
    @bot.stub!(:my_y).and_return(15)
    @bot.y_to_grid.should == 5
  end

  describe 'Eat it Sucka' do
    it 'should be able to find the approximate point for an enemy scanned' do
      @bot.stub!(:my_x).and_return(15)
      @bot.stub!(:my_y).and_return(15)
      @bot.stub!(:radar_heading).and_return(50)
      @bot.find_enemy_by_distance(14.1).should == [25,-105]
    end

    it 'should be able to find the approximate point for an enemy scanned below me' do
      @bot.stub!(:my_x).and_return(15)
      @bot.stub!(:my_y).and_return(15)
      @bot.stub!(:radar_heading).and_return(130)
      @bot.find_enemy_by_distance(14.1).should == [5,5]
    end
  end

  describe 'Move your ass' do
    it 'should be able to find the middle of the map when the width and height are even numbers' do
      @bot.stub!(:battlefield_width).and_return(200)
      @bot.stub!(:battlefield_height).and_return(200)
      @bot.map_middle.should == {'x' => 100, 'y' => 100}
    end

    it 'should be able to find the middle of the map when the width and height are odd numbers' do
      @bot.stub!(:battlefield_width).and_return(201)
      @bot.stub!(:battlefield_height).and_return(201)
      @bot.map_middle.should == {'x' => 100, 'y' => 100}
    end

    it 'should get the opposite angle from two points' do
      x1, y1, x2, y2 = 5, 5, 5, 10
      @bot.opposite_angle_between_two_points(x1, y1, x2, y2).should == 270
    end

    it 'should get the angle directly away from center' do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(5)
      @bot.stub!(:battlefield_width).and_return(10)
      @bot.stub!(:battlefield_height).and_return(20)
      @bot.begin_tick @events
      @bot.angle_away_from_center.should == 270
    end

    it 'should turn the tank 10 degrees if the difference between current heading and new heading are more than 10 degrees apart' do
      @bot.my_heading = 270
      @bot.stub!(:heading).and_return(90)
      @bot.stub!(:turn).with(10).and_return(nil)
      @bot.should_receive(:turn)
      @bot.turn_to_heading().should == 10
    end

    it 'should turn the tank 8 degrees if the difference between current heading and new heading are 8 degrees apart' do
      @bot.my_heading = 98.1
      @bot.stub!(:heading).and_return(90.1)
      @bot.stub!(:turn).with(8).and_return(nil)
      @bot.should_receive(:turn)
      @bot.turn_to_heading().should == 8
    end
  end

  describe 'Do not Shoot your partner' do
    it 'should be able to process events for my partners location' do
      events = {'broadcasts' => [["loc|500.6|500.8", "east"]]}
      @bot.process_events events
      @bot.partner.x.should == 500
      @bot.partner.y.should == 500
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 5,10' do
      x1, y1, x2, y2 = 5, 5, 5, 10
      @bot.angle_between_two_points(x1, y1, x2, y2).should == 90
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 10,5' do
      x1, y1, x2, y2 = 5, 5, 10, 5
      @bot.angle_between_two_points(x1, y1, x2, y2).should == 0
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 5,0' do
      x1, y1, x2, y2 = 5, 5, 5, 0
      @bot.angle_between_two_points(x1, y1, x2, y2).should == 270
    end

    it 'should find the angle of between 2 points when point 1 is 5,5 and point 2 is 0,5' do
      x1, y1, x2, y2 = 5, 5, 0, 5
      @bot.angle_between_two_points(x1, y1, x2, y2).should == 180
    end

    it 'should return true if 2 angles are withing 15 degrees of each other' do
      gun_angle, p_angle = 104, 90
      @bot.two_angles_within_fifteen_degrees?(gun_angle, p_angle).should == true
    end

    it 'should return false if 2 angles are more than 15 degrees of each other' do
      gun_angle, p_angle = 106, 90
      @bot.two_angles_within_fifteen_degrees?(gun_angle, p_angle).should == false
    end

    it 'should return true if 2 angles are exactly 15 degrees of each other' do
      gun_angle, p_angle = 105, 90
      @bot.two_angles_within_fifteen_degrees?(p_angle, gun_angle).should == true
    end

    it 'should set KinneyBots x and y values in the beginning of a tick' do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(5)
      @bot.begin_tick @events
      @bot.my_x.should == 5
      @bot.my_y.should == 5
    end

    it 'should set the angle to my partner in the beginning of a tick' do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(5)
      @bot.begin_tick @events
      @bot.partner.angle.should == 90
    end

    it 'should not fire if partner angle and gun heading are within 15 degrees' do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(5)
      @bot.stub!(:gun_heading).and_return(104)
      @bot.stub!(:fire).with(3).and_return(nil)
      @bot.should_not_receive(:fire)
      @bot.begin_tick @events
      @bot.fire_gun_if_not_partner 3
    end

    it 'should fire if my partner angle and gun heading are not within 15 degrees' do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(5)
      @bot.stub!(:gun_heading).and_return(106)
      @bot.stub!(:fire).with(3).and_return(nil)
      @bot.should_receive(:fire)
      @bot.begin_tick @events
      @bot.fire_gun_if_not_partner 3
    end
  end
end