# GoIT DevOps Фінальний Проєкт - Посібник з Розгортання

## Зміст
- [Огляд Архітектури](#огляд-архітектури)
- [Передумови](#передумови)
- [Налаштування AWS](#налаштування-aws)
- [Покрокове Розгортання](#покрокове-розгортання)
- [Перевірка Компонентів](#перевірка-компонентів)
- [Доступ до Сервісів](#доступ-до-сервісів)
- [Налаштування Моніторингу](#налаштування-моніторингу)
- [Усунення Несправностей](#усунення-несправностей)
- [Управління Витратами](#управління-витратами)
- [Інструкції з Очищення](#інструкції-з-очищення)

## Огляд Архітектури

Цей проєкт реалізує повний CI/CD конвеєр з GitOps, використовуючи наступні компоненти:

```
┌─────────────────────────────────────────────────────────────────┐
│                           AWS Cloud                             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────────┐ │
│  │     VPC     │    │     ECR      │    │         S3          │ │
│  │   3 AZs     │    │  Container   │    │   Terraform        │ │
│  │Public/Priv  │    │  Registry    │    │     State          │ │
│  └─────────────┘    └──────────────┘    └─────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    EKS Cluster                              │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Jenkins   │  │   Argo CD   │  │     Monitoring      │ │ │
│  │  │   CI/CD     │  │   GitOps    │  │ Prometheus/Grafana  │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │                Django Застосунок                       │ │ │
│  │  │           Автомасштабування (HPA: 2-10 подів)          │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    RDS PostgreSQL                           │ │
│  │              (Multi-AZ доступно)                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Ключові Компоненти:
- **Інфраструктура**: VPC з публічними/приватними підмережами в 3 зонах доступності
- **Реєстр Контейнерів**: ECR для зберігання Docker образів
- **Kubernetes**: EKS кластер з керованими групами вузлів
- **CI/CD**: Jenkins з Kaniko для контейнеризованої збірки
- **GitOps**: Argo CD для автоматизованих розгортань
- **База Даних**: RDS PostgreSQL з резервним копіюванням та шифруванням
- **Моніторинг**: Стек Prometheus + Grafana
- **Управління Станом**: S3 + DynamoDB для стану Terraform

## Передумови

### Необхідні Інструменти
Переконайтеся, що у вас встановлені наступні інструменти на локальній машині:

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform (>= 1.0)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Git
sudo apt-get update && sudo apt-get install git -y
```

### Перевірка Версій
```bash
aws --version          # AWS CLI 2.x
terraform --version    # >= 1.0
kubectl version --client
helm version
git --version
```

### Вимоги до AWS Акаунту
- AWS акаунт з адміністративним доступом
- Програмний доступ (Access Key ID + Secret Access Key)
- Доступні ліміти сервісів:
  - VPC: 1 (за замовчуванням: 5)
  - EKS кластери: 1 (за замовчуванням: 100)
  - EC2 інстанси: 3-5 (за замовчуванням: 20)
  - RDS інстанси: 1 (за замовчуванням: 40)

## Налаштування AWS

### 1. Налаштування AWS Облікових Даних
```bash
# Метод 1: AWS CLI Configure
aws configure
# Введіть ваш Access Key ID, Secret Access Key, Region (eu-north-1), та формат виводу (json)

# Метод 2: Змінні Середовища
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-north-1"

# Метод 3: Файл AWS Облікових Даних
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = your-access-key
aws_secret_access_key = your-secret-key
EOF

cat > ~/.aws/config << EOF
[default]
region = eu-north-1
output = json
EOF
```

### 2. Перевірка Доступу до AWS
```bash
# Тест підключення до AWS
aws sts get-caller-identity
aws ec2 describe-regions --region eu-north-1

# Перевірка доступних зон доступності в eu-north-1
aws ec2 describe-availability-zones --region eu-north-1
```

### 3. Створення GitHub Personal Access Token
1. Перейдіть до GitHub Settings → Developer settings → Personal access tokens
2. Згенеруйте новий токен з дозволами:
   - `repo` (Повний контроль приватних репозиторіїв)
   - `workflow` (Оновлення GitHub Action workflows)
   - `admin:repo_hook` (Повний контроль хуків репозиторію)
3. Скопіюйте токен для подальшого використання

## Покрокове Розгортання

### Крок 1: Клонування та Налаштування

```bash
# Клонування репозиторію
git clone <your-repository-url>
cd final-project

# Створення terraform.tfvars з шаблону
cp terraform.tfvars.example terraform.tfvars

# Редагування terraform.tfvars з вашими значеннями
nano terraform.tfvars
```

### Крок 2: Налаштування Змінних

Відредагуйте `terraform.tfvars` з вашими конкретними значеннями:

```hcl
# Обов'язково: Замініть на ваші значення
aws_region = "eu-north-1"
bucket_name = "your-unique-bucket-name-here"  # Має бути глобально унікальним
github_username = "your-github-username"
github_token = "your-github-token"
postgres_password = "your-secure-password"

# Опціонально: Налаштуйте за потребою
availability_zones = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
vpc_name = "goit-homework-vpc"
ecr_name = "goit-devops-homework"
postgres_db = "djangoapp"
postgres_user = "postgres"

# Теги для організації ресурсів
common_tags = {
  Environment = "final-project"
  Project     = "goit-devops-homework"
  Owner       = "your-name"
}
```

### Крок 3: Ініціалізація Terraform

```bash
# Ініціалізація Terraform (завантаження провайдерів та модулів)
terraform init

# Валідація конфігурації
terraform validate

# Планування розгортання (перегляд того, що буде створено)
terraform plan
```

### Крок 4: Розгортання Інфраструктури

```bash
# Застосування конфігурації (це займе 15-20 хвилин)
terraform apply

# Перегляньте план та введіть 'yes' для продовження
# Очікувана кількість ресурсів для створення: ~50-70 ресурсів
```

### Крок 5: Налаштування kubectl

```bash
# Оновлення kubeconfig для доступу до EKS кластера
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster

# Перевірка доступу до кластера
kubectl get nodes
kubectl get namespaces
```

## Перевірка Компонентів

### 1. Перевірка Інфраструктури

```bash
# Перевірка VPC та підмереж
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=goit-homework-vpc"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(terraform output -raw vpc_id)"

# Перевірка EKS кластера
aws eks describe-cluster --name goit-homework-eks-cluster --region eu-north-1
kubectl get nodes -o wide

# Перевірка ECR репозиторію
aws ecr describe-repositories --repository-names goit-devops-homework --region eu-north-1

# Перевірка RDS інстансу
aws rds describe-db-instances --region eu-north-1
```

### 2. Перевірка Kubernetes Сервісів

```bash
# Перевірка всіх просторів імен
kubectl get namespaces

# Перевірка розгортання Jenkins
kubectl get pods -n jenkins
kubectl get services -n jenkins

# Перевірка розгортання Argo CD
kubectl get pods -n argocd
kubectl get services -n argocd

# Перевірка стеку моніторингу
kubectl get pods -n monitoring
kubectl get services -n monitoring

# Перевірка постійних томів
kubectl get pv
kubectl get pvc -A
```

### 3. Перевірка Стану Застосунків

```bash
# Перевірка стану Jenkins
kubectl exec -n jenkins deployment/jenkins -- curl -f http://localhost:8080/login

# Перевірка стану Argo CD
kubectl exec -n argocd deployment/argocd-server -- curl -f http://localhost:8080/healthz

# Перевірка стану Prometheus
kubectl exec -n monitoring deployment/prometheus-server -- curl -f http://localhost:9090/-/healthy

# Перевірка стану Grafana
kubectl exec -n monitoring deployment/grafana -- curl -f http://localhost:3000/api/health
```

## Доступ до Сервісів

### Команди Переадресації Портів

#### Jenkins (Порт 8080)
```bash
# Переадресація Jenkins на localhost:8080
kubectl port-forward -n jenkins svc/jenkins 8080:80

# Отримання пароля адміністратора Jenkins
kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password

# Доступ: http://localhost:8080
# Користувач: admin
# Пароль: (з команди вище)
```

#### Argo CD (Порт 8081)
```bash
# Переадресація Argo CD на localhost:8081
kubectl port-forward -n argocd svc/argocd-server 8081:80

# Отримання пароля адміністратора Argo CD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Доступ: http://localhost:8081
# Користувач: admin
# Пароль: (з команди вище)
```

#### Grafana (Порт 3000)
```bash
# Переадресація Grafana на localhost:3000
kubectl port-forward -n monitoring svc/grafana 3000:80

# Отримання пароля адміністратора Grafana (за замовчуванням: admin123)
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Доступ: http://localhost:3000
# Користувач: admin
# Пароль: admin123 (або з команди вище)
```

#### Prometheus (Порт 9090)
```bash
# Переадресація Prometheus на localhost:9090
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Доступ: http://localhost:9090
```

### Зовнішній Доступ (Альтернатива)

Якщо ви віддаєте перевагу зовнішньому доступу через LoadBalancer:

```bash
# Отримання зовнішніх IP (може зайняти кілька хвилин для призначення)
kubectl get services -n jenkins
kubectl get services -n argocd
kubectl get services -n monitoring

# Спостереження за призначенням EXTERNAL-IP
kubectl get services -n monitoring -w
```

## Налаштування Моніторингу

### Налаштування Дашбордів Grafana

1. **Доступ до Grafana** через переадресацію портів або зовнішню IP
2. **Вхід** з обліковими даними адміністратора
3. **Перевірка Джерела Даних**: 
   - Перейти до Configuration → Data Sources
   - Підтвердити, що Prometheus налаштований: `http://prometheus-server:80`

4. **Імпорт Додаткових Дашбордів**:
   ```
   ID Дашборду: 7249 - Kubernetes Cluster Monitoring
   ID Дашборду: 1860 - Node Exporter Full
   ID Дашборду: 6417 - Kubernetes Pods
   ID Дашборду: 8588 - Kubernetes Deployment
   ```

### Кастомні Метрики для Django Застосунку

Додайте до вашого Django застосунку:

```python
# У вашому Django settings.py або окремому додатку метрик
from prometheus_client import Counter, Histogram, generate_latest
import time

# Метрики
REQUEST_COUNT = Counter('django_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('django_request_duration_seconds', 'Request latency')

# У вашому middleware або views
REQUEST_COUNT.labels(method='GET', endpoint='/api/health').inc()

# Ендпоінт метрик
def metrics_view(request):
    return HttpResponse(generate_latest(), content_type='text/plain')
```

Додайте анотації до вашого Django розгортання:

```yaml
# У вашому Kubernetes розгортанні
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8000"
    prometheus.io/path: "/metrics"
```

### Правила Алертів

Створіть кастомні правила алертів у `monitoring/alerts.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-alerts
  namespace: monitoring
data:
  alerts.yaml: |
    groups:
    - name: django-app
      rules:
      - alert: DjangoAppDown
        expr: up{job="django-app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Django застосунок недоступний"
          
    - name: kubernetes
      rules:
      - alert: NodeNotReady
        expr: kube_node_status_condition{condition="Ready",status="true"} == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Вузол {{ $labels.node }} не готовий"
```

## Усунення Несправностей

### Поширені Проблеми та Рішення

#### 1. Проблеми Terraform

**Проблема**: `bucket_name` вже існує
```bash
# Рішення: Використайте унікальне ім'я бакету
sed -i 's/your-unique-bucket-name-here/your-name-$(date +%s)/g' terraform.tfvars
```

**Проблема**: AWS облікові дані не знайдені
```bash
# Рішення: Перевірте конфігурацію AWS
aws sts get-caller-identity
aws configure list
```

**Проблема**: Перевищені ліміти ресурсів
```bash
# Рішення: Перевірте та запросіть збільшення лімітів
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
```

#### 2. Проблеми EKS

**Проблема**: Неможливо підключитися до EKS кластера
```bash
# Рішення: Оновіть kubeconfig та перевірте IAM дозволи
aws eks update-kubeconfig --region eu-north-1 --name goit-homework-eks-cluster
kubectl config current-context
kubectl auth can-i get pods --all-namespaces
```

**Проблема**: Вузли не приєднуються до кластера
```bash
# Рішення: Перевірте статус групи вузлів та групи безпеки
aws eks describe-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group
kubectl get nodes
kubectl describe nodes
```

#### 3. Проблеми Застосунків

**Проблема**: Поди застрягли в стані Pending
```bash
# Рішення: Перевірте ресурси та ємність вузлів
kubectl describe pod <pod-name> -n <namespace>
kubectl top nodes
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Проблема**: Помилки ImagePullBackOff
```bash
# Рішення: Перевірте дозволи ECR та існування образу
aws ecr describe-images --repository-name goit-devops-homework
kubectl describe pod <pod-name> -n <namespace>
```

#### 4. Проблеми Jenkins

**Проблема**: Под Jenkins не запускається
```bash
# Рішення: Перевірте логи та постійний том
kubectl logs -n jenkins deployment/jenkins
kubectl get pvc -n jenkins
kubectl describe pvc -n jenkins
```

**Проблема**: Jenkins не може відправити до ECR
```bash
# Рішення: Перевірте дозволи IRSA
kubectl describe serviceaccount jenkins-sa -n jenkins
aws iam get-role --role-name jenkins-role
```

#### 5. Проблеми Моніторингу

**Проблема**: Prometheus не збирає метрики з цілей
```bash
# Рішення: Перевірте виявлення сервісів та мережеві політики
kubectl exec -n monitoring deployment/prometheus-server -- wget -qO- http://localhost:9090/api/v1/targets
kubectl get networkpolicies -A
```

**Проблема**: Дашборди Grafana не завантажуються
```bash
# Рішення: Перевірте джерело даних та підключення
kubectl exec -n monitoring deployment/grafana -- curl -f http://prometheus-server:80/api/v1/query?query=up
```

### Команди Відладки

```bash
# Загальна відладка
kubectl get events --sort-by=.metadata.creationTimestamp -A
kubectl get pods -A -o wide
kubectl top nodes
kubectl top pods -A

# Логи
kubectl logs -n jenkins deployment/jenkins --previous
kubectl logs -n argocd deployment/argocd-server -f
kubectl logs -n monitoring deployment/prometheus-server -c prometheus

# Використання ресурсів
kubectl describe node
kubectl get resourcequotas -A
kubectl get limitranges -A

# Мережа
kubectl get services -A
kubectl get ingress -A
kubectl get networkpolicies -A
```

## Управління Витратами

### Очікувані Щомісячні Витрати (eu-north-1)

| Сервіс | Конфігурація | Очікувані Витрати/Місяць |
|---------|--------------|--------------------------|
| EKS Кластер | 1 кластер | $73 |
| EC2 Інстанси | 2x t2.micro вузли | $17 |
| RDS PostgreSQL | db.t3.medium | $31 |
| ALB/NLB | 2 балансувальники навантаження | $22 |
| ECR | 1GB зберігання | $0.10 |
| S3 | Зберігання стану | $1 |
| **Всього** | | **~$144/місяць** |

### Поради з Оптимізації Витрат

1. **Використовуйте Spot Інстанси** для не-продакшн середовищ:
```hcl
# У конфігурації групи вузлів EKS
instance_types = ["t3.medium"]
capacity_type = "SPOT"
```

2. **Конфігурація Автомасштабування**:
```hcl
# Мінімізуйте витрати під час низького використання
desired_capacity = 1
min_capacity = 1
max_capacity = 3
```

3. **Заплановані Зупинки**:
```bash
# Створіть скрипт для зменшення масштабу після робочих годин
kubectl scale deployment --replicas=0 -n jenkins jenkins
kubectl scale deployment --replicas=0 -n argocd argocd-server
```

### Моніторинг Витрат

```bash
# Перевірка поточних витрат
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE

# Налаштування алертів біллінгу (замініть на вашу електронну пошту)
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget-alert.json
```

Створіть `budget-alert.json`:
```json
{
  "BudgetName": "EKS-Monthly-Budget",
  "BudgetLimit": {
    "Amount": "200",
    "Unit": "USD"
  },
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST",
  "CostFilters": {
    "Service": ["Amazon Elastic Kubernetes Service", "Amazon Elastic Compute Cloud - Compute"]
  }
}
```

## Інструкції з Очищення

### ⚠️ Важливо: Повне Очищення Інфраструктури

**ПОПЕРЕДЖЕННЯ**: Переконайтеся в повному очищенні, щоб уникнути неочікуваних витрат!

### Метод 1: Terraform Destroy (Рекомендований)

```bash
# Перейдіть до каталогу проєкту
cd final-project

# Знищіть всі ресурси (це може зайняти 10-15 хвилин)
terraform destroy

# Підтвердіть, введіть 'yes' при запиті
# Це видалить ВСІ ресурси, створені Terraform
```

### Метод 2: Ручне Очищення (якщо Terraform не працює)

Якщо `terraform destroy` не працює, очистіть вручну в такому порядку:

#### 1. Видалення Kubernetes Ресурсів
```bash
# Спочатку видаліть всі застосунки
kubectl delete applications -n argocd --all

# Видаліть Helm релізи
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring

# Видаліть простори імен
kubectl delete namespace jenkins argocd monitoring
```

#### 2. Видалення EKS Ресурсів
```bash
# Видалення груп вузлів
aws eks delete-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group

# Очікування завершення видалення групи вузлів
aws eks wait nodegroup-deleted --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group

# Видалення кластера
aws eks delete-cluster --name goit-homework-eks-cluster
```

#### 3. Видалення RDS Ресурсів
```bash
# Видалення RDS інстансу (пропустити знімок, якщо не потрібен)
aws rds delete-db-instance \
  --db-instance-identifier djangoapp-db \
  --skip-final-snapshot \
  --delete-automated-backups
```

#### 4. Видалення VPC Ресурсів
```bash
# Видалення NAT Gateway
aws ec2 describe-nat-gateways --query 'NatGateways[*].NatGatewayId' --output text | xargs -n1 aws ec2 delete-nat-gateway --nat-gateway-id

# Видалення Internet Gateway
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=goit-homework-vpc" --query 'Vpcs[0].VpcId' --output text)
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Видалення VPC
aws ec2 delete-vpc --vpc-id $VPC_ID
```

#### 5. Видалення ECR Репозиторію
```bash
# Видалення ECR репозиторію та всіх образів
aws ecr delete-repository --repository-name goit-devops-homework --force
```

#### 6. Видалення S3 Бакету
```bash
# Очищення та видалення S3 бакету
BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "your-bucket-name")
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME
```

#### 7. Видалення DynamoDB Таблиці
```bash
# Видалення DynamoDB таблиці
aws dynamodb delete-table --table-name terraform-locks
```

### Перевірка Очищення

```bash
# Перевірка відсутності EKS кластерів
aws eks list-clusters

# Перевірка відсутності RDS інстансів
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier'

# Перевірка відсутності ECR репозиторіїв
aws ecr describe-repositories

# Перевірка VPC (має показувати тільки default VPC)
aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`]'

# Перевірка на залишкові EC2 інстанси
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name!=`terminated`]'
```

### Фінальна Перевірка Витрат

```bash
# Перевірка витрат поточного місяця після очищення
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Скрипт Екстреного Очищення

Створіть `emergency-cleanup.sh`:
```bash
#!/bin/bash
set -e

echo "🚨 ЕКСТРЕНЕ ОЧИЩЕННЯ - Це видалить ВСІ ресурси проєкту!"
echo "Натисніть Ctrl+C для скасування, або зачекайте 10 секунд для продовження..."
sleep 10

# Terraform destroy
echo "Запуск terraform destroy..."
terraform destroy -auto-approve || echo "Terraform destroy не вдався, продовжуємо з ручним очищенням..."

# Ручне очищення
echo "Виконання ручного очищення..."
kubectl delete namespace jenkins argocd monitoring --ignore-not-found=true

# Видалення EKS кластера
aws eks delete-nodegroup --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group || true
aws eks wait nodegroup-deleted --cluster-name goit-homework-eks-cluster --nodegroup-name goit-homework-node-group || true
aws eks delete-cluster --name goit-homework-eks-cluster || true

# Видалення інших ресурсів
aws rds delete-db-instance --db-instance-identifier djangoapp-db --skip-final-snapshot --delete-automated-backups || true
aws ecr delete-repository --repository-name goit-devops-homework --force || true

echo "✅ Екстрене очищення завершено. Будь ласка, перевірте в AWS Console!"
```

### 📞 Підтримка

Якщо у вас виникають проблеми:

1. **Перевірте AWS CloudFormation** консоль на завислі стеки
2. **Переглянь AWS CloudTrail** для детальних логів помилок
3. **Зверніться до AWS Support** для проблем з видаленням ресурсів
4. **Використовуйте AWS CLI** з прапором `--debug` для детальної інформації про помилки

Пам'ятайте: Повне очищення є критично важливим для уникнення неочікуваних витрат!

---

## Підсумок

Цей посібник з розгортання надає всебічні інструкції для розгортання повної DevOps інфраструктури з можливостями моніторингу. Налаштування включає:

- ✅ **Інфраструктура як Код** з Terraform
- ✅ **Оркестрація Kubernetes** з EKS
- ✅ **CI/CD конвеєр** з Jenkins та Kaniko
- ✅ **GitOps розгортання** з Argo CD
- ✅ **Комплексний моніторинг** з Prometheus та Grafana
- ✅ **Управління базою даних** з RDS PostgreSQL
- ✅ **Реєстр контейнерів** з ECR
- ✅ **Управління витратами** та процедури очищення

Дотримуйтесь кроків уважно, і пам'ятайте очистити ресурси після завершення роботи, щоб уникнути непотрібних витрат!
```