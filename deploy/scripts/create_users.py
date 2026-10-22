from django.contrib.auth import get_user_model

User = get_user_model()

# Admin
User.objects.filter(username="admin").delete()
User.objects.create_superuser("admin", "admin@example.com", "admin123")
print("Superusuario 'admin' creado con contraseña 'admin123'")

# Profe
User.objects.filter(username="profe").delete()
User.objects.create_superuser("profe", "profe@example.com", "123456")
print("Superusuario 'profe' creado con contraseña '123456'")
