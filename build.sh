git submodule init
git submodule update
docker build --no-cache -t normannovaes/ipsum --platform linux/amd64 -f Dockerfile .
docker push normannovaes/ipsum