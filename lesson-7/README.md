## Структура проєкту

```
lesson-7/
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   ├── vpc/                 # Модуль для VPC
│   ├── ecr/                 # Модуль для ECR
│   └── eks/                 # Модуль для Kubernetes кластера
└── charts/
    └── django-app/          # Helm chart для Django застосунку
        ├── templates/
        │   ├── deployment.yaml
        │   ├── service.yaml
        │   ├── configmap.yaml
        │   ├── hpa.yaml
        │   └── serviceaccount.yaml
        ├── Chart.yaml
        └── values.yaml
```

## Кроки розгортання

### 1. Розгортання русурсів за допомогою Terraform

```bash
# Перейти до каталогу lesson-7
cd lesson-7

# Ініціалізувати Terraform
terraform init

# Перевірити план
terraform plan

# Застосувати конфігурацію
terraform apply
```

### 2. Налаштування kubectl для роботи з AWS EKS

```bash
# Отримати конфігурацію кластера
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster

# Перевірити з'єднання з кластером
kubectl get nodes
```

### 3. Створення та завантаження Docker-образу до ECR

```bash
# Отримати URL ECR репозиторію
ECR_URI=$(terraform output -raw ecr_repository_url)

# Увійти до ECR
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin $ECR_URI

# Перейти до каталогу з Django застосунком
cd ../lesson-4/django

# Створити Docker-образ
docker build -t django-app .

# Тегувати образ для ECR
docker tag django-app:latest $ECR_URI:latest

# Завантажити образ до ECR
docker push $ECR_URI:latest
```

### 4. Встановлення Helm chart

```bash
# Повернутися до каталогу lesson-7
cd ../../lesson-7

# Оновити values.yaml з URL ECR репозиторію
# Замінити значення image.repository на URL з ECR

# Встановити Helm chart
helm install django-app ./charts/django-app --set image.repository=$ECR_URI

# Перевірити статус deployment
kubectl get pods
kubectl get services
kubectl get hpa
```

### 5. Перевірка роботи застосунку

```bash
# Отримати external IP Load Balancer
kubectl get services django-app

# Дочекатися коли з'явиться EXTERNAL-IP і перейти за адресою
```

## Компоненти

### EKS Кластер
- **Назва**: goit-homework-eks-cluster
- **Версія Kubernetes**: 1.28
- **Node Group**: t3.medium instances
- **Scaling**: 1-6 nodes (desired: 2)

### ECR Repository
- **Назва**: goit-devops-homework
- **Сканування образів**: увімкнено

### Компоненти Helm Chart

#### Deployment
- **Replicas**: 2 (за замовчуванням)
- **Image**: Django app з ECR
- **Resources**: 250m CPU / 256Mi Memory (requests), 500m CPU / 512Mi Memory (limits)
- **Health checks**: liveness і readiness probes

#### Service
- **Type**: LoadBalancer
- **Port**: 80 → 8000 (Django)

#### HPA (Horizontal Pod Autoscaler)
- **Min replicas**: 2
- **Max replicas**: 6
- **CPU target**: 70%
- **Memory target**: 80%

#### ConfigMap
- Містить змінні середовища Django:
  - DEBUG=False
  - ALLOWED_HOSTS=*
  - DATABASE_* змінні
  - та інші

## Видалення ресурсів

```bash
# Видалити Helm release
helm uninstall django-app

# Видалити Terraform ресурси
terraform destroy
```