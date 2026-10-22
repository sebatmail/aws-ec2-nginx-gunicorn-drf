#!/bin/bash
set -e

echo "=== Configurando Django ToDoList ==="
cd /home/ubuntu/apps
source venv/bin/activate

# 1. Crear proyecto si no existe
if [ ! -f manage.py ]; then
    django-admin startproject todolist_project .
fi

# 2. Crear app tasks si no existe
if [ ! -d tasks ]; then
    python manage.py startapp tasks
fi

# 3. tasks/models.py
cat << 'EOF' > tasks/models.py
from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=200)
    done = models.BooleanField(default=False)

    def __str__(self):
        return self.title
EOF

# 4. tasks/serializers.py
cat << 'EOF' > tasks/serializers.py
from rest_framework import serializers
from .models import Task

class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = '__all__'
EOF

# 5. tasks/views.py
cat << 'EOF' > tasks/views.py
from rest_framework import viewsets
from .models import Task
from .serializers import TaskSerializer

class TaskViewSet(viewsets.ModelViewSet):
    queryset = Task.objects.all()
    serializer_class = TaskSerializer
EOF

# 6. todolist_project/urls.py
cat << 'EOF' > todolist_project/urls.py
from django.contrib import admin
from django.urls import path, include
from rest_framework import routers
from tasks.views import TaskViewSet

router = routers.DefaultRouter()
router.register(r'tasks', TaskViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
]
EOF

# 7. Actualizar todolist_project/settings.py
python3 - << 'PYEOF'
import re

with open("todolist_project/settings.py", "r") as f:
    content = f.read()

# ALLOWED_HOSTS
content = re.sub(r"ALLOWED_HOSTS\s*=\s*\[.*?\]", "ALLOWED_HOSTS = ['*']", content, flags=re.DOTALL)

# INSTALLED_APPS
if "'rest_framework'" not in content:
    content = content.replace(
        "INSTALLED_APPS = [",
        "INSTALLED_APPS = [\n    'rest_framework',\n    'tasks',"
    )

# STATIC_ROOT
if "STATIC_ROOT" not in content:
    content += "\nSTATIC_ROOT = '/home/ubuntu/apps/static/'\n"

with open("todolist_project/settings.py", "w") as f:
    f.write(content)
PYEOF

# 8. Migraciones y estáticos
python manage.py makemigrations tasks
python manage.py migrate
python manage.py collectstatic --noinput

# 9. Ajustar permisos de usuario y carpetas
echo "=== Configurando permisos de usuario y grupos ==="
sudo usermod -aG www-data ubuntu
sudo usermod -aG ubuntu www-data
sudo chmod 750 /home/ubuntu
sudo chmod 770 /home/ubuntu/apps
sudo chown -R ubuntu:www-data /home/ubuntu/apps/static
sudo chmod -R 755 /home/ubuntu/apps/static

# 10. Configurar servicio Systemd para Gunicorn
echo "=== Creando gunicorn.service ==="
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for Django ToDoList
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/apps
ExecStart=/home/ubuntu/apps/venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/apps/todolist.sock todolist_project.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# 11. Configurar Nginx
echo "=== Configurando Nginx ==="
sudo tee /etc/nginx/sites-available/todolist > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /home/ubuntu/apps/static/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/ubuntu/apps/todolist.sock;
    }

    error_log /var/log/nginx/todolist_error.log;
    access_log /var/log/nginx/todolist_access.log;
}
EOF

# Habilitar sitio Nginx
sudo ln -sf /etc/nginx/sites-available/todolist /etc/nginx/sites-enabled/todolist
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# 12. Iniciar y reiniciar servicios
echo "=== Iniciando servicios ==="
sudo systemctl daemon-reload
sudo systemctl restart gunicorn
sudo systemctl enable gunicorn
sudo systemctl restart nginx
sudo systemctl enable nginx

# 13. Ajustar permisos del socket si se ha creado
if [ -S /home/ubuntu/apps/todolist.sock ]; then
    sudo chown ubuntu:www-data /home/ubuntu/apps/todolist.sock
    sudo chmod 660 /home/ubuntu/apps/todolist.sock
fi

echo "=== Verificación ==="
sudo systemctl is-active gunicorn
sudo systemctl is-active nginx
curl -s -I http://localhost/api/tasks/

echo "=== Despliegue completado con éxito ==="
