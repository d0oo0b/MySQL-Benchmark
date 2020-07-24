# 一、 新增OLTP按比例读写功能

### oltp-rw-withProportion
参数：

r_times 读操作比重，默认值1。
	
w_times 写操作比重，默认值1。


举例：

```
sysbench --mysql-host=[host name] --mysql-user=[user id] --mysql-password=[password] --mysql-db=[database] --table_size=1000000 --threads=36 --time=30000 --report-interval=1 --r_times=2 --w_times=3 oltp-rw-withProportion run
```


# 二、 SYSBENCH 下 IOPS的极限探索

## 目标

通过修改RDS实例类型、参数、多可用区部署等配置，探查sysbench iops压不上去的原因，发掘sysbench在benchmark过程中的局限性。

## 结论

Sysbench 自身的读写有局限性，而且数据结构简单、测试场景单调；同时受sysbench client 环境的影响，多线程并发太高时，性能存在性能损耗，影响测试结果的正确性。
建议在stage环境中，用真实的workload模拟压力测试。


## 测试过程

### 环境准备

rds：

[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)

  

db.r5.24xlarge

single az

no backup

no enhance monitoring

no Encryption

io1 2000 GiB 20000iops

client：

10* c5.9x(36)

same az（1c at tokyo）

* * *

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)--mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table_size=1000000 --threads=36 --time=30000 --report-interval=1 oltp_insert run

  

同时运行10台client

![](resources/6ABE14DE-32F6-47BB-81C4-5D0C949783B4.png)  

  

![](resources/07B0A524-CBA5-4663-8A2B-A056C47FD3DD.png)  

  

  

  

### 修改参数：

![](resources/8CFCE794-1678-4DD7-8A43-D98D167F7AF0.png)  

同时运行10台client 

![](resources/58C3C0C2-EACB-42AF-B148-9474324A7BA8.png)  

  

![](resources/32597324-0729-4355-8B4B-984FF9E2CA79.png)  

  

### 阶段小结：

有提升，但是不明显。

  

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)--mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table_size=1000000 --threads=108 --time=30000 --report-interval=1 oltp_insert run

  

![](resources/9EF50F72-332E-4C05-8125-3932D0464D63.png)  

  

tps没有增加反而降低了，延迟大大增加了。

  

![](resources/11D317E3-0921-4F11-AC43-A4F058632FB1.png)  

  

### 阶段小结：

增加线程数并不能增加tps，应该增加机器（vcpu）。

  

  

sudo sh -c 'for x in /sys/class/net/eth0/queues/rx-*; do echo f,ffffffff > $x/rps_cpus; done'

sudo sh -c "echo 32768 > /proc/sys/net/core/rps\_sock\_flow_entries"

sudo sh -c "echo 4096 > /sys/class/net/eth0/queues/rx-0/rps\_flow\_cnt"

sudo sh -c "echo 4096 > /sys/class/net/eth0/queues/rx-1/rps\_flow\_cnt"

  

### 以上重启后还原

  

sudo sh -c "echo 'kernel.pid_max = 65535' >> /etc/sysctl.conf"

sudo sh -c "echo '* soft nofile 65536' > /etc/security/limits.d/20-nproc.conf"

sudo sh -c "echo '* hard nofile 65536' >> /etc/security/limits.d/20-nproc.conf"

  

sudo reboot

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table\_size=1000000 --threads=36 --time=30000 --report-interval=1 oltp\_insert run

  

![](resources/9CC35959-6864-4724-BBEB-A7A1F0332278.png)  

  

通之前的36 threads 比，没有什么大的变化。

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table\_size=1000000 --threads=36 --time=30000 --report-interval=1 oltp\_insert run

  

![](resources/365E2A96-375F-4514-8A3B-6F44CD901E7A.png)  

IOPS倒是高了一点

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table\_size=1000000 —threads=154 --time=30000 --report-interval=1 oltp\_insert run

  

### 运行3台 改成 multi az

  

![](resources/E2D00D39-53DB-4B57-BFD5-271362323D42.png)  

  

  

刚打开 multi az的时候：

![](resources/A603812D-2E66-47ED-B2F1-4A0E685C1F6D.png)  

  

运行一段时间后

![](resources/46E4D90E-D2B9-4AAF-8868-72F1ECCCFE79.png)  

  

  

### 阶段小结：

multi-az 对性能影响有限。

  

