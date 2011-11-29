$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'
require 'NewInvader'

describe 'InvaderMath' do
  before(:each) do
    @math = InvaderMath.new
  end

  it 'should find shortest path to turn between 45 and 315' do
    result = @math.turn_toward(45,315)
    result.should == -90
  end
  it 'should find shortest path to turn between 315 and 45' do
    result = @math.turn_toward(315,45)
    result.should == 90
  end
  it 'should find shortest path between 45 and 90' do
    result = @math.turn_toward(45,90)
    result.should == 45
  end
  it 'should find shortest path between 5 and 355' do
    result = @math.turn_toward(5,355)
    result.should == -10
  end
  it 'should rotate correctly from 180 by 90' do
    result = @math.rotated(180,90)
    result.should == 270
  end
  it 'should rotate clockwise past 0' do
    result = @math.rotated(45, -90)
    result.should == 315
  end
  it 'should rotate counter clockwise past 360' do
    result = @math.rotated(270, 90)
    result.should == 0
  end
  it 'should calculate distance between objects next to each other' do
    point1 = InvaderPoint.new(5,5)
    point2 = InvaderPoint.new(65, 5)
    result = @math.distance_between_objects(point1, point2)
    result.should == 60
  end
  it 'should calculate distance between objects one above the other' do
    point1 = InvaderPoint.new(5, 5)
    point2 = InvaderPoint.new(5,65)
    result = @math.distance_between_objects(point1, point2)
    result.should == 60
  end
  it 'should calculate distance between objects at an angle to each other' do
    point1 = InvaderPoint.new(100, 100)
    point2 = InvaderPoint.new(200, 200)
    result = @math.distance_between_objects(point1, point2)
    result.to_i.should == 141
  end
  it 'should calculate 0 degree angle to point straight east' do
    point1 = InvaderPoint.new(5,5)
    point2 = InvaderPoint.new(65, 5)
    result = @math.degree_from_point_to_point(point1, point2)
    result.should == 0
  end
  it 'should calculate 90 degree angle to point straight north' do
    point1 = InvaderPoint.new(5,5)
    point2 = InvaderPoint.new(5,1)
    result = @math.degree_from_point_to_point(point1, point2)
    result.should == 90
  end
  it 'should calculate 180 degree angle to point straight west' do
    point1 = InvaderPoint.new(5,5)
    point2 = InvaderPoint.new(1,5)
    result = @math.degree_from_point_to_point(point1, point2)
    result.should == 180
  end
  it 'should calculate 270 degree angle to point straight south' do
    point1 = InvaderPoint.new(5,5)
    point2 = InvaderPoint.new(5,15)
    result = @math.degree_from_point_to_point(point1, point2)
    result.should == 270
  end

  it 'should calculate location found from radar' do
    point1 = InvaderPoint.new(100,100)
    result = @math.get_radar_point(0,100,point1)
    result.x.should == 200
    result.y.should == 100
  end

  it 'should determine when angle desired is between one angle and another' do
    result = @math.radar_heading_between?(35,45,25)
    result.should be_true
  end

end