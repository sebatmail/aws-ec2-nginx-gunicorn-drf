from tasks.models import Task

Task.objects.all().delete()

Task.objects.create(title="1. Preparar infraestructura EC2 y Elastic IP en AWS", done=True)
Task.objects.create(title="2. Configurar servidor Ubuntu con Nginx y Gunicorn", done=True)
Task.objects.create(title="3. Construir API RESTful con Django REST Framework", done=True)
Task.objects.create(title="4. Presentar despliegue y panel al Profesor Marcelo Alvarado", done=False)

print(f"Creadas {Task.objects.count()} tareas de prueba.")
