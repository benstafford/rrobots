describe 'SimpleRadar' do
  before(:each) do
    @radar = SimpleRadar.new
  end
  it 'should start turning left' do
    @radar.turn_amount.should be > 0
  end
  it 'should turn right if reverse is called while turning left' do
    @radar.reverse
    @radar.turn_amount.should be < 0
  end
  it 'should turn left if reverse is called while turning right' do
    @radar.reverse
    @radar.reverse
    @radar.turn_amount.should be > 0
  end
end