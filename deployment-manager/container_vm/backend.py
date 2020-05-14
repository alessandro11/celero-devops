# Copyright 2016 Google Inc. All rights reserved.
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

"""Create nodejs template with the back-end and front-end templates."""


def GenerateConfig(context):
  """Generate configuration."""

  backend = context.env['deployment'] + '-backend'
  postgres_port = 5432
  resources = [{
      'name': 'backend',
      'type': 'container_vm.py',
      'properties': {
          'startup-script': context.properties['startup-script'],
          'deviceName': context.properties['deviceName'],
          'zone': context.properties['zone'],
          'dockerImage': context.properties['dockerImage'],
          'containerImage': 'family/cos-stable',
          'port': postgres_port,
          'dockerEnv': {
              'POSTGRES_PASSWORD_FILE': '/var/lib/postgresql/.postgres_pass',
              'BLOG_PASSWORD': 'bIhJ6ekK$FxCKJTn0Wg47z'
          }
      }
  }]
  return {'resources': resources}
