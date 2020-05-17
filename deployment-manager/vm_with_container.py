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

"""Creates a Container VM with the provided Container manifest."""

from container_helper import GenerateManifest

COMPUTE_URL_BASE = 'https://www.googleapis.com/compute/v1/'


def GlobalComputeUrl(project, collection, name):
  return ''.join([COMPUTE_URL_BASE, 'projects/', project,
                  '/global/', collection, '/', name])


def ZonalComputeUrl(project, zone, collection, name):
  return ''.join([COMPUTE_URL_BASE, 'projects/', project,
                  '/zones/', zone, '/', collection, '/', name])


def GenerateConfig(context):
  """Generate configuration."""

  base_name = context.env['name']

  # Properties for the container-based instance.
  instance = {
      'zone': context.properties['zone'],
      'machineType': ZonalComputeUrl(context.env['project'],
                                     context.properties['zone'],
                                     'machineTypes',
                                     context.properties['machineType']),
      'metadata': {
        'items': [{
          'key': 'gce-container-declaration',
          'value': GenerateManifest(context)
        }]
      },
      'disks': [{
        'deviceName': 'boot',
        'type': 'PERSISTENT',
        'autoDelete': True,
        'boot': True,
        'initializeParams': {
          'diskName': base_name + '-disk',
          'sourceImage': GlobalComputeUrl('cos-cloud', 'images', 'family/cos-stable')
        }
      }],
      'networkInterfaces': [{
        'accessConfigs': [{
          'name': 'external-nat',
          'type': 'ONE_TO_ONE_NAT',
        }],
        'subnetwork': context.properties['subnet'],
        'networkIP': context.properties['internalIP']
      }],
      'serviceAccounts': [{
        'email': 'default',
        'scopes': ['https://www.googleapis.com/auth/logging.write',
                   'https://www.googleapis.com/auth/cloud-platform',
                   'https://www.googleapis.com/auth/compute'
        ]
      }]
  }

  if 'externalIP' in context.properties:
    instance['networkInterfaces'][0]['accessConfigs'][0]['natIP'] = \
       context.properties['externalIP']

  if 'startup-script' in context.properties:
    instance['metadata']['items'].append({
      'key': 'startup-script',
      'value': context.properties['startup-script']
    })

  if 'disks' in context.properties:
    instance['disks'].append({
      'deviceName': context.properties['disks'][0]['deviceName'],
      'type': 'PERSISTENT',
      'autoDelete': False,
      'boot': False,
      'source': context.properties['disks'][0]['diskResource']
    })

  # Resources to return.
  resources = {
    'resources': [{
      'name': base_name,
      'type': 'compute.v1.instance',
      'properties': instance
    }]
  }

  return resources
