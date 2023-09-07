## 饥荒服务器构建

### 说明

饥荒独立服务器搭建前，需要准备已经创建好的世界目录Cluster_1。

### 机器配置

2核、4G内存、1M宽带、debian或ubuntu系统。


## 服务控制

### 构建服务器

```bash
./dont_starve.sh build ./Cluster_1
```

### 停止

```bash
./dont_starve.sh stop
```

### 启动

```bash
./dont_starve.sh start
```

### 重启

```bash
./dont_starve.sh restart
```

### 更新

```bash
./dont_starve.sh update
```

### 新增存档

需要准备新世界的Cluster_1目录。

```bash
./dont_starve.sh add ./Cluster_1
```

### 移除存档

```bash
./dont_starve.sh remove Cluster_1
```

### 存档显示

```bash
./dont_starve.sh show
```

### Token

```bash
./dont_starve.sh token xxxx
```