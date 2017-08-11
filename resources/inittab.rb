#
# Copyright:: 2014-2016, Chef Software, Inc.
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
#

# actions :install, :remove # foodcritic FC092

property :identifier, name_property: true, kind_of: String
property :runlevel, kind_of: String, required: true
property :processaction, kind_of: String, required: true, equal_to: %w(respawn wait once boot bootwait powerfail off hold ondemand initdefault sysinit)
property :command, kind_of: String, required: true

property :follows, kind_of: String
property :exists, [TrueClass, FalseClass], desired_state: false

default_action :install

load_current_value do |new_resource|
  exists false
  so = shell_out("lsitab #{new_resource.identifier}")
  unless so.error?
    exists true
    fields = so.stdout.lines.first.chomp.split(':')
    # perfstat:2:once:/usr/lib/perf/libperfstat_updt_dictionary >/dev/console 2>&1
    identifier(fields[0])
    runlevel(fields[1])
    processaction(fields[2])
    command(fields[3])
  end
end

action :install do
  converge_if_changed(:runlevel, :processaction, :command) do
    converge_by('Install or update inittab') do
      if current_resource.exists
        shell_out("rmitab #{current_resource.identifier}")
      end
      follow = "-i #{new_resource.follows} " if new_resource.follows
      shell_out("mkitab #{follow}\"#{[new_resource.identifier, new_resource.runlevel, new_resource.processaction, new_resource.command].join(':')}\"")
    end
  end
end

action :remove do
  if current_resource.exists
    converge_by('Remove inittab entry') do
      shell_out("rmitab #{current_resource.identifier}")
    end
  end
end
