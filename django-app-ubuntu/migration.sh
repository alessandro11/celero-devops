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
&& python manage.py loaddata db.json; \
/home/app/blog/src/manage.py collectstatic --noinput --pythonpath /home/app/blog/src,/home/app/venv/lib,/home/app/venv/lib64
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
&& python manage.py loaddata db.json; \
/home/app/blog/src/manage.py collectstatic --noinput --pythonpath /home/app/blog/src,/home/app/venv/lib,/home/app/venv/lib64

exit $?
