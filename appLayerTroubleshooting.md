# app layer  troubleshooting

## Problem Statement

The TF infrastructure builds in a single go now. According to the [cluster install guide for Azure](https://www.terraform.io/docs/enterprise/install/cluster-azure.html) we should be able to visit the `installer_dashboard_endpoint` and continue.

In my case, its not accessible.

Had a look through the primary node 0 cloud-init-output.log. Some highlights:

```shell
/var/lib/cloud/scripts/per-once/install-ptfe.sh: line 138: /etc/ptfe/custom-ca-cert-url: No such file or directory

...

Your Kubernetes control-plane has initialized successfully!

...

ESC[0;32m✔ weave network deployedESC[0m
ESC[0;94m⚙  Await node readyESC[0m
ESC[0;32m✔ Master Node Ready!ESC[0m

+ kubectl get nodes
NAME                     STATUS   ROLES    AGE   VERSION
tfe-3wzxyt35-primary-0   Ready    master   34s   v1.15.3
ESC[0;32m✔ Kubernetes nodesESC[0m

+ kubectl get pods -n kube-system
NAME                       READY   STATUS              RESTARTS   AGE
coredns-5c98db65d4-4nzwx   0/1     Pending             0          32s
coredns-5c98db65d4-9z659   0/1     ContainerCreating   0          32s
kube-proxy-55c8r           1/1     Running             0          32s
```

Output from `kubectl get all`:

```shell
root@tfe-3wzxyt35-primary-0:/var/log# kubectl get all
NAME                                                         READY   STATUS             RESTARTS   AGE
pod/rek-operator-896ff74f-kdmmf                              1/1     Running            0          3h18m
pod/replicated-544bcfdc7b-gdvjt                              1/2     CrashLoopBackOff   40         3h18m
pod/replicated-premkit-7fd685d996-cl6mz                      2/2     Running            0          3h16m
pod/replicated-sidecar-controller-default-84595f9f9c-rtjvq   1/1     Running            0          3h16m
pod/retraced-api-6d465cdf5-mm4lq                             1/1     Running            0          3h15m
pod/retraced-cron-764cbd4f5b-hx2p2                           1/1     Running            0          3h15m
pod/retraced-nsqd-7f8cf585bf-2rgb4                           1/1     Running            0          3h15m
pod/retraced-postgres-db75bdc9d-5s2md                        1/1     Running            0          3h15m
pod/retraced-processor-7cc86f4997-lh7g4                      1/1     Running            0          3h15m


NAME                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/kubernetes           ClusterIP   10.96.0.1        <none>        443/TCP                      3h23m
service/nsqd                 ClusterIP   10.96.238.247    <none>        4150/TCP,4151/TCP            3h15m
service/replicated           ClusterIP   10.100.240.254   <none>        9877/TCP,9878/TCP,9881/TCP   3h18m
service/replicated-api       NodePort    10.99.61.157     <none>        9876:9876/TCP                3h18m
service/replicated-premkit   ClusterIP   10.108.19.19     <none>        9880/TCP                     3h16m
service/replicated-ui        NodePort    10.106.73.69     <none>        8800:8800/TCP                3h18m
service/retraced-api         NodePort    10.110.215.132   <none>        80:53041/TCP                 3h15m
service/retraced-postgres    ClusterIP   10.110.163.31    <none>        5432/TCP                     3h15m


NAME                                                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/rek-operator                            1/1     1            1           3h18m
deployment.apps/replicated                              0/1     1            0           3h18m
deployment.apps/replicated-premkit                      1/1     1            1           3h16m
deployment.apps/replicated-sidecar-controller-default   1/1     1            1           3h16m
deployment.apps/retraced-api                            1/1     1            1           3h15m
deployment.apps/retraced-cron                           1/1     1            1           3h15m
deployment.apps/retraced-nsqd                           1/1     1            1           3h15m
deployment.apps/retraced-postgres                       1/1     1            1           3h15m
deployment.apps/retraced-processor                      1/1     1            1           3h15m

NAME                                                               DESIRED   CURRENT   READY   AGE
replicaset.apps/rek-operator-896ff74f                              1         1         1       3h18m
replicaset.apps/replicated-544bcfdc7b                              1         1         0       3h18m
replicaset.apps/replicated-premkit-7fd685d996                      1         1         1       3h16m
replicaset.apps/replicated-sidecar-controller-default-84595f9f9c   1         1         1       3h16m
replicaset.apps/retraced-api-6d465cdf5                             1         1         1       3h15m
replicaset.apps/retraced-cron-764cbd4f5b                           1         1         1       3h15m
replicaset.apps/retraced-nsqd-7f8cf585bf                           1         1         1       3h15m
replicaset.apps/retraced-postgres-db75bdc9d                        1         1         1       3h15m
replicaset.apps/retraced-processor-7cc86f4997                      1         1         1       3h15m
```

I am now seeing the same problems with start up as reported [here](https://github.com/hashicorp/terraform-azurerm-terraform-enterprise/issues/46)

From the CLI on the affected VM:
`kubectl describe pod replicated-544bcfdc7b-gdvjt`

Events:
  Type     Reason   Age                       From                             Message
  ----     ------   ----                      ----                             -------
  Normal   Pulled   34m (x48 over 4h25m)      kubelet, tfe-3wzxyt35-primary-0  Container image "quay.io/replicated/replicated:stable-2.39.2" already present on machine
  Warning  BackOff  4m57s (x1118 over 4h22m)  kubelet, tfe-3wzxyt35-primary-0  Back-off restarting failed container

Then we can do a `kubectl logs replicated-544bcfdc7b-gdvjt replicated`

```shell
ERRO 2019-11-08T04:34:16+00:00 marketlicense/license.go:95 license data is invalid
ERRO 2019-11-08T04:34:16+00:00 daemon/daemon.go:393 License bootstrap failed: install license online: import license properties: license data is invalid
```

Same problem as reported above.
