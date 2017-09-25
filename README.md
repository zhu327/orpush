# orpush

基于OpenResty的websocket推送框架

### 启动

```shell
nginx -p `pwd`/ -c conf/nginx.conf
```

### 连接

```javascript
var s = new WebSocket('ws://localhost:8080/ws');

s.onmessage = function(v){
    console.log(v.data);
}
```

### 推送

```python
import redis

r = redis.Redis(host='localhost')
r.publish('websocket', '{"message": "Hello, World!", "session_id": 100001}')
```

### 依赖

redis分支依赖于redis 2.8.17以上版本