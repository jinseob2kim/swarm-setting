---
title: "맞춤형 의학연구 애플리케이션을 위한 개발 환경 구축"
author: "Jinseob Kim"
date: "October 26, 2018"
output:
  slidy_presentation: 
    df_print: paged
    duration: 40
    fig_caption: yes
    fig_height: 6
    fig_width: 7
    font_adjustment: 2
    footer: '&copy;2018 ANPANMAN Co.,Ltd. All rights reserved.'
    highlight: tango
    keep_md: yes
    theme: readable
subtitle: ANPANMAN Co.,Ltd.
editor_options:
  chunk_output_type: console
---






# Executive Summary 


맞춤형 의학연구 애플리케이션을 위해


1. **마이크로서비스 아키텍처**(microservice architecture) 구축

    + `Rstudio`와 `shiny server`가 설치된 [Docker](https://www.docker.com/what-docker) 이미지 제작
    
    + [Docker swarm](https://docs.docker.com/engine/swarm/)을 이용해 배포
    
    + 서버의 종류와 갯수에 구애받지 않음


2. **https** 보안이 적용된 **subdomain 주소** 부여 

    + 동적 프록시 서버(dynamic proxy server) 프로그램인 [Traefik](https://traefik.io/) 이용
    
    
    + 서비스가 추가될 때 마다(ex: 홈페이지, Jupyter) 자동 적용.
    

3. `ShinyApps`

    + 흔히 이용되는 의학통계 방법들을 `ShinyApps` 로 만들어 위의 환경에 배포
    
    
    + **데이터 라벨(label) 정보** 활용 - 라벨이 적용된 논문용 테이블/그림 
    


# 1. 마이크로서비스 아키텍처 

# 

<img src="https://blog.philipphauer.de/blog/2015/0411-microservices-nutshell-pros-cons/Monolith-vs-Microservices.png" width="40%" style="display: block; margin: auto;" />

<div class="figure" style="text-align: center">
<img src="https://blog.philipphauer.de/blog/2015/0411-microservices-nutshell-pros-cons/Scaling-Microservices.png" alt="https://blog.philipphauer.de/microservices-nutshell-pros-cons/" width="60%" />
<p class="caption">https://blog.philipphauer.de/microservices-nutshell-pros-cons/</p>
</div>



# 여행용 파우치 

<div class="figure" style="text-align: center">
<img src="https://funshop.akamaized.net/products/0000045775/HF-INLUGGAGE-POUCH-LINGERIE-%EC%83%81%EC%84%B8%ED%8E%98%EC%9D%B4%EC%A7%80_01.jpg" alt="https://funshop.akamaized.net/products/0000045775/HF-INLUGGAGE-POUCH-LINGERIE-%EC%83%81%EC%84%B8%ED%8E%98%EC%9D%B4%EC%A7%80_01.jpg" width="60%" />
<p class="caption">https://funshop.akamaized.net/products/0000045775/HF-INLUGGAGE-POUCH-LINGERIE-%EC%83%81%EC%84%B8%ED%8E%98%EC%9D%B4%EC%A7%80_01.jpg</p>
</div>



# 여행용 파우치 장단점

장점

1. **깔끔하다.**

2. 치우기 쉽다. 

3. 다른 가방으로 옮기기 쉽다. 

4. 가방 종류에 구애받지 않는다.


단점

1. 실제 쓸 수 있는 공간이 줄어든다. 

2. 분리해서 넣기 귀찮다. 

3. 물건 찾을 때 지퍼를 한번 더 열어야 된다. 



# Microservice 장단점

장점

1. **깔끔하다.**

2. 삭제가 쉽다. 

3. 다른 컴퓨터에 재설치 쉽다.

4. 컴퓨터/서버 종류에 구애받지 않는다. 


단점

1. 실제 쓸 수 있는 용량이 줄어든다. 

2. 서비스마다 모듈 만들기 귀찮다. 

3. 성능저하 우려 


**가상머신(Virtual machine)** 활용이 대표적.  


# [Docker](https://www.docker.com/what-docker)

- 빠르고 용량이 적은 가상머신?
- [Docker hub](https://hub.docker.com/)을 통해 [github](https://github.com/)처럼 이용가능.  
    + [github](https://github.com/)과 연계 가능 
    + [github](https://github.com/)에 이미지 제작 코드 저장하면 [Docker hub](https://hub.docker.com/)에 실제 이미지가 저장


<div class="figure" style="text-align: center">
<img src="https://journals.plos.org/plosone/article/figure/image?size=large&id=10.1371/journal.pone.0152686.g002" alt="https://doi.org/10.1371/journal.pone.0152686" width="60%" />
<p class="caption">https://doi.org/10.1371/journal.pone.0152686</p>
</div>


# [Docker hub](https://hub.docker.com/) 활용 예

<div class="figure" style="text-align: center">
<img src="http://edu.delestra.com/docker-slides/img/docker_hub_auto_build.png" alt="http://edu.delestra.com/docker-slides/img/docker_hub_auto_build.png" width="70%" />
<p class="caption">http://edu.delestra.com/docker-slides/img/docker_hub_auto_build.png</p>
</div>

- [rshiny docker image](https://hub.docker.com/r/jinseob2kim/docker-rshiny/)


- [rshiny github](https://github.com/jinseob2kim/docker-rshiny)



# rshiny DockerFile

```bash
FROM ubuntu:latest

RUN sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list  && \
    sed -i 's/extras.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list

MAINTAINER Jinseob Kim "jinseob2kim@gmail.com"

# Setup apt to be happy with no console input
ENV DEBIAN_FRONTEND noninteractive


# Install dependencies and Download 
RUN apt-get update && apt-get install -y \
    udev \
    locales \
    software-properties-common \
    file \
    curl \
    git \
    sudo \
    wget \
    gdebi-core \
    vim \
    psmisc \
    tzdata \
    libxml2-dev \
    libcairo2-dev \
    libgit2-dev \
    tk-table \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxt-dev \
    supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Prevent bugging us later about timezones
RUN ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Use UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8


# Update R -latest version
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu bionic-cran35/" | sudo tee -a /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | sudo apt-key add - && \
    apt-get update && \
    apt-get install -y r-base r-base-dev

# Install Rstudio-server
ARG RSTUDIO_VERSION

RUN RSTUDIO_LATEST=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) && \ 
    [ -z "$RSTUDIO_VERSION" ] && RSTUDIO_VERSION=$RSTUDIO_LATEST || true && \
    wget -q http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb && \
    dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb && \
    rm rstudio-server-*-amd64.deb 


# Install Shiny server
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-14.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown', 'DT', 'data.table', 'ggplot2', 'devtools', 'epiDisplay', 'tableone', 'svglite', 'plotROC', 'pROC', 'labelled', 'geepack', 'lme4', 'PredictABEL', 'shinythemes', 'maxstat', 'manhattanly', 'Cairo', 'future', 'promises', 'GGally', 'fst', 'blogdown', 'metafor', 'roxygen2'), repos='https://cran.rstudio.com/')" && \
    R -e "devtools::install_github(c('jinseob2kim/jstable', 'jinseob2kim/jskm', 'emitanaka/shinycustomloader', 'Appsilon/shiny.i18n', 'metrumresearchgroup/sinew'))" 
    


## User setting
COPY ini.sh /etc/ini.sh


## Github
RUN git config --system credential.helper 'cache --timeout=3600' && \ 
    git config --system push.default simple 


## Multiple run
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor \
	&& chmod 777 -R /var/log/supervisor


EXPOSE 8787 3838 


CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 
```


# [Rocker project](https://www.rocker-project.org/)

- `R` [Docker](https://www.docker.com/what-docker) image 모음.  

<div class="figure" style="text-align: center">
<img src="rocker.png" alt="https://www.rocker-project.org/images/" width="80%" />
<p class="caption">https://www.rocker-project.org/images/</p>
</div>

- `shiny server` 의 한글 지원 문제로 자체 이미지 제작 결정. 



# 개발환경 구축 컨셉 

- 데이터: 로컬 컴퓨터, 개인 클라우드(ex: [드롭박스](https://www.dropbox.com), [S3](https://aws.amazon.com/ko/s3))

- 코드: [github](https://github.com/)

- 프로그램: [Docker hub](https://hub.docker.com/) 

- 서버: 클라우드([AWS](https://aws.amazon.com/), [Azure](https://azure.microsoft.com/ko-kr/), [Digital ocean](https://www.digitalocean.com/)) or 자체 서버



# [Docker](https://www.docker.com/what-docker) 이미지 실행

```bash
docker run --rm -d \ 
    -p 3838:3838 -p 8787:8787 \
    -e USER=js -e PASSWORD=js -e ROOT=TRUE\
    jinseob2kim/docker-rshiny
```

- **--rm -d** : 실행 중지시 지움(--rm), 백그라운드 실행(-d)


- 호스트의 **3838**포트를 이미지의 **3838**포트(`shiny server`)와 연결,  **8787**포트를 **8787**포트(`rstudio server`)에 연결


- 유저 생성 : **js/js, 루트 권한**


- [Docker hub](https://hub.docker.com/) 주소 : **jinseob2kim/docker-rshiny**


로컬 컴퓨터 -  http://localhost:8787, http://localhost:3838 로 접속. 서버 - **Your IP**:8787, **Your IP**:3838



# 서버의 갯수?

> 서버의 **종류와 갯수**에 구애받지 않는  **마이크로서비스 아키텍처**(microservice architecture)...

- 윈도우 서버, 맥에서도 [Docker](https://www.docker.com/what-docker) 설치하고 이미지 실행 가능.

- 서버 **갯수에 구애받지 않는다?** [Docker](https://www.docker.com/what-docker) 만으로는 불가능. 

<div class="figure" style="text-align: center">
<img src="https://www.penflip.com/akira.ohio/appcatalyst-hands-on-lab-en/blob/master/images/docker-ppt-swarm-1.png/?raw=true" alt="https://www.penflip.com/akira.ohio/appcatalyst-hands-on-lab-en/blob/master/images/docker-ppt-swarm-1.png/?raw=true" width="70%" />
<p class="caption">https://www.penflip.com/akira.ohio/appcatalyst-hands-on-lab-en/blob/master/images/docker-ppt-swarm-1.png/?raw=true</p>
</div>



# [Docker swarm](https://docs.docker.com/engine/swarm/) 

- **Server orchestration**: 지휘자가 오케스트라 연주하듯이

- 여러대의 서버를 묶어 **마치 하나의 서버**를 이용하는 것처럼 느낌. 

- [Docker](https://www.docker.com/what-docker) 에 내장되어 별다른 설치 필요없음. 

- 비슷한 프로그램으로 구글의 [Kubernetes](https://kubernetes.io/)

<div class="figure" style="text-align: center">
<img src="https://www.upcloud.com/support/wp-content/uploads/2016/10/Docker-Swarm-Orchestration-1024x265.png" alt="https://www.upcloud.com/support/docker-swarm-orchestration/" width="70%" />
<p class="caption">https://www.upcloud.com/support/docker-swarm-orchestration/</p>
</div>


# 과정 

1. 서버들에 [Docker](https://www.docker.com/what-docker) 설치

2. 서버들을 묶음: **manager** 서버와 **worker** 서버.

3. **manager** 서버에서 [Docker](https://www.docker.com/what-docker) 이미지를 실행하면 자동으로 한가한 서버에 배치. 

4. 어떤 서버 주소로 접속해도 실행 가능. 
    + **manager IP**:8787, **worker IP**:8787 모두 OK
    


# Manager & worker node

<div class="figure" style="text-align: center">
<img src="https://pbs.twimg.com/media/DP5VZC8UIAAnV6j.jpg:large" alt="https://pbs.twimg.com/media/DP5VZC8UIAAnV6j.jpg:large" width="50%" />
<p class="caption">https://pbs.twimg.com/media/DP5VZC8UIAAnV6j.jpg:large</p>
</div>


# 어떤 IP로 접속해도 실행 가능

<div class="figure" style="text-align: center">
<img src="http://callistaenterprise.se/assets/blogg/docker/docker-in-swarm-mode-on-docker-in-docker/docker-swarm.png" alt="http://callistaenterprise.se/assets/blogg/docker/docker-in-swarm-mode-on-docker-in-docker/docker-swarm.png" width="50%" />
<p class="caption">http://callistaenterprise.se/assets/blogg/docker/docker-in-swarm-mode-on-docker-in-docker/docker-swarm.png</p>
</div>
  

# 예: [Docker swarm](https://docs.docker.com/engine/swarm/) 으로 서버 2개 묶기

> [Docker](https://www.docker.com/what-docker)가 설치된 2개 서버: **manager, worker** node 

In **manager** node

1. Init Docker Swarm mode

```bash
manger_ip = $(123.456.789.10)
docker swarm init --advertise-addr $manager_ip
```



2. Get Swarm tokens

```bash
worker_token=$(docker swarm join-token worker -q)
```


In **worker** node

3. Join worker nodes

```bash
docker swarm join --token $worker_token $manager_ip:2377
````


https://www.youtube.com/watch?v=2RQbpnRxx-Y




# 주의 (1) - Port setting for swarm 

- TCP port **2377** for cluster management & raft sync communications

- TCP and UDP port **7946** for `control plane` gossip discovery communication between all nodes

- UDP port **4789** for `data plane` VXLAN overlay network traffic

- IP Protocol 50 (ESP) if you plan on using overlay network with the encryption option


# AWS Security Group Example

<!--html_preserve--><div id="htmlwidget-db3b8aa079f97c90f6a6" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-db3b8aa079f97c90f6a6">{"x":{"filter":"none","caption":"<caption>Inbound to Swarm Managers<\/caption>","data":[["Custom TCP Rule","Custom TCP Rule","Custom UDP Rule","Custom UDP Rule","Custom UDP Rule","Custom Protocol"],["TCP","TCP","UDP","UDP","UDP","50"],["2377","7946","7946","4789","4789","all"],["swarm + remote mgmt","swarm","swarm","swarm","swarm","swarm"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>TYPE<\/th>\n      <th>PROTOCOL<\/th>\n      <th>PORTS<\/th>\n      <th>SOURCE<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"dom":"t","order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve--><!--html_preserve--><div id="htmlwidget-348b09c51138a9a9e3ac" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-348b09c51138a9a9e3ac">{"x":{"filter":"none","caption":"<caption>Inbound to Swarm Workers<\/caption>","data":[["Custom TCP Rule","Custom UDP Rule","Custom UDP Rule","Custom Protocol"],["TCP","UDP","UDP","50"],["7946","7946","4789","all"],["swarm","swarm","swarm","swarm"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th>TYPE<\/th>\n      <th>PROTOCOL<\/th>\n      <th>PORTS<\/th>\n      <th>SOURCE<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"dom":"t","order":[],"autoWidth":false,"orderClasses":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->




# 주의 (2)

연결 가능한 서버끼리만 묶을 수 있다. 

1. AWS끼리(O), Azure끼리(O), Digitalocean끼리(O)

2. **AWS와 Azure(X), AWS와 Digitalocean(X)**

3. **AWS(Azure, Digitalocean)와 자체서버(X)**


# 서비스 실행: rstudio & shiny server

자체 이미지 [docker-rshiny](https://hub.docker.com/r/jinseob2kim/docker-rshiny/) 

```bash
docker service create \
    --publish 8787:8787 \
    --publish 3838:3838 \ 
    -e USER=js -e PASSWORD=js -e ROOT=TRUE \
    --name rshiny \
    jinseob2kim/docker-rshiny
```

- `rstudio server`: **Both IP**:8787, `shiny server`: **Both IP**:3838


추가: [tensorflow docker](https://hub.docker.com/r/tensorflow/tensorflow/) 실행 

```bash
docker service create \
    --name tf \
    --publish 8888:8888\
     tensorflow/tensorflow
```

- **Both IP**:8888


# 사용자가 늘어나면?

`docker service scale` 명령어 이용, 여러 서버에 이미지 설치. 

```bash
docker service scale rshiny=2
```

다시 줄이기 

```bash
docker service scale rshiny=1
```




# 옵션: [Docker-machine](https://docs.docker.com/machine/overview/)

- 여러 대의 서버(docker가 설치된)를 로컬 컴퓨터에서 한 번에 관리할 수 있음. 

- 클라우드 지원
    + ex) AWS 서버 2대 불러오기, 서버 삭제하기
    
- **2376** port 오픈 필요.

<div class="figure" style="text-align: center">
<img src="https://docs.docker.com/machine/img/machine-mac-win.png" alt="https://docs.docker.com/machine/overview/#whats-the-difference-between-docker-engine-and-docker-machine" width="60%" />
<p class="caption">https://docs.docker.com/machine/overview/#whats-the-difference-between-docker-engine-and-docker-machine</p>
</div><div class="figure" style="text-align: center">
<img src="https://docs.docker.com/machine/img/provision-use-case.png" alt="https://docs.docker.com/machine/overview/#whats-the-difference-between-docker-engine-and-docker-machine" width="60%" />
<p class="caption">https://docs.docker.com/machine/overview/#whats-the-difference-between-docker-engine-and-docker-machine</p>
</div>





# [Docker-machine](https://docs.docker.com/machine/overview/) 설치

```bash
base=https://github.com/docker/machine/releases/download/v0.15.0 &&
curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
sudo install /tmp/docker-machine /usr/local/bin/docker-machine
docker-machine version
```

# 예: Digital ocean - manager 이름으로 서버 생성 

- **TOKEN** 정보 필요 

```bash
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
```


# AWS 

- **ACCESS_KEY_ID, SECRET_ACCESS_KEY, VPC_ID** 필요
- 포트 따로 열어줘야 됨.

```bash
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
```

# AZURE 

- **Subscription id** 필요
- 포트 따로 열어줘야 됨.

```bash
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
```



# 묶을 서버 추가오기 : worker node 

```bash
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


# 서버 묶기 : [Docker-machine](https://docs.docker.com/machine/overview/) 활용 

**manager1** 과 **worker1** 노드를 [docker swarm](https://docs.docker.com/engine/swarm/)를 활용하여 묶자. 

```bash
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



# 2. Dynamic proxy & https: [Traefik](https://traefik.io/)


# Problem

- DOMAINNAME:3838, :8787 보여주기 싫다. 
    + `/server`, `/app` 으로는 안되나?
    + `server.DOMAINNAME`, `app.DOMAINNAME` 은?

**리버스 프록시(reverse proxy)** 프로그램이 필요하다. 

- [nginx](https://nginx.org/en/) 로 `/server`, `/app` 가능. 

<div class="figure" style="text-align: center">
<img src="https://diarmuid.ie/media/nginx-docker-reverse-proxy.png" alt="https://diarmuid.ie/media/nginx-docker-reverse-proxy.png" width="40%" />
<p class="caption">https://diarmuid.ie/media/nginx-docker-reverse-proxy.png</p>
</div>



# Problem: [nginx](https://nginx.org/en/)

1. [Docker](https://www.docker.com/what-docker) 와 궁합이 안좋다?

- 서비스 실행해서 포트 추가될 때마다 일일히 주소 적용해줘야..

- [Docker swarm](https://docs.docker.com/engine/swarm/) 과는 더 안좋다. 


2. `https` 적용 불가능 

- 따로 비용을 지불하거나 

- 무료 `https` 적용 프로그램인 [Let's Encrypt](https://letsencrypt.org/) 를 수동으로 적용해야됨. 


[`HTTP` 구글 크롬서 퇴출 수순…7월부터 "안전하지 않다" 경고](http://news.mk.co.kr/newsRead.php?sc=30000037&year=2018&no=129224)


3. **Subdomain** 불가능

- `server.DOMAINNAME`, `app.DOMAINNAME` 불가능. 



# [Traefik](https://traefik.io/)

[Docker swarm](https://docs.docker.com/engine/swarm/) 을 위한 **dynamic proxy** 프로그램

- `rstudio server` 서비스 추가하면 **rstudio.DOMAINNAME** 로 자동으로 **subdomain** 적용. `tensorflow` 서비스 추가하면 **tensorflow.DOMAINNAME** 으로 적용. 

- `https` 자동 적용됨: [Let's Encrypt](https://letsencrypt.org/) 연계 

<img src="https://ian-says.com/articles/traefik-proxy-docker-ssl/thumbnail.png" width="70%" style="display: block; margin: auto;" />

https://ian-says.com/articles/traefik-proxy-docker-lets-encrypt/


# Overview [Traefik](https://traefik.io/) 

<div class="figure" style="text-align: center">
<img src="https://image.ibb.co/enAZi5/Sans_titre.png" alt="https://hub.docker.com/r/ghiltoniel/traefik-react/" width="90%" />
<p class="caption">https://hub.docker.com/r/ghiltoniel/traefik-react/</p>
</div>





# Run [Traefik](https://traefik.io/)

1. 도메인 추가: `*.DOMAINNAME`

도메인 설정 **CNAME**에 `*.DOMAINNAME`를 추가해야 된다. 

<img src="domain_wild.jpg" width="70%" style="display: block; margin: auto;" />



# 2. [Traefik](https://traefik.io/) 용 network 만들기

```bash
# Run in manager node
eval $(docker-machine env manager1)

# Create network for swarm
docker network create --driver=overlay traefik-net
```



# 3. [Let's Encrypt](https://letsencrypt.org/) 설정

- 빈 **acme.json** 파일을 만든다 (읽기쓰기 가능).

- 세부 설정이 담긴 **traefik.toml** 을 만든다.

```bash
# For Let's Encrypt
docker-machine ssh manager1 "DOMAINNAME=anpanman.co.kr && \ 
                             mkdir /home/js/opt && \ 
                             mkdir /home/js/opt/traefik && \
                             cd /home/js/opt/traefik && \
                             touch acme.json && chmod 600 acme.json && \
                             wget -O traefik.toml  https://raw.githubusercontent.com/jinseob2kim/swarm-setting/master/opt/traefik/traefik.toml"
```                             



# traefik.toml

```bash
defaultEntryPoints = ["http", "https"]

logLevel = "INFO"

[api]
dashboard = true
address = ":8080"

[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.redirect]
      regex = "^https://anpanman.co.kr/(.*)"
      replacement = "https://www.anpanman.co.kr/$1"
      permanent = true
    [entryPoints.https.tls]  


[acme]
email = "jinseob2kim@gmail.com"
storage = "acme.json"
entryPoint = "https"
onHostRule = true
onDemand = false


## *.anpanman.co.kr & anpanman.co.kr should be in DNS "A or CNAME": digitalocean case.
[acme.dnsChallenge]
  provider = "digitalocean"
  delayBeforeCheck = 0 
```



# 4. Run [Traefik](https://traefik.io/)

```bash
eval $(docker-machine env manager1)
DOMAINNAME="anpanman.co.kr"

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
    -l traefik.frontend.rule=Host:monitor.$DOMAINNAME\
    --network traefik-net \
    traefik \
    --logLevel=INFO \
    --docker \
    --docker.swarmMode \
    --docker.watch \
    --docker.domain=$DOMAINNAME
```

https://monitor.anpanman.co.kr 에서 `dashboard`를 볼 수 있다.



# 서비스 재실행: rstudio & shiny server

[Traefik](https://traefik.io/) 를 적용하여 재실행하자. 

```bash
docker service create \
    --name rshiny \
    --label traefik.shiny.port=3838 \
    --label traefik.rstudio.port=8787 \
    --label traefik.shiny.frontend.rule="Host:app.$DOMAINNAME" \
    --label traefik.rstudio.frontend.rule="Host:server.$DOMAINNAME" \
    -e USER=js -e PASSWORD=js -e ROOT=TRUE \
    --network traefik-net \
     jinseob2kim/docker-rshiny
```
https://server.anpanman.co.kr 에서 `rstudio server`를, https://app.anpanman.co.kr 에서 `shiny server`를 실행할 수 있다. 



# 서비스 추가: 홈페이지

proxy server 프로그램인 [nginx](https://www.nginx.com/)의 [docker image](https://hub.docker.com/_/nginx/) 를 이용하였고, [blogdown 패키지](https://github.com/rstudio/blogdown) 를 활용해서 홈페이지를 만들었다. 


```bash
docker service create \
    --name nginx \
    --label traefik.port=80 \
    --label traefik.frontend.rule="Host:${DOMAINNAME},www.${DOMAINNAME}" 
    --network traefik-net \
    nginx 
```
https://anpanman.co.kr, https://www.anpanman.co.kr 에서 [nginx](https://www.nginx.com/) 실행환경을 볼 수 있다. 


# 중간 정리 

1. 필요한 서비스를 미리 [Docker image](https://hub.docker.com/r/jinseob2kim/docker-rshiny/) 로 만들었다. 

2. [Docker-machine](https://docs.docker.com/machine/overview/) 을 이용하여 [Docker](https://www.docker.com/what-docker)가 설치된 클라우드 서버를 여러 개 생성한 후 

3. [Docker swarm](https://docs.docker.com/engine/swarm/) 을 통해 서버들을 묶었다. 

4. 이제 서비스를 실행하면 Swarm 환경이 알아서 적절한 서버를 골라 실행한다. 

5. [Traefik](https://traefik.io/) 을 이용하여 서비스를 추가할 때마다 그에 맞는 **subdomain** 주소를 자동으로 할당하였다. 

6. [Let's Encrypt](https://letsencrypt.org/) 을 통한 **https** 인증이 자동으로 적용된다. 


# 사용 후기: (9월 말)

1. [Docker swarm](https://docs.docker.com/engine/swarm/) 은 오버.

    + 서비스 24시간 계속 실행 필요?
    
    + 서버 하나 먹통되더라도 서비스 유지 필수?
    
    + 대규모 프로젝트?
    
 

2. 가내수공업은 [Docker](https://www.docker.com/what-docker) 로 충분.


현재 

- [docker-rshiny](https://hub.docker.com/r/jinseob2kim/docker-rshiny/)는 자체 서버 1대에서 실행

- [홈페이지](https://www.anpanman.co.kr/)와 [블로그](https://blog.anpanman.co.kr/)는 [github](https://github.com/)에 코드, [netlify](https://www.netlify.com/)로 무료 호스팅. - **https** 무료 



    

# 3. 의학연구용 `ShinyApps` 만들기 

# 주 활용 패키지 

- 데이터: [`data.table`](https://github.com/Rdatatable/data.table/wiki), [`DT`](https://rstudio.github.io/DT/)

- 통계분석: [`tableone`](https://github.com/kaz-yos/tableone), [`epiDisplay`](https://cran.r-project.org/web/packages/epiDisplay/index.html), `survival`, `geepack`, `lme4`, `plotROC`, `pROC`

- Plot: `ggplot2`, [`GGally`](http://ggobi.github.io/ggally/), [`svglite`](https://github.com/r-lib/svglite) 

- 패키지: `devtools`, `roxygen2`

- Shiny: [`shinycustomloader`](https://github.com/emitanaka/shinycustomloader), [`shiny.i18n`](https://github.com/Appsilon/shiny.i18n)


# [`DT`](https://rstudio.github.io/DT/)

- 반응형 테이블 패키지

- 셀 강조 (ex: **색깔**) : `formatStyle` 옵션 

- 엑셀 파일로 바로 **다운로드** : `Buttons` 옵션

<!--html_preserve--><div id="htmlwidget-4d1f7c6289244fa3328e" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-4d1f7c6289244fa3328e">{"x":{"filter":"none","extensions":["Buttons"],"data":[["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39","40","41","42","43","44","45","46","47","48","49","50","51","52","53","54","55","56","57","58","59","60","61","62","63","64","65","66","67","68","69","70","71","72","73","74","75","76","77","78","79","80","81","82","83","84","85","86","87","88","89","90","91","92","93","94","95","96","97","98","99","100","101","102","103","104","105","106","107","108","109","110","111","112","113","114","115","116","117","118","119","120","121","122","123","124","125","126","127","128","129","130","131","132","133","134","135","136","137","138","139","140","141","142","143","144","145","146","147","148","149","150"],[5.1,4.9,4.7,4.6,5,5.4,4.6,5,4.4,4.9,5.4,4.8,4.8,4.3,5.8,5.7,5.4,5.1,5.7,5.1,5.4,5.1,4.6,5.1,4.8,5,5,5.2,5.2,4.7,4.8,5.4,5.2,5.5,4.9,5,5.5,4.9,4.4,5.1,5,4.5,4.4,5,5.1,4.8,5.1,4.6,5.3,5,7,6.4,6.9,5.5,6.5,5.7,6.3,4.9,6.6,5.2,5,5.9,6,6.1,5.6,6.7,5.6,5.8,6.2,5.6,5.9,6.1,6.3,6.1,6.4,6.6,6.8,6.7,6,5.7,5.5,5.5,5.8,6,5.4,6,6.7,6.3,5.6,5.5,5.5,6.1,5.8,5,5.6,5.7,5.7,6.2,5.1,5.7,6.3,5.8,7.1,6.3,6.5,7.6,4.9,7.3,6.7,7.2,6.5,6.4,6.8,5.7,5.8,6.4,6.5,7.7,7.7,6,6.9,5.6,7.7,6.3,6.7,7.2,6.2,6.1,6.4,7.2,7.4,7.9,6.4,6.3,6.1,7.7,6.3,6.4,6,6.9,6.7,6.9,5.8,6.8,6.7,6.7,6.3,6.5,6.2,5.9],[3.5,3,3.2,3.1,3.6,3.9,3.4,3.4,2.9,3.1,3.7,3.4,3,3,4,4.4,3.9,3.5,3.8,3.8,3.4,3.7,3.6,3.3,3.4,3,3.4,3.5,3.4,3.2,3.1,3.4,4.1,4.2,3.1,3.2,3.5,3.6,3,3.4,3.5,2.3,3.2,3.5,3.8,3,3.8,3.2,3.7,3.3,3.2,3.2,3.1,2.3,2.8,2.8,3.3,2.4,2.9,2.7,2,3,2.2,2.9,2.9,3.1,3,2.7,2.2,2.5,3.2,2.8,2.5,2.8,2.9,3,2.8,3,2.9,2.6,2.4,2.4,2.7,2.7,3,3.4,3.1,2.3,3,2.5,2.6,3,2.6,2.3,2.7,3,2.9,2.9,2.5,2.8,3.3,2.7,3,2.9,3,3,2.5,2.9,2.5,3.6,3.2,2.7,3,2.5,2.8,3.2,3,3.8,2.6,2.2,3.2,2.8,2.8,2.7,3.3,3.2,2.8,3,2.8,3,2.8,3.8,2.8,2.8,2.6,3,3.4,3.1,3,3.1,3.1,3.1,2.7,3.2,3.3,3,2.5,3,3.4,3],[1.4,1.4,1.3,1.5,1.4,1.7,1.4,1.5,1.4,1.5,1.5,1.6,1.4,1.1,1.2,1.5,1.3,1.4,1.7,1.5,1.7,1.5,1,1.7,1.9,1.6,1.6,1.5,1.4,1.6,1.6,1.5,1.5,1.4,1.5,1.2,1.3,1.4,1.3,1.5,1.3,1.3,1.3,1.6,1.9,1.4,1.6,1.4,1.5,1.4,4.7,4.5,4.9,4,4.6,4.5,4.7,3.3,4.6,3.9,3.5,4.2,4,4.7,3.6,4.4,4.5,4.1,4.5,3.9,4.8,4,4.9,4.7,4.3,4.4,4.8,5,4.5,3.5,3.8,3.7,3.9,5.1,4.5,4.5,4.7,4.4,4.1,4,4.4,4.6,4,3.3,4.2,4.2,4.2,4.3,3,4.1,6,5.1,5.9,5.6,5.8,6.6,4.5,6.3,5.8,6.1,5.1,5.3,5.5,5,5.1,5.3,5.5,6.7,6.9,5,5.7,4.9,6.7,4.9,5.7,6,4.8,4.9,5.6,5.8,6.1,6.4,5.6,5.1,5.6,6.1,5.6,5.5,4.8,5.4,5.6,5.1,5.1,5.9,5.7,5.2,5,5.2,5.4,5.1],[0.2,0.2,0.2,0.2,0.2,0.4,0.3,0.2,0.2,0.1,0.2,0.2,0.1,0.1,0.2,0.4,0.4,0.3,0.3,0.3,0.2,0.4,0.2,0.5,0.2,0.2,0.4,0.2,0.2,0.2,0.2,0.4,0.1,0.2,0.2,0.2,0.2,0.1,0.2,0.2,0.3,0.3,0.2,0.6,0.4,0.3,0.2,0.2,0.2,0.2,1.4,1.5,1.5,1.3,1.5,1.3,1.6,1,1.3,1.4,1,1.5,1,1.4,1.3,1.4,1.5,1,1.5,1.1,1.8,1.3,1.5,1.2,1.3,1.4,1.4,1.7,1.5,1,1.1,1,1.2,1.6,1.5,1.6,1.5,1.3,1.3,1.3,1.2,1.4,1.2,1,1.3,1.2,1.3,1.3,1.1,1.3,2.5,1.9,2.1,1.8,2.2,2.1,1.7,1.8,1.8,2.5,2,1.9,2.1,2,2.4,2.3,1.8,2.2,2.3,1.5,2.3,2,2,1.8,2.1,1.8,1.8,1.8,2.1,1.6,1.9,2,2.2,1.5,1.4,2.3,2.4,1.8,1.8,2.1,2.4,2.3,1.9,2.3,2.5,2.3,1.9,2,2.3,1.8],["setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica"]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>Sepal.Length<\/th>\n      <th>Sepal.Width<\/th>\n      <th>Petal.Length<\/th>\n      <th>Petal.Width<\/th>\n      <th>Species<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"dom":"<lf<rt>Bip>","lengthMenu":[[10,25,-1],["10","25","All"]],"pageLength":10,"buttons":["copy","print",{"extend":"collection","buttons":[{"extend":"csv","filename":"table"},{"extend":"excel","filename":"table"},{"extend":"pdf","filename":"table"}],"text":"Download"}],"columnDefs":[{"className":"dt-right","targets":[1,2,3,4]},{"orderable":false,"targets":0}],"order":[],"autoWidth":false,"orderClasses":false,"rowCallback":"function(row, data) {\nvar value=data[5]; $(this.api().cell(row, 5).node()).css({'background-color':value == 'setosa' ? 'lightblue' : value == 'versicolor' ? 'lightgreen' : value == 'virginica' ? 'lightpink' : '','transform':'rotateX(45deg) rotateY(20deg) rotateZ(30deg)'});\nvar value=data[3]; $(this.api().cell(row, 3).node()).css({'background':isNaN(parseFloat(value)) || value <= 1 ? '' : 'linear-gradient(90deg, transparent ' + (6.9 - value)/5.9 * 100 + '%, steelblue ' + (6.9 - value)/5.9 * 100 + '%)','background-size':'100% 90%','background-repeat':'no-repeat','background-position':'center'});\nvar value=data[2]; $(this.api().cell(row, 2).node()).css({'color':isNaN(parseFloat(value)) ? '' : value <= 3.4 ? 'white' : value <= 3.8 ? 'blue' : 'red','background-color':isNaN(parseFloat(value)) ? '' : value <= 3.4 ? 'gray' : 'yellow'});\nvar value=data[1]; $(this.api().cell(row, 1).node()).css({'font-weight':isNaN(parseFloat(value)) ? '' : value <= 5 ? 'normal' : 'bold'});\n}"}},"evals":["options.rowCallback"],"jsHooks":[]}</script><!--/html_preserve-->


#


```r
library(DT)
datatable(iris, extension= "Buttons", rownames = F,
          options = list(dom = '<lf<rt>Bip>', lengthMenu = list(c(10, 25, -1), c('10', '25', 'All')), pageLength = 10,
                        buttons = list('copy', 'print', 
                                       list(extend = 'collection', 
                                            buttons = list(list(extend = 'csv', filename= "table"),
                                                           list(extend = 'excel', filename= "table"), 
                                                           list(extend = 'pdf', filename= "table")
                                                           ), 
                                            text = 'Download')
                                       )
                        )
          ) %>% 
  formatStyle('Sepal.Length', fontWeight = styleInterval(5, c('normal', 'bold'))) %>%
  formatStyle(
    'Sepal.Width',
    color = styleInterval(c(3.4, 3.8), c('white', 'blue', 'red')),
    backgroundColor = styleInterval(3.4, c('gray', 'yellow'))
  ) %>%
  formatStyle(
    'Petal.Length',
    background = styleColorBar(iris$Petal.Length, 'steelblue'),
    backgroundSize = '100% 90%',
    backgroundRepeat = 'no-repeat',
    backgroundPosition = 'center'
  ) %>%
  formatStyle(
    'Species',
    transform = 'rotateX(45deg) rotateY(20deg) rotateZ(30deg)',
    backgroundColor = styleEqual(
      unique(iris$Species), c('lightblue', 'lightgreen', 'lightpink')
    )
  )
```


# [`shinycustomloader`](https://github.com/emitanaka/shinycustomloader)

- 앱 실행 중 로딩 보여주기.

- 실행이 오래걸리는 앱일 때 필요.

<div class="figure" style="text-align: center">
<img src="https://user-images.githubusercontent.com/7620319/38162696-cafcd18e-3531-11e8-8228-f08defa97ae0.gif" alt="https://user-images.githubusercontent.com/7620319/38162696-cafcd18e-3531-11e8-8228-f08defa97ae0.gif" width="70%" />
<p class="caption">https://user-images.githubusercontent.com/7620319/38162696-cafcd18e-3531-11e8-8228-f08defa97ae0.gif</p>
</div>


# Label

- **데이터**의 변수명, 값 $\neq$ **테이블/그림**의 변수명, 값 

- **Label data** 생성하고 통계결과와 그림에 적용: 자체 패키지 [`jstable`](https://github.com/jinseob2kim/jstable)

<img src="label.jpg" width="70%" style="display: block; margin: auto;" />


# Table 1: `tableone` package

<div class="figure" style="text-align: center">
<img src="https://github.com/kaz-yos/tableone/raw/master/tableone.gif" alt="https://github.com/kaz-yos/tableone" width="70%" />
<p class="caption">https://github.com/kaz-yos/tableone</p>
</div>

- [`tableone`](https://github.com/kaz-yos/tableone) 패키지 기반으로 **Label** 정보 적용하여 앱 구현


# Main results 

- **Regression, logistic regression, cox** : [`epiDisplay`](https://cran.r-project.org/web/packages/epiDisplay/index.html) 패키지 기반으로 결과테이블 생성


```r
library(epiDisplay)
model0 <- glm(case ~ induced + spontaneous, family=binomial, data=infert)
logistic.display(model0, crude = T, crude.p.value = T)$table
```

<!--html_preserve--><div id="htmlwidget-234aed8dc624573e4f98" style="width:100%;height:auto;" class="datatables html-widget"></div>
<script type="application/json" data-for="htmlwidget-234aed8dc624573e4f98">{"x":{"filter":"none","caption":"<caption>\nLogistic regression predicting case \n<\/caption>","data":[["induced (cont. var.)","","spontaneous (cont. var.)",""],["1.05 (0.74,1.5) ","","2.9 (1.97,4.26) ",""],["0.788","","&lt; 0.001",""],["1.52 (1.02,2.27) ","","3.31 (2.19,5.01) ",""],["0.042","","&lt; 0.001",""],["0.042","","&lt; 0.001",""]],"container":"<table class=\"display\">\n  <thead>\n    <tr>\n      <th> <\/th>\n      <th>crude OR(95%CI)<\/th>\n      <th>crude P value<\/th>\n      <th>adj. OR(95%CI)<\/th>\n      <th>P(Wald's test)<\/th>\n      <th>P(LR-test)<\/th>\n    <\/tr>\n  <\/thead>\n<\/table>","options":{"dom":"t","order":[],"autoWidth":false,"orderClasses":false,"columnDefs":[{"orderable":false,"targets":0}]}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

```
## Log-likelihood = -139.806
## No. of observations = 248
## AIC value = 285.612
```


# 

<img src="cox.jpg" width="60%" style="display: block; margin: auto;" />

- **GEE, mixed model, GLMM, mixed effect Cox** : 자체 패키지 [`jstable`](https://github.com/jinseob2kim/jstable) 로 결과테이블 생성

- **Label** 정보 적용.


# Plot

- [`GGally`](http://ggobi.github.io/ggally/) : `ggpair` 함수로 변수 비교

- [`svglite`](https://github.com/r-lib/svglite) : **svg** 포맷으로 그림 저장하여 **ppt**에서 수정 가능. 

- Kaplan meire plot: [`ggkm`](https://github.com/michaelway/ggkm) 패키지 기반으로 자체 패키지 [`jskm`](https://github.com/jinseob2kim/jskm) 사용 

<img src="km.jpg" width="70%" style="display: block; margin: auto;" />

# `Shiny module` and `Rstudio addin`

[`jsmodule`](https://github.com/jinseob2kim/jsmodule)

- 자주 쓰는 `Shiny module` 을 저장.

- `Rstudio addin` : basic, propenstity score analysis

#

<div class="figure" style="text-align: center">
<img src="propensity.gif" alt="Rstudio addin: propensity score analysis" width="100%" />
<p class="caption">Rstudio addin: propensity score analysis</p>
</div>




# 다중언어 지원 

- [`shiny.i18n`](https://github.com/Appsilon/shiny.i18n) 패키지

<div class="figure" style="text-align: center">
<img src="https://cdn-ak.f.st-hatena.com/images/fotolife/k/ksmzn/20171209/20171209204102.gif" alt="https://cdn-ak.f.st-hatena.com/images/fotolife/k/ksmzn/20171209/20171209204102.gif" width="90%" />
<p class="caption">https://cdn-ak.f.st-hatena.com/images/fotolife/k/ksmzn/20171209/20171209204102.gif</p>
</div>




# Examples 

1. [범용 기초통계 앱](http://147.47.68.165:2222/basic)

2. [범용 Propensity score 분석앱](http://147.47.68.165:2222/ps)

3. [건강설문조사 리포트](http://147.47.68.165:2222/health-report)

4. [대장암 환자 연구: 강릉아산병원](http://147.47.68.165:2222/yschoi)

5. [이완기 압력 계산: 삼성서울병원](http://147.47.68.165:2222/chkh/dPR)

6. [심장질환 위험인자 연구: 계명대 동산의료원](http://147.47.68.165:2222/ds010042/REFERRAL/)

7. [다중 언어: 한/영](http://147.47.68.165:2222/shiny.i18n)


# Q & A {.bigger}






