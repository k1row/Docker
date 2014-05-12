Docker
======
Dockerを利用して、GCEにCentOS + nginx サーバの構築  
GCEの設定型は割愛  

# 事前準備

####自分のMAC等においてあるDockerfileのコピー
`$ gcutil --project="YOUR PROJECT NAME" push "YOUR SERVER NAME" /Users/a12431/Develop/ss/docker /tmp`  

#### GCEサーバにログイン
`$ gcutil --service_version="v1" --project="YOUR PROJECT NAME" ssh --zone="YOUR ZONE" "YOUR SERVER NAME"`  

#### Dockerのインストール
`$ sudo yum -y update`  
`$ sudo yum -y install wget`   

*ホスト側のSELinuxを切っておかないと※passwd しようとすると以下のエラーが出る。*  
**passwd: unconfined_u:system_r:initrc_t:s0 is not authorized to change the password of user*  
`$ sudo echo "SELINUX=disabled" > /etc/selinux/config`  
`$ sudo cd /usr/local/src/`  
`$ sudo wget http://ftp-srv2.kddilabs.jp/Linux/distributions/fedora/epel/6/x86_64/epel-release-6-8.noarch.rpm`  
`$ sudo rpm -ivh epel-release-6-8.noarch.rpm`  
`$ sudo yum -y --enablerepo=epel install docker-io`  
`$ sudo chkconfig docker on`  
`$ sudo service docker start`  

#### コンテナ用SSHキーの発行(すべてのコンテナに同一のキーでアクセスする前提)
`$ mkdir ~/docker_ssh`  
`$ cd ~/docker_ssh/`  
`$ mkdir ~/.ssh/docker`  
`$ ssh-keygen -t rsa -C "YOUR EMAIL"`  

> Generating public/private rsa key pair.
> Enter file in which to save the key (/home/USER NAME/.ssh/id_rsa): /home/USER NAME/.ssh/docker/docker_rsa
> Enter passphrase (empty for no passphrase):
> Enter same passphrase again:
> Your identification has been saved in /home/USER NAME/.ssh/docker/docker_rsa.
> Your public key has been saved in /home/USER NAME/.ssh/docker/docker_rsa.pub.
> The key fingerprint is:
> 91:dc:70:25:62:e2:de:47:30:d3:a5:a2:a1:d0:88:f4 YOUR EMAIL
> The key's randomart image is:
> +--[ RSA 2048]----+
> | .    . B.ooo    |
> |...o . + X.o     |
> |. oE. o = +      |
> |   . o + +       |
> |    . o S .      |
> |         .       |
> |                 |
> |                 |
> |                 |
> +-----------------+

  
`$ cp ~/.ssh/docker/docker_rsa.pub ~/docker_ssh/authorized_keys`  
`$ cp ~/.ssh/docker/docker_rsa ~/docker_ssh/docker_rsa`  

#### Dockerfileと同じ場所にauthorized_keysを配置
`$ cp /tmp/docker ~/docker_ssh/authorized_keys`  

# Dockerの設定

#### Dockerfileを使ってイメージを作成する
`$ cd /tmp/docker`  
`$ sudo docker build -t centos:webserver .`  
> ---> 4e9582af70b3
>> Successfully built 4e9582af70b3

#### 完成imageの確認
`$ sudo docker images`  
> REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
> centos              webserver           4e9582af70b3        9 minutes ago       605.1 MB

#### 作成したコンテナイメージから、sshdを起動した状態でコンテナを立ち上げてみる
*-dオプションでバックグラウンド起動*  
*-pオプションでポートフォワーディング*  
`$ sudo docker run -d -p 22 centos:webserver /usr/sbin/sshd -D`  

#### 起動したコンテナを確認
`$ sudo docker ps`  
> CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS           >         NAMES
> f267d0eafcaf        centos:webserver    /usr/sbin/sshd -D   16 seconds ago      Up 14 seconds       0.0.0.0:49153->22/tcp   boring_pasteur

* PORTSの部分にある"0.0.0.0:49155->22/tcp"のような記述が、コンテナの22番ポートがホストの49155番にバインドされているという意味。*  

#### 起動したコンテナのIPアドレスの確認
`$ ifconfig`  
> docker0   Link encap:Ethernet  HWaddr FE:61:82:1B:A6:50
          inet addr:172.17.42.1  Bcast:0.0.0.0  Mask:255.255.0.0
          inet6 addr: fe80::c4e3:98ff:fe01:2ea2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1460  Metric:1
          RX packets:50872 errors:0 dropped:0 overruns:0 frame:0
          TX packets:138011 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:2783150 (2.6 MiB)  TX bytes:201929190 (192.5 MiB)  

  

#### 実際にSSH
`$ ssh -i ~/docker_ssh/docker_rsa -l docker 172.17.42.1 -p 49153`  
> The authenticity of host '[172.17.42.1]:49153 ([172.17.42.1]:49153)' can't be established.
RSA key fingerprint is 5d:c1:d9:6d:f2:e8:5c:9c:13:1b:c7:8a:be:46:86:48.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '[172.17.42.1]:49153' (RSA) to the list of known hosts.
[docker@f267d0eafcaf ~]$

  
# Dokerのコマンド関連

#### コンテナの確認
`$ sudo docker ps -a`  

#### コンテナIDをコマンド結果から入力して、該当コンテナを削除
`$ sudo docker rm `sudo docker ps -a -q```  

#### コンテナイメージの確認
`$ sudo docker images`  

#### コンテナイメージのの削除
`$ sudo docker rmi IMAGEID`  

#### イメージを一気に削除したい
`$ sudo docker rmi $(sudo docker images -q)`  

#### 依存関係などはdocker images の --treeオプションを使うとわかりやすい
`$ sudo docker images --tree`  

# 参考URL
<http://memocra.blogspot.jp/2014/02/dockerdockernginxweb.html>  
<http://yss44.hatenablog.com/entry/2014/01/02/083600>  
<http://nekok.com/2014/01/docker-memo-2/>  
<http://qiita.com/mopemope/items/181cb6c6c6f7cf9bbaa9>  
<http://yss44.hatenablog.com/entry/2013/12/27/150920>  
<http://dev.classmethod.jp/cloud/aws/firststep-docker-on-ec2/>  
