# Copyright 2018 Google Inc. All rights reserved.
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
"""Creates a network and its subnetworks."""


def GenerateConfig(context):
    """Generates config."""

    network_name = context.env['name']

    resources = [{
        'name': network_name,
        'type': 'compute.v1.network',
        'properties': {
            'name': network_name,
            'autoCreateSubnetworks': False,
        }
    }]

    for subnetwork in context.properties['subnetworks']:
        resources.append({
            'name': '{}-{}'.format(network_name, subnetwork['region']),
            'type': 'compute.v1.subnetwork',
            'properties': {
                'name': '{}-{}'.format(network_name, subnetwork['region']),
                'description': 'Subnetwork of {} in {}'.format(network_name,
                                                           subnetwork['region']),
                'ipCidrRange': subnetwork['cidr'],
                'region': subnetwork['region'],
                'network': '$(ref.{}.selfLink)'.format(network_name),
            },
            'metadata': {
                'dependsOn': [
                    network_name,
                ]
            }
        })

    outputs = [{
        'name': 'subnet',
        'value': '$(ref.{}-{}.selfLink)'.format(network_name, subnetwork['region'])
    }, {
        'name': 'selfLink',
        'value': '$(ref.{}.selfLink)'.format(network_name)
    }, {
        'name': 'region', 'value': context.properties['subnetworks'][0]['region']
    }]

    return { 'resources': resources, 'outputs': outputs }
