# chef-handler-updated-resources

Chef report handler to report resources updated in the Chef Run.  Upon a successful chef run, an API call is made to ServiceNow

# Installation

This report handler should be installed into the Ruby environment used by Chef. This can be done with `/opt/chef/embedded/bin/gem` or `c:\opscode\embedded\bin\gem`. Or, it can be installed using the `chef_gem` resource.

# Usage

Configure `/etc/chef/client.rb` or other config file:

```ruby
require 'chef/handler/updated_resources'
report_handlers << SimpleReport::UpdatedResources.new
```

Optionally, pass an argument specifying a prefix for updated resource messages. The default is `'  '` (two spaces). This may make it easier to grep for updated resources, depending on your tooling.

```ruby
require 'chef/handler/updated_resources'
report_handlers << SimpleReport::UpdatedResources.new('GREPME')
```

Or, use the [chef_handler cookbook](https://supermarket.chef.io/cookbooks/chef_handler).

```ruby
chef_gem 'chef-handler-servicenow' do
  compile_time true
end

chef_handler 'SimpleReport::UpdatedResources' do
  source 'chef/handler/updated_resources'
  action :enable
end
```

# License and Author

- Author: Ryan Kotecki <ryankotecki@email.com>
- Copyright 2018, Your Company
