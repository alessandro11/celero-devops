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

COMPUTE_URL_BASE = 'https://www.googleapis.com/compute/v1/'


def GenerateConfig(context):
  """Creates configuration."""

  resources = []
  project = context.env['project']

  # create disks resources
  for disk_obj in context.properties['disks']:
    resources.append({'name': disk_obj['name'],
                      'type': 'compute.v1.disk',
                      'properties': {
                          'zone': context.properties['zone'],
                          'sizeGb': str(disk_obj['sizeGb']),
                          'type': ''.join([COMPUTE_URL_BASE,
                                           'projects/', project, '/zones/',
                                           context.properties['zone'],
                                           '/diskTypes/', disk_obj['diskType']])
                      }
                     })
  return {'resources': resources}
