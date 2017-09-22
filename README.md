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

```shell
curl -X POST \
  http://localhost:8080/emitor \
  -H 'content-type: application/json' \
  -d '{
    "session_id": 100001,
    "message": "Hello, World!"
}'
```