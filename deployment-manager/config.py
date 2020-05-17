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
"""
This template creates a Runtime Configurator with the associated resources.
"""


def generate_config(context):
    """ Entry point for the deployment resources. """

    resources = []
    properties = context.properties
    project_id = properties.get('projectId', context.env['project'])
    name = properties.get('config', context.env['name'])

    properties['postgres']['image'] = 'gcr.io/{}/{}'.format(project_id, \
                                            properties['postgres']['image'])
    properties['worker']['image'] = 'gcr.io/{}/{}'.format(project_id, \
                                            properties['worker']['image'])
    properties['webserver']['image'] = 'gcr.io/{}/{}'.format(project_id, \
                                            properties['webserver']['image'])

    outputs = [
        { 'name': 'region', 'value': properties['region'] },
        { 'name': 'zone', 'value': properties['zone'] },
        { 'name': 'postgres', 'value': properties['postgres'] },
        { 'name': 'worker', 'value': properties['worker'] },
        { 'name': 'webserver', 'value': properties['webserver'] }
    ]

    return {'resources': resources, 'outputs': outputs}
