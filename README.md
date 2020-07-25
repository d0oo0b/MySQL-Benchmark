# 关于本工具：
需要预先安装sysbench 1.0.19
将lua和shall脚本，放置在/usr/share/sysbench 目录中，如有文件冲突，请覆盖原来的文件。

作为常用的MySQL基准测试工具，Sysbench有很多限制，例如无法自由设置读写比率，无法自动重建连接以及不友好的命令工具，这给基准测试带来了许多困难。 
本工具通过Lua脚本增强了sysbench的功能:

# 一、 新增OLTP按比例读写功能

### oltp-rw-withProportion
参数：

r_times 读操作比重，默认值1。
	
w_times 写操作比重，默认值1。


举例：

```
sysbench --mysql-host=[host name] --mysql-user=[user id] --mysql-password=[password] --mysql-db=[database] --table_size=1000000 --threads=36 --time=30000 --report-interval=1 --r_times=2 --w_times=3 oltp-rw-withProportion run
```

# 二、 新增自动化测试脚本，实现自动重连（测试failover等场景）

使用举例：
```
# 准备数据
bash /usr/share/sysbench/sysloop.sh
# 输入p

# 运行插入（1 thread）
bash /usr/share/sysbench/sysloop.sh > sysloop_insert.log
# 输入r
# 运行检查/select （50 thread）
bash /usr/share/sysbench/sysloop.sh > sysloop_check.log
# 输入c
```
请在 sysloop_check.log中调整测试参数。

# 三、 新增对分布式数据库读写分离的情况下，事务一致性的测试

插入的逻辑：

顺序插入row，按照每次insert 100行的方式。自动commit。

检查的逻辑：

```
-- 在bulk insert 的同时，不停的查询最大id
rs  = con:query(string.format([[SELECT max(id) 
                                  FROM sbtest%d
                              ]],table_num))
-- 等待另一个线程 insert
os.execute("sleep " .. 0.01)

for i = 1, rs.nrows do
    row = rs:fetch_row()
    if row[1] ~= nil then
       local num = 0
       num = tonumber(row[1])
       rscount = con:query(string.format([[SELECT count(id) 
                                             FROM sbtest%d
                                            where id > %d ]],table_num, num))
       row_count = rscount:fetch_row()
       local num_count = 0
       num_count = tonumber(row_count[1])
       local num1,num2=math.modf(num/sysbench.opt.batch_inserts)
       -- 检查是否存在读取的记录数量不是100的倍数的情况     
       if num2~=0 then
          print("xxxxxxxxxxx  %d    xxxxxxxxxxxx", num1)
          print(string.format("Max of table sbtest%d is  %d ", table_num, num))
       end

    end
end
```
如果出现 “xxxxxxxxxxx  [100内的自然数]   xxxxxxxxxxxx“ 既说明没有完整的读到insert的记录。



