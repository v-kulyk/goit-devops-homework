#!/bin/bash

# Скрипт для автоматичного встановлення Docker, Docker Compose, Python і Django
# Автор: Кулик Володимир

set -e  # Зупинити виконання при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Без кольору

# Функція для виводу повідомлень
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функція для перевірки, чи запущений скрипт з правами sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Цей скрипт має бути запущений з правами sudo"
        print_message "Використайте: sudo $0"
        exit 1
    fi
}

# Функція для оновлення списку пакетів
update_packages() {
    print_message "Оновлення списку пакетів..."
    apt-get update -y
    print_success "Список пакетів оновлено"
}

# Функція для встановлення Docker
install_docker() {
    print_message "Перевірка наявності Docker..."
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        print_warning "Docker вже встановлено (версія: $DOCKER_VERSION)"
        return 0
    fi
    
    print_message "Встановлення Docker..."
    
    # Встановлення залежностей
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Додавання офіційного GPG ключа Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Додавання репозиторію Docker
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Оновлення списку пакетів і встановлення Docker
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin
    
    # Запуск і активація Docker
    systemctl start docker
    systemctl enable docker
    
    # Додавання поточного користувача до групи docker
    if [[ -n "$SUDO_USER" ]]; then
        usermod -aG docker "$SUDO_USER"
        print_message "Користувач $SUDO_USER додано до групи docker"
    fi
    
    print_success "Docker успішно встановлено"
}

# Функція для встановлення Docker Compose
install_docker_compose() {
    print_message "Перевірка наявності Docker Compose..."
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        print_warning "Docker Compose вже встановлено (версія: $COMPOSE_VERSION)"
        return 0
    fi
    
    print_message "Встановлення Docker Compose..."
    
    # Отримання останньої версії Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    
    # Завантаження і встановлення Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Надання прав на виконання
    chmod +x /usr/local/bin/docker-compose
    
    print_success "Docker Compose успішно встановлено (версія: $COMPOSE_VERSION)"
}

# Функція для встановлення Python
install_python() {
    print_message "Перевірка наявності Python..."
    
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [[ $PYTHON_MAJOR -ge 3 ]] && [[ $PYTHON_MINOR -ge 9 ]]; then
            print_warning "Python вже встановлено (версія: $PYTHON_VERSION)"
            
            # Перевірка та встановлення pip якщо потрібно
            if ! python3 -m pip --version &>/dev/null; then
                print_message "Встановлення pip для існуючого Python..."
                apt-get install -y python3-pip python3-venv
            fi
            
            return 0
        else
            print_message "Встановлена версія Python ($PYTHON_VERSION) застаріла. Встановлюємо нову версію..."
        fi
    fi
    
    print_message "Встановлення Python 3.9+..."
    
    # Додавання PPA для нових версій Python
    apt-get install -y software-properties-common
    add-apt-repository ppa:deadsnakes/ppa -y
    apt-get update -y
    
    # Встановлення Python 3.11 (стабільна версія)
    apt-get install -y python3.11 python3.11-venv python3.11-dev
    
    # Встановлення pip
    apt-get install -y python3-pip
    
    # Створення символічного посилання (опціонально)
    if [[ ! -L /usr/bin/python ]]; then
        ln -sf /usr/bin/python3.11 /usr/bin/python
    fi
    
    print_success "Python успішно встановлено"
}

# Функція для встановлення Django
install_django() {
    print_message "Перевірка наявності Django..."
    
    # Перевірка, чи встановлено Django
    if python3 -c "import django; print('Django version:', django.get_version())" 2>/dev/null; then
        DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
        print_warning "Django вже встановлено (версія: $DJANGO_VERSION)"
        return 0
    fi
    
    print_message "Встановлення Django..."
    
    # Перевірка наявності pip та його встановлення якщо потрібно
    if ! python3 -m pip --version &>/dev/null; then
        print_message "Встановлення pip..."
        apt-get install -y python3-pip
    fi
    
    # Спроба встановлення через системний пакетний менеджер (рекомендований підхід для Ubuntu 24.04)
    if apt-get install -y python3-django &>/dev/null; then
        if python3 -c "import django" 2>/dev/null; then
            DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())")
            print_success "Django успішно встановлено через apt (версія: $DJANGO_VERSION)"
            return 0
        fi
    fi
    
    # Якщо системний пакет недоступний, використовуємо pip з --break-system-packages
    print_warning "Системний пакет Django недоступний. Використовуємо pip з --break-system-packages..."
    print_warning "Це може вплинути на системні пакети Python. Для продакшн використовуйте віртуальне середовище!"
    
    # Оновлення pip до останньої версії
    python3 -m pip install --upgrade pip --break-system-packages
    
    # Встановлення Django з обходом обмеження
    python3 -m pip install django --break-system-packages
    
    # Перевірка успішності встановлення
    if python3 -c "import django" 2>/dev/null; then
        DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())")
        print_success "Django успішно встановлено (версія: $DJANGO_VERSION)"
        print_warning "Для розробки рекомендується використовувати віртуальне середовище:"
        print_message "python3 -m venv myproject && source myproject/bin/activate"
    else
        print_error "Помилка при встановленні Django"
        exit 1
    fi
}

# Функція для виводу підсумкової інформації
print_summary() {
    echo
    echo "    ПІДСУМОК ВСТАНОВЛЕННЯ"
    echo "======================================"
    
    # Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "${GREEN}✓${NC} Docker: $DOCKER_VERSION"
    else
        echo -e "${RED}✗${NC} Docker: не встановлено"
    fi
    
    # Docker Compose
    if command -v docker-compose &> /dev/null; then
        # Більш надійний спосіб отримання версії
        COMPOSE_VERSION=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        if [[ -z "$COMPOSE_VERSION" ]]; then
            COMPOSE_VERSION=$(docker-compose --version | sed 's/.*version \([v]*[0-9][0-9.]*\).*/\1/')
        fi
        echo -e "${GREEN}✓${NC} Docker Compose: $COMPOSE_VERSION"
    else
        echo -e "${RED}✗${NC} Docker Compose: не встановлено"
    fi
    
    # Python
    if command -v python3 &> /dev/null; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        echo -e "${GREEN}✓${NC} Python: $PYTHON_VERSION"
    else
        echo -e "${RED}✗${NC} Python: не встановлено"
    fi
    
    # Django
    if python3 -c "import django" 2>/dev/null; then
        DJANGO_VERSION=$(python3 -c "import django; print(django.get_version())")
        echo -e "${GREEN}✓${NC} Django: $DJANGO_VERSION"
    else
        echo -e "${RED}✗${NC} Django: не встановлено"
    fi
    
    echo "======================================"
    echo
}

# Головна функція
main() {
    echo "  АВТОМАТИЧНЕ ВСТАНОВЛЕННЯ DEV TOOLS"
    echo "======================================"
    echo "Встановлюємо: Docker, Docker Compose, Python, Django"
    echo "Система: $(lsb_release -d | cut -f2)"
    echo "======================================"
    echo
    
    # Перевірка прав sudo
    check_sudo
    
    # Оновлення пакетів
    update_packages
    
    # Встановлення компонентів
    install_docker
    install_docker_compose
    install_python
    install_django
    
    # Виведення підсумку
    print_summary
    
    print_success "Встановлення завершено успішно!"
}

# Запуск головної функції
main "$@"