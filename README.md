# swarm-setting
[Docker swarm](https://docs.docker.com/engine/swarm/) development environment for customized medical study app.

## Intall docker-machine
[docker-machine](https://docs.docker.com/machine/overview/)을 활용하여 [docker](https://www.docker.com/what-docker)가 설치된 클라우드 컴퓨터를 쉽게 생성할 수 있다.

```shell
base=https://github.com/docker/machine/releases/download/v0.15.0 &&
curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
sudo install /tmp/docker-machine /usr/local/bin/docker-machine
docker-machine version
```


## 클라우드 생성 : DigitalOcean

[DigitalOcean](https://www.digitalocean.com/) 은 상대적으로 저렴한 클라우스 서비스 업체이다. 매니저 노드와 워쿼 노드를 각 1개씩 생성해 보겠다(`manager1`, `worker1`). 만든 후에는 기본으로 `js`유저를
생성하겠다(password: `js`).

```shell
export DIGITALOCEAN_ACCESS_TOKEN=<YOUR_DIGITALOCEAN_ACCESS_TOKEN>
export DIGITALOCEAN_IMAGE="ubuntu-18-04-x64"
export DIGITALOCEAN_REGION="sgp1"
echo "### Creating manager nodes ..."

for c in {1..1} ; do
  docker-machine create \
     --driver digitalocean \
     --digitalocean-access-token $DIGITALOCEAN_ACCESS_TOKEN \
     --digitalocean-image $DIGITALOCEAN_IMAGE \
     --digitalocean-region $DIGITALOCEAN_REGION \
     --digitalocean-size "s-2vcpu-4gb" \
     manager$c &&\
  docker-machine ssh manager$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done

export DIGITALOCEAN_SIZE="s-1vcpu-1gb"
echo "### Creating worker nodes ..."
for c in {1..1} ; do
    docker-machine create \
  --driver digitalocean \
  --digitalocean-access-token $DIGITALOCEAN_ACCESS_TOKEN \
  --digitalocean-image $DIGITALOCEAN_IMAGE \
  --digitalocean-region $DIGITALOCEAN_REGION \
  --digitalocean-size $DIGITALOCEAN_SIZE \
  worker$c && \
  docker-machine ssh worker$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done
```

## 스윔 클러스터 생성 

`manager1` 과 `worker1` 서버를 [docker swarm](https://docs.docker.com/engine/swarm/)를 활용하여 묶자. 

```shell
# Get IP from leader node
leader_ip=$(docker-machine ip manager1)

# Init Docker Swarm mode
echo "### Initializing Swarm mode ..."
eval $(docker-machine env manager1)
docker swarm init --advertise-addr $leader_ip

# Swarm tokens
manager_token=$(docker swarm join-token manager -q)
worker_token=$(docker swarm join-token worker -q)

# Joinig manager nodes
echo "### Joining manager modes ..."
for c in {1..1} ; do
    eval $(docker-machine env manager$c)
    docker swarm join --token $manager_token $leader_ip:2377
done

# Join worker nodes
echo "### Joining worker modes ..."
for c in {1..1} ; do
    eval $(docker-machine env worker$c)
    docker swarm join --token $worker_token $leader_ip:2377
done


# Clean Docker client environment
echo "### Cleaning Docker client environment ..."
eval $(docker-machine env -u)
```


## Service 

### Traefik
[Traefik](https://traefik.io/)은 스웜환경에 적합한 `reverse-proxy` 프로그램으로 이를 활용해서 생성된 서비스를 `subdomain` 주소로 불러올 수 있다. 또한  [Let's Encrypt](https://docs.traefik.io/configuration/acme/)을 지원하여 `https` 보안이 된 서비스를 생성할 수 있다. 


```shell
eval $(docker-machine env manager1)
DOMAINNAME="anpanman.co.kr"

# Create network for swarm
docker network create --driver=overlay traefik-net

# For Let's Encrypt
docker-machine ssh manager1 "DOMAINNAME=anpanman.co.kr && \ 
                             mkdir /home/js/opt && \ 
                             mkdir /home/js/opt/traefik && \
                             cd /home/js/opt/traefik && \
                             touch acme.json && chmod 600 acme.json && \
                             wget -O traefik.toml  https://raw.githubusercontent.com/jinseob2kim/swarm-setting/master/opt/traefik/traefik.toml"
                             
                             
# Create traefik service
docker service create \
    --name traefik \
    --constraint=node.role==manager \
    --publish 80:80 --publish 443:443\
    --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
    --mount type=bind,source=/root/acme.json,target=/acme.json \
    --mount type=bind,source=/root/traefik.toml,target=/traefik.toml \
    -e DO_AUTH_TOKEN=$DIGITALOCEAN_ACCESS_TOKEN \
    -l traefik.port=8080 \
    -l traefik.frontend.rule=Host:traefik.$DOMAINNAME\
    --network traefik-net \
    traefik \
    --logLevel=INFO \
    --docker \
    --docker.swarmMode \
    --docker.watch \
    --docker.domain=$DOMAINNAME
```

https://traefik.anpanman.co.kr 에서 dashboard를 볼 수 있다.

### Nginx
```shell
docker service create \
    --name nginx \
    --label traefik.port=80 \
    --label traefik.frontend.rule="Host:${DOMAINNAME},www.${DOMAINNAME}" 
    --network traefik-net \
    nginx 
```
https://anpanman.co.kr, https://www.anpanman.co.kr 에서 `nginx` 실행환경을 볼 수 있다. 


### Rstudio & shiny server

자체적으로 이미지 [docker-rshiny](https://hub.docker.com/r/jinseob2kim/docker-rshiny/) 를 만들어 사용하였다.

```shell
docker service create \
    --name rshiny \
    --label traefik.shiny.port=3838 \
    --label traefik.rstudio.port=8787 \
    --label traefik.shiny.frontend.rule="Host:shiny.anpanman.co.kr" \
    --label traefik.rstudio.frontend.rule="Host:rstudio.anpanman.co.kr" \
    -e PASSWORD=js -e ROOT=TRUE \
    --mount=type=bind,src=/home/js,dst=/home/rstudio \
    --network traefik-net \
     jinseob2kim/docker-rshiny
```
https://rstudio.anpanman.co.kr 에서 'rstudio server'를, https://shiny.anpanman.co.kr 에서 'shiny server'를 실행할 수 있다. 


### Viz

[Docker swarm](https://docs.docker.com/engine/swarm/) 클러스터링 현황을 볼 수 있는 서비스이다.

```shell
docker service create \
    --name viz \ 
    --label traefik.port=8080 \
    --constraint=node.role==manager \
    --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    --network traefik-net \
    dockersamples/visualizer
```

서비스는 특별한 옵션(`traefik.frontend.rule`)이 없으면  `<서비스 이름>.<DOMAIN 이름>` 주소로 생성되며 `viz`는 https://viz.anpanman.co.kr 으로 실행 가능하다. 


### Jupyter notebook(tensorflow) | jupyterhub

[jupyterhub](https://github.com/jupyterhub/jupyterhub)은 멀티 유저를 지원한다.

```shell
docker service create \
    --name tf \
    --label traefik.port=8888 \ 
    --network traefik-net \
    tensorflow/tensorflow

docker service create \
    --name jupyterhub \
    --label traefik.port=8000 \
    --network traefik-net \
    jupyterhub/jupyterhub
```

앞서와 마찬가지로 https://tf.anpanman.co.kr, https://jupyterhub.anpanman.co.kr 으로 접속하면 된다. 

## Uninstall docker-machine

등록되어 있는 docker-machine node를 삭제한 후 프로그램을 삭제한다.

```shell
docker-machine rm -f $(docker-machine ls -q)
rm $(which docker-machine)
```


## 타 클라우드 서비스 

### AWS

```shell
export AWS_ACCESS_KEY_ID=<YOUR_AWS_ACEESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY>
export AWS_INSTANCE_TYPE="t2.micro" 
export AWS_INSTANCE_REGION="ap-northeast-2"
export AWS_SECURITY_GROUP="launch-wizard-2"
export AWS_VPC_ID=<YOUR_AWS_VPC_ID>
export AWS_ZONE=c


for c in {1..1} ; do
docker-machine create \
  --driver amazonec2 \
  --amazonec2-access-key $AWS_ACCESS_KEY_ID \
  --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
  --amazonec2-region $AWS_INSTANCE_REGION \
  --amazonec2-vpc-id $AWS_VPC_ID \
  --amazonec2-open-port 3838 \
  --amazonec2-open-port 8787 \
  --amazonec2-open-port 8000 \
  --amazonec2-open-port 8080 \
  --amazonec2-open-port 2377 \
  --amazonec2-open-port 7946 \
  --amazonec2-open-port 7946/udp \
  --amazonec2-open-port 4789 \
  --amazonec2-open-port 4789/udp \
  --amazonec2-open-port 8888 \
  --amazonec2-open-port 80 \
  --amazonec2-open-port 443 \
  manager$c && \
  docker-machine ssh manager$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done

for c in {1..1} ; do
docker-machine create \
  --driver amazonec2 \
  --amazonec2-access-key $AWS_ACCESS_KEY_ID \
  --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY \
  --amazonec2-region $AWS_INSTANCE_REGION \
  --amazonec2-vpc-id $AWS_VPC_ID \
  --amazonec2-open-port 3838 \
  --amazonec2-open-port 8787 \
  --amazonec2-open-port 8000 \
  --amazonec2-open-port 8080 \
  --amazonec2-open-port 2377 \
  --amazonec2-open-port 7946 \
  --amazonec2-open-port 7946/udp \
  --amazonec2-open-port 4789 \
  --amazonec2-open-port 4789/udp \
  --amazonec2-open-port 8888 \
  --amazonec2-open-port 80 \
  --amazonec2-open-port 443 \
  worker$c && \
  docker-machine ssh worker$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done
```

### AZURE

```shell
export sub=<YOUR_AZURE_SUBSCRIPTION_VALUE>

for c in {1..1} ; do
docker-machine create \
    --driver azure \
    --azure-location "koreacentral" \
    --azure-size Standard_B1s \
    --azure-subscription-id $sub \
    --azure-open-port 3838 \
    --azure-open-port 8787 \
    --azure-open-port 8000 \
    --azure-open-port 8080 \
    --azure-open-port 2377 \
    --azure-open-port 7946 \
    --azure-open-port 7946/udp \
    --azure-open-port 4789 \
    --azure-open-port 4789/udp \
    --azure-open-port 8888 \
    --azure-open-port 80 \
    --azure-open-port 443 \
    manager$c && \
    docker-machine ssh manager$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done

for c in {1..1} ; do
docker-machine create \
    --driver azure \
    --azure-location "koreacentral" \
    --azure-size Standard_B1s \
    --azure-subscription-id $sub \
    --azure-open-port 3838 \
    --azure-open-port 8787 \
    --azure-open-port 8000 \
    --azure-open-port 8080 \
    --azure-open-port 2377 \
    --azure-open-port 7946 \
    --azure-open-port 7946/udp \
    --azure-open-port 4789 \
    --azure-open-port 4789/udp \
    --azure-open-port 8888 \
    --azure-open-port 80 \
    --azure-open-port 443 \
    worker$c && \
    docker-machine ssh worker$c "adduser js --gecos 'First Last,RoomNumber,WorkPhone,HomePhone' --disabled-password && sh -c 'echo js:js | sudo chpasswd' && usermod -aG sudo js"
done
```


