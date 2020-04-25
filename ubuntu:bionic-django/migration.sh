#!/bin/sh

set -ex

su - app <<EOF
source $HOME/venv/bin/activate
cd blog/src
python manage.py migrate
&& echo -e "from django.contrib.contenttypes.models import ContentType\nContentType.objects.all().delete()\n" | python manage.py shell \
&& python manage.py loaddata db.json
EOF

exit 0
