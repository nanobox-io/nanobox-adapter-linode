require 'linode'
require 'securerandom'

class Client

  attr_reader :api_key

  def initialize(api_key)
    @api_key = api_key
  end

  def verify
    l_client.account.info
  end

  def servers
    l_client.linode.list.map { |l| process_server(l) }
  end

  def server(id)
    linode = l_client.linode.list(LinodeId: id.to_i).first
    raise 'Error #5 - Object not found' unless linode
    process_server(linode)
  end

  def server_order(attrs)
    linode = linode_create(attrs['region'], attrs['size'])
    # rename since no way to provide label during create
    server_rename(linode.linodeid, attrs['name'])
    # add internal_ip
    l_client.linode.ip.addprivate(LinodeId: linode.linodeid)
    # create disk
    disk = linode_create_disk(linode.linodeid, attrs['size'], attrs['ssh_key'])
    # create swap disk
    swap_disk = linode_create_swap_disk(linode.linodeid, attrs['size'])
    # create config
    disks = [disk.diskid, swap_disk.diskid].join(',')
    config = linode_create_config(linode.linodeid, disks)
    # boot
    l_client.linode.boot(LinodeID: linode.linodeid, ConfigID: config.configid)
    # return id for Odin
    linode.linodeid
  end

  def server_delete(id)
    l_client.linode.delete(LinodeId: id.to_i, skipChecks: true)
  end

  def server_reboot(id)
    l_client.linode.reboot(LinodeId: id.to_i)
  end

  def server_rename(id, name)
    # replace dots with underscores since Linode doesn't allow them
    l_client.linode.update(LinodeId: id.to_i, label: name.gsub('.', '_'))
  end

  def server_start(id)
    l_client.linode.boot(LinodeId: id.to_i)
  end

  def server_stop(id)
    l_client.linode.shutdown(LinodeId: id.to_i)
  end

  private

  def process_server(linode)
    s = {
      id:     linode.linodeid,
      name:   linode.label,
      status: tr_status(linode.status)
    }

    external_ip = network_ip('public', linode.linodeid)
    internal_ip = network_ip('private', linode.linodeid)

    s[:external_ip] = external_ip if external_ip
    s[:internal_ip] = internal_ip if internal_ip
    s
  end

  def network_ip(scope, linode_id)
    linode_ip = l_client.linode.ip.list.find do |ip|
      ip.linodeid == linode_id && tr_ip_scope(ip.ispublic) == scope
    end
    linode_ip.ipaddress if linode_ip
  end

  def tr_status(linode_status)
    # Status values are:
    #   -1: Being Created, 0: Brand New, 1: Running, and 2: Powered Off
    case linode_status
    when -1
      'creating'
    when 0
      'new'
    when 1
      'active'
    when 2
      'off'
    end
  end

  def tr_ip_scope(linode_scope)
    case linode_scope
    when 1
      'public'
    when 0
      'private'
    end
  end

  # LINODE ACTIONS START

  def linode_create(region, size)
    l_client.linode.create(
      DatacenterID: region,
      PlanID:       size
    )
  end

  def linode_create_disk(linode_id, size, ssh_key)
    l_client.linode.disk.createfromdistribution(
      LinodeID:       linode_id,
      # Ubuntu 16.04 LTS
      DistributionID: 146,
      Label:          'nanobox-disk',
      Size:           disk_size(size),
      rootSSHKey:     ssh_key,
      # never going to use this password, but it's required
      rootPass:       ::SecureRandom.hex(50)
    )
  end

  def linode_create_swap_disk(linode_id, size_id)
    l_client.linode.disk.create(
      LinodeID: linode_id,
      Type:     'swap',
      Size:     swap_disk_size(size_id),
      Label:    "nanobox-swap"
    )
  end

  def linode_create_config(linode_id, disks)
    l_client.linode.config.create(
      LinodeID: linode_id,
      # GRUB 2
      KernelID: 210,
      Label: "nanobox-profile",
      DiskList: disks
    )
  end

  # LINODE ACTIONS END

  def disk_size(size_id)
    (Catalog.size(size_id)[:disk] * 1000) - swap_disk_size(size_id)
  end

  # equal swap to ram ratio as per:
  # https://help.ubuntu.com/community/SwapFaq#How_much_swap_do_I_need.3F
  def swap_disk_size(size_id)
    Catalog.size(size_id)[:ram]
  end

  def l_client
    @l_client ||= ::Linode.new(:api_key => api_key)
  end
end
