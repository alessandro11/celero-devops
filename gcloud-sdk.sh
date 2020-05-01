#!/bin/bash

exit 1
#
# Este script é somente para documentar o que fiz
# aqui eu compilei todas as linhas de comandos que executaram com sucesso
# para fazer o deploy para o GCP
#

gcloud compute networks create vpc-celero --subnet-mode=custom --bgp-routing-mode=regional
gcloud compute networks subnets create webserver --network vpc-celero \
       --range 10.128.0.0/16 --secondary-range container-range=172.16.0.0/20

gcloud compute addresses create postgres-global --region southamerica-east1
gcloud compute addresses create postgres \
       --region southamerica-east1 --subnet webserver --addresses 10.128.0.200

gcloud compute addresses create nginx-global --region southamerica-east1
gcloud compute addresses create nginx \
       --region southamerica-east1 --subnet webserver --addresses 10.128.0.100

gcloud compute addresses create blog1 blog2 blog3 \
       --region southamerica-east1 --subnet webserver --addresses 10.128.0.10,10.128.0.11,10.128.0.12


gcloud compute firewall-rules create allow-ssh --network vpc-celero --allow tcp:22 --priority 1000
gcloud compute firewall-rules create allow-postgres --network vpc-celero --allow tcp:5432 --priority 50 --source-range 10.128.0.0/16 --target-tags allow-postgres
gcloud compute firewall-rules create celero-http-server --network vpc-celero --allow tcp:80 --priority 1000 --target-tags http-server
gcloud compute firewall-rules create http-server --network vpc-celero --allow tcp:443 --priority 10 --destination-ranges 35.247.200.44/32

gcloud compute disks create storage-postgresql --description "Makes de PGDATA persistent" --type pd-standard --size 10G --zone=southamerica-east1-a


gcloud compute instances create-with-container postgres \
       --container-image gcr.io/celerodevops/postgres-12.2-alpine-3.11:blog-0.0.5 \
       --container-env 'POSTGRES_PASSWORD_FILE=/var/lib/postgresql/.postgres_pass,BLOG_PASSWORD=bIhJ6ekK$FxCKJTn0Wg47z' \
       --container-mount-host-path 'host-path=/mnt/disks/storage-postgresql/data,mount-path=/var/lib/postgresql/data,mode=rw' \
       --container-restart-policy on-failure \
       --tags allow-postgres \
       --description 'Instance that handle PostgreSQL from persistent disk' \
       --machine-type n1-standard-2 \
       --network-interface 'address=postgres-global,network=vpc-celero,subnet=webserver,private-network-ip=postgres,aliases=container-range:172.16.0.0/24' \
       --disk name=storage-postgresql,auto-delete=no,device-name=storage-postgresql,mode=rw \
       --metadata '^:^startup-script=#!/bin/bash
if ! blkid /dev/disk/by-id/google-storage-postgresql &>/dev/null; then
   mkfs.ext4 -L storage-postgresql -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-storage-postgresql;
fi

fsck.ext4 -tvy /dev/disk/by-id/google-storage-postgresql \
&& mkdir -p /mnt/disks/storage-postgresql \
&& mount -t ext4 -o discard,defaults /dev/disk/by-id/google-storage-postgresql /mnt/disks/storage-postgresql
[ ! -d "/mnt/disks/storage-postgresql/data" ] && mkdir "/mnt/disks/storage-postgresql/data"
'


gcloud compute instances create-with-container blog1 \
       --container-image gcr.io/celerodevops/ubuntu-18.04.4-lts:blog-0.0.4 \
       --container-env 'DB_PASSWD=bIhJ6ekK$FxCKJTn0Wg47z,DB_SERVER=10.128.0.200' \
       --container-restart-policy on-failure \
       --tags allow-worker \
       --machine-type n1-standard-1 \
       --description 'Worker for application blog' \
       --network-interface 'subnet=webserver,private-network-ip=blog1,aliases=container-range:172.16.1.0/24'

gcloud compute instances create-with-container blog2 \
       --container-image gcr.io/celerodevops/ubuntu-18.04.4-lts:blog-0.0.4 \
       --container-env 'DB_PASSWD=bIhJ6ekK$FxCKJTn0Wg47z,DB_SERVER=10.128.0.200' \
       --container-restart-policy on-failure \
       --tags blog-worker \
       --machine-tgype n1-standard-1 \
       --description 'Worker for application blog' \
       --network-interface 'subnet=webserver,private-network-ip=blog2,aliases=container-range:172.16.2.0/24'

gcloud compute instances create-with-container blog3 \
       --container-image gcr.io/celerodevops/ubuntu-18.04.4-lts:blog-0.0.4 \
       --container-env 'DB_PASSWD=bIhJ6ekK$FxCKJTn0Wg47z,DB_SERVER=10.128.0.200' \
       --container-restart-policy on-failure \
       --tags blog-worker \
       --machine-type n1-standard-1 \
       --description 'Worker for application blog' \
       --network-interface 'subnet=webserver,private-network-ip=blog3,aliases=container-range:172.16.3.0/24'

gcloud compute instances create-with-container nginx \
       --container-image gcr.io/celerodevops/ngix-alpine-3.11:blog-0.0.7 \
       --container-env '^:^SERVER_NAME=blog.celero.com:SERVERS=10.128.0.10,10.128.0.11' \
       --container-restart-policy on-failure \
       --tags http-server \
       --machine-type n1-standard-1 \
       --description 'Web server front end' \
       --network-interface 'address=nginx-global,network=vpc-celero,subnet=webserver,private-network-ip=nginx,aliases=container-range:172.16.4.0/24'



