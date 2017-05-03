require 'spec_helper'

describe Client do

  let(:client) { Client.new(ENV['API_KEY']) }

  describe '#verify' do
    it 'returns account info' do
      VCR.use_cassette('client/verify') do
        expect(client.verify.active_since).to be_a String
      end
    end
  end

  describe '#servers' do
    it 'returns an array of servers' do
      VCR.use_cassette('client/servers') do
        result = client.servers
        expect(result).to be_a Array
      end
    end
  end

  describe '#server' do
    it 'returns a server' do
      VCR.use_cassette('client/server') do
        result = client.server('3068345')
        expect(result).to be_a Hash
      end
    end
  end

  describe '#server_order' do
    it 'returns a server id' do
      VCR.use_cassette('client/server_order') do
        result = client.server_order(
          'name'    => 'test-bot',
          'size'    => Meta.attrs[:default_size].to_i,
          'ssh_key' => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWYkCuD5pgtFCNWGeuvsRzZBtr7cp2vDKZ+YFi4j7z13IKuzkf+T7o23kaAENWitAUYel+rWcCIZbMh58NkNfVjgJI6j4FFKPFwMAmDRXWJxRqjjIm4B4i1HT/42RetU41VbP535TGX+wuCWk2G0o839+GWP6jWXcLP3Z3mm69Qzkdz02vdKkfdDpcX/QqPq93pDoceMyGoZvpsZ4J/Ww769KAZCvseEU9jI03iXK2ur9lUGmzbrTfGFSVV7qSBi3ffMlU5dL9hSZCzDtEGX6UjzbDiuyKtPliGQ0m+XFNNG9dztjr67hQ7wBdih+sCUcw8tr+XJAMQrYGW5YReHnl",
          'region'  => Meta.attrs[:default_region].to_i
        )
        expect(result).to be_a Fixnum
      end
    end
  end

  describe '#server_delete' do
    it 'returns linodeid' do
      VCR.use_cassette('client/server_delete') do
        result = client.server_delete('3068345')
        expect(result.linodeid).to be_a Fixnum
      end
    end
  end

  describe '#server_reboot' do
    it 'returns jobid' do
      VCR.use_cassette('client/server_reboot') do
        result = client.server_reboot('3068345')
        expect(result.jobid).to be_a Fixnum
      end
    end
  end

  describe '#server_rename' do
    it 'returns linodeid' do
      VCR.use_cassette('client/server_rename') do
        result = client.server_rename('3068345', 'test-bot-new-name')
        expect(result.linodeid).to be_a Fixnum
      end
    end
  end

  describe '#server_start' do
    it 'returns jobid' do
      VCR.use_cassette('client/server_start') do
        result = client.server_start('3068345')
        expect(result.jobid).to be_a Fixnum
      end
    end
  end

  describe '#server_stop' do
    it 'returns jobid' do
      VCR.use_cassette('client/server_stop') do
        result = client.server_stop('3068345')
        expect(result.jobid).to be_a Fixnum
      end
    end
  end
end
