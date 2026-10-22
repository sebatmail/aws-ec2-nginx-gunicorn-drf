<div align="center">

# ☁️ Despliegue de API RESTful en AWS EC2 con Gunicorn y Nginx
### Sistema ToDoList & Resolución de Normalización de Bases de Datos (3FN)

[![AWS EC2](https://img.shields.io/badge/AWS-EC2%20(Ubuntu%2022.04)-FF9900?style=for-the-badge&logo=amazonec2&logoColor=white)](https://aws.amazon.com/)
[![Nginx](https://img.shields.io/badge/Nginx-Reverse%20Proxy-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![Gunicorn](https://img.shields.io/badge/Gunicorn-WSGI%20Server-499848?style=for-the-badge&logo=gunicorn&logoColor=white)](https://gunicorn.org/)
[![Django](https://img.shields.io/badge/Django-REST%20Framework-092E20?style=for-the-badge&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![Python](https://img.shields.io/badge/Python-3.12%2B-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Active-brightgreen?style=for-the-badge)](http://44.193.33.51/api/tasks/)

<p align="center">
  <b>Instituto Profesional INACAP — Área Informática y Ciberseguridad</b><br>
  <b>Asignatura:</b> Desarrollo Backend & Bases de Datos<br>
  <b>Profesor:</b> Marcelo Alvarado | <b>Unidad 3:</b> Cloud Computing & Infraestructura AWS
</p>

[🌐 Ver API en Producción](http://44.193.33.51/api/tasks/) • [🔐 Panel Admin Django](http://44.193.33.51/admin/) • [📄 Resolución Normalización (PDF)](docs/RESOLUCION_EJERCICIO_NORMALIZACION.pdf) • [💾 Script SQL (3FN)](docs/RESOLUCION_NORMALIZACION.sql)

</div>

---

## 📌 Tabla de Contenidos

- [🌐 Entorno de Producción en Vivo](#-entorno-de-producción-en-vivo)
- [🏛️ Arquitectura de la Solución Cloud](#️-arquitectura-de-la-solución-cloud)
- [📡 Endpoints de la API REST](#-endpoints-de-la-api-rest)
- [📊 Normalización de Base de Datos (Diapositiva 24)](#-normalización-de-base-de-datos-diapositiva-24)
- [🛡️ Ciberseguridad y Manejo de Secretos](#️-ciberseguridad-y-manejo-de-secretos)
- [📁 Estructura del Repositorio](#-estructura-del-repositorio)
- [⚙️ Guía de Aprovisionamiento y Despliegue](#️-guía-de-aprovisionamiento-y-despliegue)
- [👨‍💻 Autor y Evaluación](#-autor-y-evaluación)

---

## 🌐 Entorno de Producción en Vivo

El sistema se encuentra desplegado y funcionando de manera ininterrumpida (**24/7**) en una máquina virtual de **Amazon Web Services (AWS)** con IP Elástica fija asociada:

| Parámetro | Valor de Producción |
|:---|:---|
| **Proveedor Cloud** | Amazon Web Services (AWS) |
| **Servicio** | Amazon EC2 (Elastic Compute Cloud) |
| **IP Elástica Pública** | `44.193.33.51` |
| **Sistema Operativo** | Ubuntu Server 22.04 LTS (x86_64) |
| **URL API RESTful** | [`http://44.193.33.51/api/tasks/`](http://44.193.33.51/api/tasks/) |
| **URL Django Admin** | [`http://44.193.33.51/admin/`](http://44.193.33.51/admin/) |

### 🔑 Credenciales para Evaluación Docente

| Rol | Usuario | Contraseña | Alcance de Permisos |
|:---|:---|:---|:---|
| **Superusuario Administrador** | `admin` | `admin123` | Control total del sistema, modelos y usuarios |
| **Cuenta Profesor (Receta)** | `profe` | `123456` | Cuenta docente con perfil staff/superuser |

---

## 🏛️ Arquitectura de la Solución Cloud

La infraestructura implementa una arquitectura desacoplada y de alta concurrencia basada en el estándar industrial para aplicaciones Python/Django:

```
                  Cliente Web / Postman / Navegador
                                  │
                                  ▼ [HTTP / Puerto 80]
              ┌────────────────────────────────────────┐
              │           NGINX (Reverse Proxy)        │
              └────────────────────────────────────────┘
                      │                        │
                      │ [Archivos Estáticos]   │ [Solicitudes Dinámicas]
                      ▼                        ▼
           ┌──────────────────────┐  ┌─────────────────────────────────┐
           │   /home/ubuntu/apps  │  │   Socket Unix IPC               │
           │   /static/ (CSS/JS)  │  │   /home/ubuntu/apps/            │
           └──────────────────────┘  │   todolist.sock                 │
                                     └─────────────────────────────────┘
                                                       │
                                                       ▼
                                     ┌─────────────────────────────────┐
                                     │     GUNICORN (WSGI Server)      │
                                     │   Daemon Systemd (3 Workers)    │
                                     └─────────────────────────────────┘
                                                       │
                                                       ▼
                                     ┌─────────────────────────────────┐
                                     │   DJANGO REST FRAMEWORK (DRF)   │
                                     │       todolist_project          │
                                     └─────────────────────────────────┘
                                                       │
                                                       ▼
                                     ┌─────────────────────────────────┐
                                     │    Base de Datos (SQLite3)      │
                                     └─────────────────────────────────┘
```

1. **Nginx:** Recibe el tráfico web en el puerto `80`. Entrega de forma nativa los archivos estáticos de Django y DRF (`STATIC_ROOT`) reduciendo drásticamente la latencia, y redirige el tráfico dinámico hacia Gunicorn.
2. **Socket Unix (`todolist.sock`):** Mecanismo de comunicación entre procesos (IPC) local con permisos `ubuntu:www-data`, mucho más rápido y seguro que una conexión por loopback TCP (`127.0.0.1:8000`).
3. **Gunicorn:** Servidor WSGI ejecutándose como demonio controlado por **systemd** (`gunicorn.service`), permitiendo auto-recuperación ante fallos y balanceo entre 3 workers concurrentes.
4. **Django REST Framework:** Capa backend que expone los endpoints de la API y gestiona el ORM y serializadores.

---

## 📡 Endpoints de la API REST

| Método | Endpoint | Descripción | Formato Respuesta |
|:---|:---|:---|:---|
| `GET` | `/api/tasks/` | Obtiene la lista completa de tareas registradas | JSON / HTML Browsable API |
| `POST` | `/api/tasks/` | Crea una nueva tarea (`title`, `done`) | JSON (`201 Created`) |
| `GET` | `/api/tasks/{id}/` | Detalle de una tarea específica | JSON (`200 OK`) |
| `PUT` | `/api/tasks/{id}/` | Actualiza completamente una tarea | JSON (`200 OK`) |
| `PATCH` | `/api/tasks/{id}/` | Actualización parcial (ej. marcar `done=true`) | JSON (`200 OK`) |
| `DELETE`| `/api/tasks/{id}/` | Elimina una tarea | Empty (`204 No Content`) |

### Estructura del Objeto JSON (`Task`)
```json
{
  "id": 1,
  "title": "Preparar infraestructura EC2 y Elastic IP en AWS",
  "done": true
}
```

---

## 📊 Normalización de Base de Datos (Diapositiva 24)

Como parte de los requerimientos de la asignatura, se resolvió formalmente el ejercicio de la **Diapositiva 24** del material de clase (*Normalización de BD*), transformando una tabla desnormalizada (**0FN**) a **Tercera Forma Normal (3FN)**:

### 1. Diagnóstico del Estado Inicial (0FN)
* **Tabla Origen:** `Estudiante#`, `Nombre del titular`, `Salón`, `Clase#`.
* **Problema:** Redundancia severa en datos del titular y salón por cada clase inscrita, con riesgo de anomalías de inserción, modificación y borrado.

### 2. Proceso de Normalización
* **1FN (Atomicidad):** Descomposición del nombre en `Tratamiento` (*Sr./Srita.*) y `ApellidoTitular`. Clave primaria compuesta: `(CodEstudiante, CodClase)`.
* **2FN (Eliminación de dependencias parciales):** Se aíslan los datos del estudiante y salón que dependen únicamente del `CodEstudiante`.
* **3FN (Eliminación de dependencias transitivas):** Se detecta la dependencia transitiva *Estudiante $\rightarrow$ Salón $\rightarrow$ Titular*. Se extrae la entidad independiente `SALON_TITULAR`.

### 3. Esquema Relacional Final (3FN)
```
  ┌───────────────────────────┐         ┌───────────────────────────┐
  │       SALON_TITULAR       │         │        ESTUDIANTE         │
  ├───────────────────────────┤ 1     N ├───────────────────────────┤
  │ PK  NumeroSalon           │────────<│ PK  CodEstudiante         │
  │     Tratamiento           │         │ FK  NumeroSalon           │
  │     ApellidoTitular       │         └───────────────────────────┘
  └───────────────────────────┘                       │ 1
                                                      │
                                                      ▼ N
  ┌───────────────────────────┐         ┌───────────────────────────┐
  │           CLASE           │         │        INSCRIPCION        │
  ├───────────────────────────┤ 1     N ├───────────────────────────┤
  │ PK  CodClase              │────────<│ PK,FK CodEstudiante       │
  │     NombreClase           │         │ PK,FK CodClase            │
  └───────────────────────────┘         │       FechaInscripcion    │
                                        └───────────────────────────┘
```

> 📄 **Documentación completa:** Consulta el PDF detallado en [`docs/RESOLUCION_EJERCICIO_NORMALIZACION.pdf`](docs/RESOLUCION_EJERCICIO_NORMALIZACION.pdf) y el código DDL/DML en [`docs/RESOLUCION_NORMALIZACION.sql`](docs/RESOLUCION_NORMALIZACION.sql).

---

## 🛡️ Ciberseguridad y Manejo de Secretos

Siguiendo las directrices del programa de **Informática y Ciberseguridad** y las recomendaciones del estándar **OWASP**:

1. **Zero Secret Leakage:** Las claves privadas de acceso SSH (`.pem`), credenciales de bases de datos productivas y secretos de entorno **NO se versionan bajo ninguna circunstancia en este repositorio Git**.
2. **Protección por `.gitignore`:** Se implementó una lista estricta de exclusión que bloquea extensiones criptográficas (`*.pem`, `*.key`, `*.ppk`), bases de datos y entornos virtuales.
3. **Control de Acceso EC2:** La clave privada requerida para administrar el servidor (`AWS BACKEND.pem`) es administrada fuera de banda y entregada exclusivamente a través de los canales institucionales de INACAP.

---

## 📁 Estructura del Repositorio

```
.
├── manage.py                     # Entry point de Django CLI
├── requirements.txt              # Dependencias de producción
├── .gitignore                    # Reglas de exclusión de seguridad
├── README.md                     # Documentación principal del proyecto
│
├── todolist_project/             # Configuración central del proyecto Django
│   ├── settings.py               # Settings (ALLOWED_HOSTS, STATIC_ROOT, DRF)
│   ├── urls.py                   # Enrutamiento global (/api/, /admin/)
│   └── wsgi.py                   # Punto de enlace WSGI para Gunicorn
│
├── tasks/                        # Aplicación ToDoList
│   ├── models.py                 # Modelo ORM (Task)
│   ├── serializers.py            # Serializador ModelSerializer de DRF
│   ├── views.py                  # TaskViewSet (ModelViewSet)
│   └── admin.py                  # Registro en panel administrativo
│
├── deploy/                       # Archivos de infraestructura y despliegue
│   ├── nginx/
│   │   └── todolist.conf         # Configuración del proxy inverso Nginx
│   ├── systemd/
│   │   └── gunicorn.service      # Servicio demonio de Gunicorn
│   └── scripts/
│       ├── setup_deploy.sh       # Script de automatización de servidor
│       ├── create_users.py       # Creación desatendida de administradores
│       └── seed_tasks.py         # Poblado inicial de datos de prueba
│
└── docs/                         # Documentación académica y de evaluación
    ├── INFORME_FINAL_ENTREGA_PROFESOR.pdf
    ├── RESOLUCION_EJERCICIO_NORMALIZACION.pdf
    ├── RESOLUCION_NORMALIZACION.sql
    └── INSTRUCCIONES_LABORATORIO.txt
```

---

## ⚙️ Guía de Aprovisionamiento y Despliegue

Para desplegar esta arquitectura desde cero en una instancia Ubuntu Server limpia:

```bash
# 1. Conectarse a la instancia EC2 por SSH
ssh -i "AWS BACKEND.pem" ubuntu@<TU_IP_ELASTICA>

# 2. Clonar el repositorio
git clone https://github.com/sebatmail/aws-ec2-nginx-gunicorn-drf.git apps
cd apps

# 3. Dar permisos y ejecutar el script automatizado
chmod +x deploy/scripts/setup_deploy.sh
./deploy/scripts/setup_deploy.sh

# 4. Verificar estado de los servicios
sudo systemctl status nginx
sudo systemctl status gunicorn
```

---

## 👨‍💻 Autor y Evaluación

* **Estudiante:** Sebastián Torres | *Informática y Ciberseguridad*
* **Institución:** Instituto Profesional INACAP
* **Profesor Evaluador:** Marcelo Alvarado
* **Asignatura:** Desarrollo Backend & Bases de Datos
* **Fecha:** Octubre 2026
