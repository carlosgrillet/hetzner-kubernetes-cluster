# Deploy a kubernetes cluster in Hetzner Cloud
---
## Intoduction
Over the past few months, I've spent considerable time exploring the best way to create my own Kubernetes cluster. 
Initially, I installed Kubernetes on my computer using VMware, which is an excellent setup for lab purposes and testing. 
In fact, this remains my recommended approach for learning Kubernetes. However, if you want to add more 
advanced functionalities—such as setting up a load balancer—a local setup can quickly become challenging 
and time-consuming. This is where cloud solutions shine, offering a production-like environment for managing your cluster.

The main challenge with moving to the cloud is cost. Running a Kubernetes cluster on a cloud provider can be expensive, 
especially if your goal is to host a personal website or experiment with technologies like Jenkins or ArgoCD. 
If budget is a priority, you might need to rule out solutions from hyperscale providers like AWS, Azure, or GCP. 
Even smaller providers like DigitalOcean, Linode (now Akamai Cloud), and others can be costly. 
Even their minimal configurations may exceed your expectations, and with just one node, you wouldn't 
fully leverage Kubernetes' powerful features, such as pod affinity, automated pod lifecycle management, and more.

I've been using Hetzner Cloud for the past three years, and it has consistently impressed me as a reliable and 
affordable cloud provider. Unlike some competitors, Hetzner doesn't offer a managed Kubernetes service like Linode 
Kubernetes Engine (LKE). This limitation inspired me to deploy my own cluster. After countless hours of trial and error, 
reading documentation, failing, and learning, I was able to distill everything I learned into a practical solution. 
By leveraging automation tools, I created a scalable and cost-effective Kubernetes cluster tailored to my needs.

> [!WARNING]
> From this point I assume that you already have installed Terraform, ansible and cmake, so make shure you already have it :)

## Instalation
---

### Clone the repository from GitHub
1. Create your terraform variables
```bash
git clone https://github.com/carlosgrillet/hetzner-kubernetes-cluster.git
```
or using ssh
```bash
git clone git@github.com:carlosgrillet/hetzner-kubernetes-cluster.git
```

### Prepare you terraform
2. Create your terraform variables
```bash
cp .tfvars.example .tfvars
```
and edit the file to add you Hetzner Cloud api token, to know how to get yours see [Generating an API token](https://docs.hetzner.com/cloud/api/getting-started/generating-api-token/)

```hcl
# General config
hcloud_token = "yourhcloudtoken"          # Here you put your hcloud token
ssh_key      = "path/to/your/ssh_key.pub" # Path to your SSH public key, normally located at ~/.ssh/<key>.pub
location     = "fsn1"                     # When you select the instance type from below link you will see the city code

# Control-plane config
master_count       = 1      # How many control-plane nodes you desire
master_server_type = "cx22" # Server type, see here to select the one that fits you better https://www.hetzner.com/cloud#pricing

# Workers config
worker_count       = 1      # How many workers you want in the cluster
worker_server_type = "cx22" # Server type, same that above

```

3. Initialize terraform
```bash
make init
```

4. Validate config (optional)
```bash
make validate
```

5. Review the plan (optional)
```bash
make plan
```

### Deploy to Hetzner Cloud
6. Create your terraform variables
```bash
make apply
```

## Cluster configuration
---
7. Initialize the cluster by configuring the first control-plane
```bash
make cluster-init
```

8. Add other control-plane nodes to the cluster (if your choose more than 1 master in your .tfvars)
```bash
make join-masters
```

9. Add workers to the cluster
```bash
make join-workers
```

10. Get the kubecofig file to your system
```bash
make get-kubeconfig
```
> [!NOTE]
> This will copy the file to your home directory `~/cluster-kubeconfig.yaml`.
> don't forget to run `export KUBECONFIG=~/clsuter-kubeconfig.yaml` for kubectl to use the cluster config


## Add-on: install traefik in the cluster
---
In addtion to the installation, you can also install and configure traefik using ansible. To do this you firs 
need to change the file `kubernetes/traefik-values.yaml` and add the email you want to use to generate the SSL 
sertificates.

Also feel free to change something if you need to. here you will find more documentation
[Traefik helm chart values examples](https://github.com/traefik/traefik-helm-chart/blob/master/EXAMPLES.md)
[Traefik helm chatt default values](https://github.com/traefik/traefik-helm-chart/blob/master/traefik/values.yaml)


```yaml
ports:
  web:
    redirections:
      to: websecure
      schema: https
  websecure:
    tls:
      enabled: true
      certResolver: letsencrypt
certificatesResolvers:
  letsencrypt:
    acme:
      email: youremail@mail.com # Here you change the email
      storage: /data/acme.json
      tlsChallenge: true
```

11. Install traefik in the cluster
```bash
make install-traefik
```
