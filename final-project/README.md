# Lesson DB module
## Структура проєкту

```
lesson-8-9
├── backend.tf
├── charts
│   └── django-app
│       ├── Chart.yaml
│       ├── templates
│       │   ├── configmap.yaml
│       │   ├── deployment.yaml
│       │   ├── hpa.yaml
│       │   └── service.yaml
│       └── values.yaml
├── django
│   ├── Dockerfile
│   ├── Jenkinsfile
│   └── requirements.txt
├── main.tf
├── modules
│   ├── argo_cd
│   │   ├── agro_cd.tf
│   │   ├── charts
│   │   │   ├── Chart.yaml
│   │   │   ├── templates
│   │   │   │   ├── application.yaml
│   │   │   │   └── repository.yaml
│   │   │   └── values.yaml
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml
│   │   └── variables.tf
│   ├── ecr
│   │   ├── ecr.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── eks
│   │   ├── eks.tf
│   │   ├── node.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── jenkins
│   │   ├── jenkins.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   ├── values.yaml
│   │   └── variables.tf
│   ├── s3-backend
│   │   ├── dynamodb.tf
│   │   ├── outputs.tf
│   │   ├── s3.tf
│   │   └── variables.tf
│   └── vpc
│       ├── outputs.tf
│       ├── routes.tf
│       ├── variables.tf
│       └── vpc.tf
├── outputs.tf
├── README.md
└── variables.tf
```

## CI/CD Процес

### 1. Jenkins Pipeline
- **Автоматичне збирання** Docker образів з Dockerfile
- **Публікація** образів до Amazon ECR
- **Оновлення** тегів у Helm chart values.yaml
- **Commit & Push** змін до Git репозиторію

### 2. Argo CD GitOps
- **Моніторинг** Git репозиторію на зміни
- **Автоматична синхронізація** застосунків
- **Безперервне розгортання** оновлених версій

## Кроки розгортання

### 1. Ініціалізація та застосування Terraform

```bash
# Перейти до каталогу lesson-db-module
cd lesson-db-module

# Ініціалізувати Terraform
terraform init

# Перевірити план
terraform plan

# Застосувати конфігурацію
terraform apply
```

### 2. Налаштування kubectl для роботи з EKS

```bash
# Отримати конфігурацію кластера
aws eks update-kubeconfig --region eu-north-1 --name lesson-9-eks-cluster

# Перевірити з'єднання з кластером
kubectl get nodes
```

### 3. Доступ до Jenkins

```bash
# Отримати Jenkins LoadBalancer URL
kubectl get services -n jenkins

# Отримати початковий пароль Jenkins
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo

# Альтернативно, використовуйте налаштований пароль: admin123
```

### 4. Налаштування Jenkins Pipeline

1. **Увійти до Jenkins** з обліковими даними admin/admin123
2. **Запустити seed-job** для створення pipeline
3. **Налаштувати GitHub credentials** (вже налаштовані через JCasC)
4. **Запустити goit-django-docker pipeline**

### 5. Доступ до Argo CD

```bash
# Отримати Argo CD LoadBalancer URL
kubectl get services -n argocd

# Отримати початковий пароль admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Увійти як admin з отриманим паролем
```

### 8. Приклади використання модулю RDS
### RDS Module
Універсальний модуль бази даних, який підтримує обидва типи кластерів RDS і Aurora.

**Standard RDS:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  name                = "my-database"
  use_aurora         = false
  engine             = "postgres"
  engine_version     = "17.2"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20
  
  db_name            = "myapp"
  username           = "postgres"
  password           = var.postgres_password
  
  vpc_id             = module.vpc.vpc_id
  subnet_private_ids = module.vpc.private_subnet_ids
  publicly_accessible = false
}
```

**Aurora Cluster:**
```hcl
module "rds" {
  source = "./modules/rds"
  
  name                       = "aurora-cluster"
  use_aurora                = true
  engine_cluster            = "aurora-postgresql"
  engine_version_cluster    = "15.3"
  aurora_instance_count     = 2
  
  # ... other parameters
}
```

### 7. Перевірка роботи застосунку

```bash
# Перевірити Django application
kubectl get applications -n argocd
kubectl get pods -n default
kubectl get services -n default

# Отримати external IP Load Balancer Django app
kubectl get services django-app
```

## Компоненти

### EKS Кластер
- **Назва**: goit-homework-eks-cluster
- **Версія Kubernetes**: 1.28
- **Node Group**: t2.micro instances
- **Scaling**: 1-2 nodes (desired: 1)
- **OIDC Provider**: для IRSA (IAM Roles for Service Accounts)

### Jenkins
- **Namespace**: jenkins
- **Service Type**: LoadBalancer
- **Plugins**: Kubernetes, Git, Docker, Job DSL
- **Service Account**: jenkins-sa з ECR permissions
- **Kaniko**: для збирання Docker образів без Docker daemon

### Argo CD
- **Namespace**: argocd
- **Service Type**: LoadBalancer
- **GitOps Repository**: https://github.com/AndriyDmitriv/goit-devops.git
- **Auto-sync**: увімкнено
- **Self-heal**: увімкнено

### ECR Repository
- **Назва**: goit-devops-homework
- **Сканування образів**: увімкнено

### Django Application
- **Replicas**: 2
- **Autoscaling**: 2-10 pods
- **Resources**: CPU та Memory limits
- **Service**: LoadBalancer type

## Jenkins Pipeline Workflow

1. **Trigger**: Git commit до основного репозиторію
2. **Build**: Kaniko збирає Docker образ
3. **Push**: Образ завантажується до ECR
4. **Update**: Оновлюється tag у values.yaml
5. **Commit**: Зміни комітяться до Git
6. **Sync**: Argo CD підхоплює зміни та розгортає

## Argo CD Applications

- **django-app**: Моніторить django-chart у Git репозиторії
- **Auto-sync**: Автоматично застосовує зміни
- **Self-healing**: Відновлює стан при ручних змінах

## Корисні команди

### Jenkins
```bash
# Перегляд Jenkins pods
kubectl get pods -n jenkins

# Перегляд Jenkins logs
kubectl logs -f -n jenkins deployment/jenkins

# Перегляд Jenkins service
kubectl get services -n jenkins
```

### Argo CD
```bash
# Перегляд Argo CD applications
kubectl get applications -n argocd

# Синхронізація application вручну
argocd app sync django-app

# Перегляд статусу
argocd app get django-app
```

### Django Application
```bash
# Перегляд Django pods
kubectl get pods

# Перегляд logs
kubectl logs -f deployment/django-app

# Масштабування
kubectl scale deployment django-app --replicas=3

# HPA статус
kubectl get hpa
```

## Troubleshooting

### Jenkins Issues
```bash
# Перевірка Jenkins pod logs
kubectl logs -n jenkins -l app.kubernetes.io/component=jenkins-controller

# Перевірка Service Account
kubectl get serviceaccount jenkins-sa -n jenkins -o yaml

# Перевірка IAM role annotations
kubectl describe serviceaccount jenkins-sa -n jenkins
```

### Argo CD Issues
```bash
# Перевірка Argo CD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Перевірка application статусу
kubectl describe application django-app -n argocd

# Ручна синхронізація
kubectl patch application django-app -n argocd --type merge --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

## Очищення ресурсів

```bash
# Видалити Argo CD applications
kubectl delete applications --all -n argocd

# Видалити Terraform ресурси
terraform destroy
```