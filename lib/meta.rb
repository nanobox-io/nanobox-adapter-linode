class Meta
  class << self
    def attrs
      {
        id:                'ln',
        name:              'Linode(beta)',
        server_nick_name:  'linode',
        default_region:    '3',
        default_plan:      'standard',
        default_size:      '1',
        ssh_user:          'root',
        internal_iface:    'eth0:1',
        external_iface:    'eth0',
        bootstrap_script:  'https://s3.amazonaws.com/tools.nanobox.io/bootstrap/ubuntu.sh',
        # options: reference, object
        ssh_key_method:    'object',
        can_reboot:        true,
        can_rename:        true,
        credential_fields: [{ key: :api_key, label: 'API Key' }],
        instructions:      instructions
      }
    end

    private

    def instructions
    <<-INSTR
<a href="//manager.linode.com/profile/api" target="_blank">Create
an API Key</a> in your Linode Account, then add it here. Please note this
Nanobox integration is still undergoing beta testing and should not be relied
upon for production use.
    INSTR
    end
  end
end
