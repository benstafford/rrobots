$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '../')

require 'PolarIce'
require 'Matrix'

describe 'PolarIce' do
  before(:each) do
    @bot = PolarIce.new
  end

  describe 'It should know its environment' do
    describe 'It should know its location' do
      it 'should know its x value' do
        @bot.stub!(:x).and_return(5)
        @bot.x.should == 5
      end
      it 'should know its y value' do
        @bot.stub!(:y).and_return(5)
        @bot.y.should == 5
      end
    end
    describe 'It should know its headings' do
      it 'should know its heading' do
        @bot.stub!(:heading).and_return(1)
        @bot.heading.should == 1
      end
      it 'should know its gun heading' do
        @bot.stub!(:gun_heading).and_return(2)
        @bot.gun_heading.should == 2
      end
      it 'should know its radar heading' do
        @bot.stub!(:radar_heading).and_return(3)
        @bot.radar_heading.should == 3
      end
    end
    describe 'It should know the battlefield' do
      it 'should know the battlefield width' do
        @bot.stub!(:battlefield_width).and_return(1)
        @bot.battlefield_width.should == 1
      end
      it 'should know the battlefield height' do
        @bot.stub!(:battlefield_height).and_return(1)
        @bot.battlefield_height.should == 1
      end
      it 'should know the time' do
        @bot.stub!(:time).and_return(5)
        @bot.time.should == 5
      end
    end
    describe 'It should know its life' do
      it 'should know its remaining energy' do
        @bot.stub!(:energy).and_return(1)
        @bot.energy.should == 1
      end
      it 'should know that it is alive' do
        @bot.stub!(:dead).and_return(false)
        @bot.dead.should == false
      end
    end
    describe 'It should know its other status' do
      it 'should know the heat of its gun' do
        @bot.stub!(:gun_heat).and_return(1)
        @bot.gun_heat.should == 1
      end
      it 'should know its size' do
        @bot.stub!(:size).and_return(1)
        @bot.size.should == 1
      end
      it 'should know its current speed' do
        @bot.stub!(:speed).and_return(1)
        @bot.speed.should == 1
      end
    end
  end

  describe 'It should initialize variables' do
    it 'should have a default acceleration rate' do
      @bot.accelerationRate.should_not == nil
    end
    it 'should have a default hull rotation' do
      @bot.hullRotation.should_not == nil
    end
    it 'should have a default gun rotation' do
      @bot.gunRotation.should_not == nil
    end
    it 'should have a default radar rotation' do
      @bot.radarRotation.should_not == nil
    end
  end

  describe 'It should handle ticks' do
    before(:each) do
      @bot.stub!(:x).and_return(5)
      @bot.stub!(:y).and_return(10)
      @bot.stub!(:accelerate)
      @bot.stub!(:turn)
      @bot.stub!(:turn_gun)
      @bot.stub!(:turn_radar)
    end
    it 'should handle a nil tick' do
      @bot.tick nil
    end
    describe 'It should initialize variables on a tick' do
      it 'should store its location as a vector' do
        @bot.tick nil
        @bot.currentPosition.should == Vector[5,10]
      end
    end
    describe 'It should move its parts' do
      it 'should accelerate the desired amount' do
        @bot.accelerationRate = 1.0
        @bot.should_receive(:accelerate).with(1.0)
        @bot.tick nil
      end
      it 'should rotate its hull the desired amount' do
        @bot.hullRotation = 15
        @bot.should_receive(:turn).with(15)
        @bot.tick nil
      end
      it 'should rotate its gun the desired amount' do
        @bot.gunRotation = 15
        @bot.should_receive(:turn_gun).with(15)
        @bot.tick nil
      end
      it 'should rotate its radar the desired amount' do
        @bot.radarRotation = 15
        @bot.should_receive(:turn_radar).with(15)
        @bot.tick nil
      end
    end
  end

end

