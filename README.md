# istio 故障注入 demo

## 下载代码仓库

克隆代码仓库:

```bash
git clone https://github.com/istio-demo/fault-injection.git && cd fault-injection
```

## 开启 Sidecar 自动注入

将需要部署 demo 的命名空间开启 sidecar 自动注入。

## 安装 demo 应用

确保本地 kubeconfig 配置正常，可以用 kubectl 操作集群，然后执行下面命令将 demo 应用安装到集群中:

```bash
make install
```

会安装 httpbin 作为服务端，fortio 作为压测客户端。

## 压测

执行 `make bench` 进行压测 ，会看到所有请求都成功并且响应很快:

```txt
# target 50% 0.00245455
# target 75% 0.00290909
# target 90% 0.004
# target 99% 0.0155169
# target 99.9% 0.0158582
...
Code 200 : 200 (100.0 %)
```

## 注入延时

执行以下命令为 `httpbin` 服务注入 1s 的响应延时：

```bash
make delay
```

实际会使用是下面的 `VirtualService`:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
    - fault:
        delay:
          fixedDelay: 1s
          percentage:
            value: 100
      match:
        - headers:
            end-user:
              exact: roc
      route:
        - destination:
            host: httpbin
    - route:
        - destination:
            host: httpbin
```

大概意思是：
* 只对 `roc` 的请求注入 100% 的 1s 延时（header 中带了 `end-user: roc` 的请求）。
* 其余请求不影响。

## 再次压测

先用 `make bench` 压测，可以发现与之前结果一致，再使用 `make benchroc` 进行压测（带上了 `end-user: roc` 的 header），可以看到延时增加了 1s:

```txt
# target 50% 1.0054
# target 75% 1.00625
# target 90% 1.00676
# target 99% 1.00707
# target 99.9% 1.0071
...
Code 200 : 20 (100.0 %)
```

## 注入异常状态码

执行以下命令为 `httpbin` 服务注入 500 的异常状态码：

```bash
make 500
```
实际会使用是下面的 `VirtualService`:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
    - httpbin
  http:
    - fault:
        abort:
          httpStatus: 500
          percentage:
            value: 100
      match:
        - headers:
            end-user:
              exact: roc
      route:
        - destination:
            host: httpbin
    - route:
        - destination:
            host: httpbin
```

大概意思是：
* 只对 `roc` 的请求注入 100% 的 500 异常状态码（header 中带了 `end-user: roc` 的请求）。
* 其余请求不影响。

## 再次压测

先用 `make bench` 压测，可以发现与之前结果一致，再使用 `make benchroc` 进行压测（带上了 `end-user: roc` 的 header），可以看到全部都响应了 500 的状态码:

```txt
Code 500 : 20 (100.0 %)
```
