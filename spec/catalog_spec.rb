require 'spec_helper'

describe Catalog do

  describe 'self.regions' do
    it 'returns an array' do
      expect(described_class.regions).to be_an Array
    end
  end

  describe 'self.update' do
    it "doesn't raise errors" do
      VCR.use_cassette('catalog/update') do
        expect{ Catalog.update }.to_not raise_error
      end
    end
  end
end
