#!/bin/sh

set -e

perr() {
	echo "$@" 1>&2
}

run_as_root() {
    su - app <<EOM
. \$HOME/.venv/bin/activate
cd \$HOME/blog/src
python manage.py migrate \
&& echo -e "from django.contrib.contenttypes.models import ContentType\nContentType.objects.all().delete()\n" | python manage.py shell \
&& python manage.py loaddata db.json
EOM

    exit $?
}

UID=`id -u`
if [ $UID -eq 0 ]; then
    run_as_root
fi

. $HOME/.venv/bin/activate
cd $HOME/blog/src
python manage.py migrate \
&& echo "from django.contrib.contenttypes.models import ContentType\nContentType.objects.all().delete()\n" | python manage.py shell \
&& python manage.py loaddata db.json

exit $?
