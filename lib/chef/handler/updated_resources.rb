#
# Copyright:: 2017, Your Company <Maintainer@yourcompany.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'chef/handler'
require 'json'
require 'socket'

module ServiceNowReport
  class UpdatedResources < Chef::Handler

    def savetime
      Time.now.strftime('%Y%m%d%H%M%S')
    end
    
    def report
      build_report_dir

       blacklist = [
        'template[/etc/centrifydc/centrifydc.conf]',
        'bash[sysctl-net.ipv4.conf.all.accept_redirects]',
        'bash[sysctl-net.ipv4.conf.all.send_redirects]',
        'bash[sysctl-net.ipv4.conf.default.send_redirects]',
        'bash[sysctl-net.ipv4.conf.default.accept_redirects]',
        'bash[sysctl-net.ipv4.conf.all.secure_redirects]',
        'bash[sysctl-net.ipv4.conf.default.secure_redirects]',
        'bash[sysctl-net.ipv4.conf.all.log_martians]',
        'bash[sysctl-net.ipv4.conf.default.log_martians]',
        'ruby_block[syslog_rwlog]',
        'ruby_block[syslog_nalog]',
        'file[/etc/scsp-check-bypass]',
        'execute[install dcs]',
      ]

      report_file = File.open(File.join('/var/chef/reports', "chef-update-report-#{savetime}.txt"), 'w')

      updated_resources.each do |r|
        next if blacklist.include? r.to_s

        resource_recipe = "recipe[#{r.cookbook_name}::#{r.recipe_name}] ran '#{r.action}' on #{r.resource_name} '#{r.name}'"
        report_file << "\n#{resource_recipe}"
      end

      report_file.close

      if File.zero?("/var/chef/reports/chef-update-report-#{savetime}.txt")
        clean_up_empty_file
      else
        snow_api
        clean_up
      end
    end

    def build_report_dir
      unless File.exist?('/var/chef/reports')
        FileUtils.mkdir_p('/var/chef/reports')
        File.chmod(00744, '/var/chef/reports')
      end
    end

    def snow_api
      # Gather some variables
      hostname = Socket.gethostname[/^[^.]+/]
      file = File.open("/var/chef/reports/chef-update-report-#{savetime}.txt")
      data = ''
      file.each { |line| data << line }
      t = Time.now
      st = t + (60 * 60 * 7)
      et = t + (60 * 60 * 8)

      json_hash = {
        'u_assigned_to' => 'assigned_user',
        'u_planned_start_date' => st.to_s,
        'u_planned_end_date' => et.to_s,
        'u_template' => 'Chef Client Runs',
        'u_short_description' => 'Chef Client Runs',
        'u_cmdb_ci' => hostname.to_s,
        'u_description' => data.to_s
      }

      File.open('/var/chef/reports/updated_resources.json', 'w') do |f|
        f.write(json_hash.to_json)
      end

      uname = 'username'
      pwd = 'password'
      proxy = 'proxy-app.yourcompany.com:8080'
      url = 'https://yourcompany.service-now.com/api/now/import/u_chef_standard_change'
      request_post = 'POST'
      header1 = 'Accept:application/json'
      header2 = 'Content-Type:application/json'
      open_data = '@/var/chef/reports/updated_resources.json'

      puts command = `curl -x #{proxy} #{url} --request #{request_post} --header #{header1} --header #{header2} --data #{open_data} --user #{uname}:#{pwd}`

      # sys_id = JSON.parse(command)["result"]["sys_id"]
    end

    def dir_clean_up
      # Keeps files that are less than 10 days old
      clean_dir = '/var/chef/reports'

      Dir.chdir(clean_dir)

      d = Dir.new(clean_dir)
      d.each do |name|
        if File.file?(name)
          if File.mtime(name) < Time.now - (60 * 60 * 24 * 10)
            File.delete(name)
          end
        end
      end
    end

    def clean_up
      FileUtils.rm('/var/chef/reports/updated_resources.json')
      dir_clean_up
    end

    def clean_up_empty_file
      FileUtils.rm("/var/chef/reports/chef-update-report-#{savetime}.txt")
    end

  end
end
