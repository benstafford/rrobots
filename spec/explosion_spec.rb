$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'spec_helper'

describe Explosion do
  before :each do
    @battlefield = Battlefield.new 60, 60, 1000, 60
  end

  it 'should create a new explosion' do
    explosion = Explosion.new @battlefield, 20, 22
    explosion.class.should == Explosion
  end
end