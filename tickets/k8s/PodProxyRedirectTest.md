# Progress <code>[1/6]</code>

-   [X] APISnoop org-flow : [PodProxyRedirectTest.org](https://github.com/cncf/apisnoop/blob/master/tickets/k8s/PodProxyRedirectTest.org)
-   [ ] test approval issue : [kubernetes/kubernetes#](https://github.com/kubernetes/kubernetes/issues/)
-   [ ] test pr : kuberenetes/kubernetes#
-   [ ] two weeks soak start date : testgrid-link
-   [ ] two weeks soak end date :
-   [ ] test promotion pr : kubernetes/kubernetes#?

# Identifying an untested feature Using APISnoop

According to this APIsnoop query, there are still some remaining PodProxyOptions endpoints which are untested.

```sql-mode
SELECT
  operation_id,
  -- k8s_action,
  -- path,
  description,
  kind
  FROM untested_stable_core_endpoints
  -- FROM untested_stable_endpoints
  where path not like '%volume%'
  and kind like 'PodProxyOptions'
  and operation_id like '%Proxy'
 ORDER BY kind,operation_id desc
 LIMIT 25
       ;
```

```example
              operation_id              |               description                |      kind
----------------------------------------|------------------------------------------|-----------------
 connectCoreV1PutNamespacedPodProxy     | connect PUT requests to proxy of Pod     | PodProxyOptions
 connectCoreV1PostNamespacedPodProxy    | connect POST requests to proxy of Pod    | PodProxyOptions
 connectCoreV1PatchNamespacedPodProxy   | connect PATCH requests to proxy of Pod   | PodProxyOptions
 connectCoreV1OptionsNamespacedPodProxy | connect OPTIONS requests to proxy of Pod | PodProxyOptions
 connectCoreV1HeadNamespacedPodProxy    | connect HEAD requests to proxy of Pod    | PodProxyOptions
 connectCoreV1GetNamespacedPodProxy     | connect GET requests to proxy of Pod     | PodProxyOptions
 connectCoreV1DeleteNamespacedPodProxy  | connect DELETE requests to proxy of Pod  | PodProxyOptions
(7 rows)

```

As the [Apiserver proxy requires a trailing slash #4958](https://github.com/kubernetes/kubernetes/issues/4958) these endpoints are redirected to their related `PodProxyWithPath` endpoints.

# API Reference and feature documentation

-   [Kubernetes API Reference Docs](https://kubernetes.io/docs/reference/kubernetes-api/)
-   [Kubernetes API: v1.19 Pod v1 core Proxy Operations](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#-strong-proxy-operations-pod-v1-core-strong-)
-   [client-go](https://github.com/kubernetes/client-go/blob/master/kubernetes/typed)

# The mock test

## Test outline

1.  Create pod and confirm that the pod is running so that the tested endpoints can be found.

2.  Create a http.Client that checks for a redirect so that status code can be checked

3.  Loop through all http verbs, testing that the pod proxy endpoint returns the required 301 status code.

## Test the functionality in Go

-   [e2e test: "proxy connection returns a series of 301 redirections for a pod"](https://github.com/ii/kubernetes/blob/proxy-301-redirect/test/e2e/network/proxy.go#L266-L358)

# Verifying increase in coverage with APISnoop

Discover useragents:

```sql-mode
select distinct useragent from audit_event where bucket='apisnoop' and useragent not like 'kube%' and useragent not like 'coredns%' and useragent not like 'kindnetd%' and useragent like 'live%';
```

List endpoints hit by the test:

```sql-mode
select * from endpoints_hit_by_new_test where useragent like 'live%';
```

Display endpoint coverage change:

```sql-mode
select * from projected_change_in_coverage;
```

```example
   category    | total_endpoints | old_coverage | new_coverage | change_in_number
---------------|-----------------|--------------|--------------|------------------
 test_coverage |             438 |          183 |          183 |                0
(1 row)

```

# Final notes

If a test with these calls gets merged, ****test coverage will go up by 7 points****

This test is also created with the goal of conformance promotion.

---

/sig testing

/sig architecture

/area conformance