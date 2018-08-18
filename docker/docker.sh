#!/bin/bash

abspath=$(cd $(dirname $0) && pwd)
prog=$(basename $abspath)
now=`date +%Y-%m-%d\ %H:%M:%S`

homedir=$abspath
logdir=/var/log/$prog

RETVAL=0

cd $abspath

update_yml() {
cat << EOS > ./docker-compose.yml
# build at $now
# !!! do not edit !!! Please look at docker.sh

version: "3"
services:
  nuxt:
    build: nuxt
    privileged: true
    volumes:
      - "$homedir/nuxt/app:/usr/local/nginx/html"
    ports:
      - 80:80
      - 3000:3000
    container_name: nuxt

EOS
}

case "$1" in
  up) # build & run
    update_yml
    docker-compose up -d
    ;;
  down)
    docker-compose down
    ;;
  start)
    docker-compose start
    ;;
  stop)
    docker-compose stop
    ;;
  rm)
    docker-compose rm
    ;;
  build)
    update_yml
    docker-compose build
    ;;
  rebuild)
    update_yml
    docker-compose build --no-cache
    ;;
  ps)
    docker-compose ps
    ;;
  exec)
    [ $2 ] && service=$2 || service=app
    docker-compose exec $service bash
    ;;
  *)
    echo $"Usage: $prog {up|down|start|stop|rm|build|rebuild|ps|exec}"
    RETVAL=2
esac

exit $RETVAL
