An implementation of the [Nanobox Custom Provider](https://docs.nanobox.io/providers/create/) spec for Linode.

## Development

### Local Server
`bundle exec puma -e development`

### Update Catalog

### Local Evars
A Linode API key is required to update the catalog files.
`nanobox evar add local API_KEY=your_linode_api_key`
Update catalog config files.
`bundle exec rake catalog:update`

### Console
`bundle exec irb -I. -r app.rb`

### Tests
`rspec`