找到一个case：[https://paragon-na.amazon.com/hz/view-case?caseId=6164945421](https://paragon-na.amazon.com/hz/view-case?caseId=6164945421)

说明5.7.22 iops有瓶颈。。。。。。

  

### 升级到目前最新的5.7.28（和火币dba用的一样）

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table\_size=1000000 --threads=36 --time=30000 --report-interval=1 oltp\_insert run

  

### 运行10台client

![](resources/DC430C62-6F82-4942-B592-6ABF6035977D.png)  

  

和之前5.7.22比tps和95%没有大的变化

![](resources/A2B29617-0208-40DB-9564-EC6FC2D97496.png)  

  

iops 倒是明显的高了，但是还没有到1w。

当前数据表达到4亿行，truncate table后再跑一次。

  

![](resources/2C3CB458-8547-4CF3-923C-C334B58BDA5F.png)  

  

明显tps更高一点、95%更低一点。

![](resources/2DE56EF5-3EF2-4C6C-9BF0-097F68E6E02E.png)  

write io 更少了。似乎5.7.28 的io利用率更高，并且在数量大时，有更高的io极限。

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test1 --table_size=1000000 --threads=36 --time=30000 --report-interval=1 oltp\_read\_write run

  

![](resources/3B07E221-AB58-4F7D-9909-550DCF6E89D5.png)  

![](resources/0728EF18-29BF-46DD-9727-859E67D87CAA.png)  

  

混合读写之后iops更高了一点。。。什么原理？读似乎都被cache了。

  

干掉缓存

![](resources/64418E1C-8F88-4036-A462-DB03EBBB7B50.png)  

重新运行10client(中间停掉一台)

![](resources/EC33EAD2-0279-44DD-8211-0F8D8C63065A.png)  

![](resources/DC7AF550-C8A0-4659-B564-18BC4F10F091.png)  

  

io增长速度：30/分钟

  

增加数据和表看一下：

  

sysbench --mysql-host=[aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com](http://aaa-mysql.clahnijqri5x.ap-northeast-1.rds.amazonaws.com)  --mysql-user=admin --mysql-password=1qaz2WSX --mysql-db=test3 --table\_size=100000000  --threads=36 --time=30000 --report-interval=10 --tables=30 oltp\_read_write prepare

  

  

  

如果固定了机型、数据量、sysbench测试方法（读写模式）现在看响应时间包括：client 线程等待+client到mysql网络延迟和数据传输+mysql处理并发+db引擎解析sql等操作+磁盘io+mysql到client网络延迟和数据传输

大概这5部分，与之相关的“常量”如下：

  

client 线程等待 ----> client

client到mysql网络延迟和数据传输------> 网络延迟

mysql到client网络延迟和数据传输------> 网络延迟

db引擎解析sql等操作------>引擎

磁盘io------>磁盘配置

mysql处理并发------>实例配置

  

  

唯一的变量：改变线程大小，因为从目前测试看所有的case都远没有达到磁盘吞吐、网络带宽上限，和这个变量相关的“响应时间组成部分”：

  

client 线程等待 ----> client

db引擎解析sql等操作------>引擎

mysql处理并发------>实例配置

  

因为前面说过，固定了机型，剩下可以优化的只有：

  

client 线程等待 ----> client

db引擎解析sql等操作------>引擎

  

![](resources/A2F100EB-D7E4-4886-A193-4C75AECD400A.png)

  

可以看到5的位置，做数据的时候增大了io，超过了1w。

等待11个小时后看：

![](resources/75019D1A-EA63-4670-9F1A-8993F6B3616E.png)

  

![](resources/5DDA8D41-3961-43F4-AC57-180C5D0148AC.png)

![](resources/5BAC4786-8DA4-4FF7-97C9-723FB8850314.png)

![](resources/8C999B24-6CE9-4CB1-BFF6-BCF5BA45B831.png)

![](resources/C7CA44A3-0F5F-410C-958C-74A9708B0ADF.png)

![](resources/A05EB21C-2119-4F89-ABC8-F4C92E2DBC66.png)

  

  

### 结论：
Sysbench 自身的读写有局限性，而且数据结构简单、测试场景单调；同时受sysbench client 环境的影响，多线程并发太高时，性能存在性能损耗，影响测试结果的正确性。
建议在stage环境中，用真实的workload模拟压力测试。

