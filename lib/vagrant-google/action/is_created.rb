# Copyright 2013 Google Inc. All Rights Reserved.
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
module VagrantPlugins
  module Google
    module Action
      # This can be used with "Call" built-in to check if the machine
      # is created and branch in the middleware.
      class IsCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:result] = env[:machine].state.id != :not_created

          zone = env[:machine].provider_config.zone
          zone_config = env[:machine].provider_config.get_zone_config(zone)
          if not env[:result] and !zone_config.name.nil?
            begin
              server = env[:google_compute].servers.get(zone_config.name, zone)
              if !server.nil? and [:STOPPING, :TERMINATED].include?(server.state.to_sym)
                env[:ui].info("Waiting for already terminating instance...")
                server.wait_for { ![:STOPPING, :TERMINATED].include?(server.state.to_sym) }
              end
            rescue Exception => e
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
