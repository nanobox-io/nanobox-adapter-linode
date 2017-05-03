require 'linode'

class Catalog

  SIZES_PATH   = 'lib/catalog/sizes.json'.freeze
  REGIONS_PATH = 'lib/catalog/regions.json'.freeze

  class << self
    def regions
      @regions ||= begin
        parse_file(REGIONS_PATH).map do |dc|
          {
            id:    dc['datacenterid'].to_s,
            name:  dc['location'],
            plans: plans
          }
        end
      end
    end

    def update
      puts 'updating catalog...'

      f = File.open(SIZES_PATH, 'w')
      f << l_client.avail.linodeplans.map(&:to_h).to_json
      f.close
      puts "updated sizes: #{SIZES_PATH}"

      f = File.open(REGIONS_PATH, 'w')
      f << l_client.avail.datacenters.map(&:to_h).to_json
      f.close
      puts "updated regions: #{REGIONS_PATH}"

      puts 'done.'
    end

    def size(plan_id)
      sizes.find { |s| s[:id] == plan_id.to_s }
    end

    private

    def sizes
      @sizes ||= begin
        parse_file(SIZES_PATH).map do |plan|
          {
            id:             plan['planid'].to_s,
            ram:            plan['ram'],
            cpu:            plan['cores'],
            disk:           plan['disk'],
            transfer:       plan['xfer'],
            dollars_per_hr: plan['hourly'],
            dollars_per_mo: plan['price']
          }
        end
      end
    end

    def plans
      @plans ||= begin
        [
          { id: 'standard', name: 'Standard', specs: plans_standard },
          { id: 'high-mem', name: 'High Memory', specs: plans_high_mem }
        ]
      end
    end

    def plans_standard
      @plans_standard ||= sizes.select { |size| size[:id].to_i < 10 }
    end

    def plans_high_mem
      @plans_high_mem ||= sizes.select { |size| size[:id].to_i >= 10 }
    end

    def parse_file(path)
      contents = File.open(path, 'r').read
      JSON.parse(contents) unless contents.empty?
    end

    def l_client
      @l_client ||= ::Linode.new(:api_key => ENV['API_KEY'])
    end
  end
end
