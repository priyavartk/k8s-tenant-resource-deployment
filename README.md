# Tenant Resource Management in EKS using Simple Jenkins Pipelines


Managing resource isolation is fundamental ask by software as service vendors and it serves the purpose of other industry vertical also to logically divide resources and their permissions.

“This solution is a technical showcase of how can you create/manage/deploy tenant’s resources in multi cluster/multi-tenant setup. Solution includes setting up clusters/VPC/VPNs and jenkins for cross cluster sharing as well pipeline which uses the setup securely to manage tenants K8S resource definition  as well including terraform code”

Solution can be modified and re-used with other pipeline tools/practices following up the same structured design.

We will be designing and setting up mechanism to easily manage on boarding of new Tenant on Kubernetes cluster, this new tenant can be a client on boarding or environment segregation like Dev/QA/ Or a business unit like finance/purchase etc.



The basic building block of solution is Kubernetes “Namespace”, a Kubernetes namespace are a way to divide cluster resources between multiple users(tenants).

Resource quota/netpolicies and limits resources can be defined per tenant level.

Namespaces provide a scope for names. Names of resources need to be unique within a namespace, but not across namespaces. Namespaces cannot be nested inside one another and each Kubernetes resource can only be in one namespace.

Essentially Kubernetes [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces) help different projects, teams, or customers to share a Kubernetes cluster.

It does this by providing the following:

* A scope for [Names](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/).
* A mechanism to attach authorization and policy to a subsection of the cluster.

A cluster admin for a SaaS solution using Kubernetes, will need to manage namespaces and resource limits and network policies in these namespaces to create a defined isolation of customers. Kubernetes has default namespace called “default” for all deployments not mentioning a namespace.

What should typically a Namespace contain?

* **LimitRange** By default, containers run with unbounded [compute resources](https://kubernetes.io/docs/user-guide/compute-resources) on a Kubernetes cluster. With Resource quotas, cluster administrators can restrict the resource consumption and creation on a namespace basis. Within a namespace, a Pod or Container can consume as much CPU and memory as defined by the namespace’s resource quota. There is a concern that one Pod or Container could monopolize all of the resources. Limit Range is a policy to constrain resource by Pod or Container in a namespace.
* **ResourceQuotas** **,** **** When several users or teams share a cluster with a fixed number of nodes, there is a concern that one team could use more than its fair share of resources.

Resource quotas are a tool for administrators to address this concern.

* **Network Policy** , A network policy is a specification of how groups of [pods](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/) are allowed to communicate with each other and other network endpoints.

**EKS by default uses AWS CNI plugin**
NetworkPolicy resources use [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) to select pods and define rules which specify what traffic is allowed to the selected pods.

**How to organise Namespaces and Resources?**

In a DevOps culture enabled organisation, it becomes obvious that you manage these namespace, resources quotas and network policies in similar way like your application code so that changes to these resources can reviewed, controller, managed and deployed using Pipelines.

An organisation will have at least minimum two environments to test and deploy their applications “Dev and Prod” and ideally two separate cluster for each of them, as business and teams grow, demand for more and more environment and cluster shall become challenging to manage.

I have followed an old structure of segregating these by clusters and envs where I keep configuration of each env/cluster separately in a directory structure easy to manage. A single pipeline is enough to manage these resources provided that pipeline is passed right context of env and cluster name.

Environment and cluster specific variables can be dealt in Pipeline stages.

The sample directory structure looks  like.


```
**k8s****-****namespace****-****quotas**
**eng**
   tenant-a.yaml << tenant-a's resource definition in ENG cluster>>
**prod**
   tenant-c.yaml << tenant-b's resource definition in Prod cluster>>
notprod
   tenant-c.yaml << tenant-c's resource definiton in notprod cluser>>
**Jenkinsfile**

```


Sample tenant-a.yml will look like something this.

```
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-a
  labels:
    name: tenant-a
    environment: dev
  annotations:
    owner: tenant-a@mail.com
    contact: Tenant-A 
    business-unit: Finance
---
kind: LimitRange
apiVersion: v1
metadata:
  name: tenant-a-limit
  namespace: tenant-a
spec:
  limits:
  - type: Pod
    max:
      cpu: 4
      memory: 8Gi
  - type: Container
    default:
      cpu: 1
      memory: 1Gi
    defaultRequest:
      cpu: 200m
      memory: 200Mi
    max:
      cpu: 2
      memory: 4Gi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-a-quota
  namespace: tenant-a
spec:
  hard:
    persistentvolumeclaims: "100"
    pods: "100"
    replicationcontrollers: "100"
    resourcequotas: "1"
    requests.cpu: "24"
    requests.memory: 32Gi
    limits.cpu: "200"
    limits.memory: 192Gi
    configmaps: "100"
    secrets: "100"
    services: "200"
    services.loadbalancers: "0"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-webapp-ingress
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      role: web
  ingress:
  - ports:
    - port: 443
      protocol: TCP
    - port: 8443
      protocol: TCP
    from: []
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-service-ingress
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      role: service
  ingress:
  - ports:
    - port: 443
      protocol: TCP
    - port: 8443
      protocol: TCP
    from: []
  policyTypes:
  - Ingress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-pod-communication
  namespace: tenant-a
spec:
  podSelector: {}
  ingress:
  - from:
     - namespaceSelector:
        matchLabels:
          name: tenant-a
  egress:
  - to:
     - namespaceSelector:
        matchLabels:
          name: tenant-a
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
---
#  Access to SQL server from pods 
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-service-sqlserver-egress
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      role: service
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 192.168.0.0/16 <<vpc CIDR of RDS VPC>>  
    ports:
    - protocol: TCP
      port: 1433
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-auth0-egress
  namespace: tenant-a
spec:
  podSelector: {}
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80 
    - protocol: TCP
      port: 443
  policyTypes:
  - Egress
```


These policies can be created/tested and deployed using pipeline. Jenkins is a popular CI/CD tool used in this setup. Jenkins is also running as K8S deployment in one of EKS cluster. 

Pre-requisite for Jenkins or any other pipeline tool like gitlab runner etc.

Jenkins installed and configured with kubernetes plugin which allows to run Jenkins slave worker nodes as K8S pods. 
Jenkins should have access to jnlp-slave image (the image can be from ECR or docker hub or any other repo which Jenkins have access to).
Jenkins deployment must be configured to run with Service Account , which has permission to create/manage resources in K8S cluster. The service is deployed with annotation which allows service account to assume IAM role allowing access to ECR,Code Commit etc.
A multi Branch pipeline  job which scan this repo.
