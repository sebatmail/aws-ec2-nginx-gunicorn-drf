-- ============================================================================
-- INSTITUTO PROFESIONAL INACAP
-- CARRERA: Informática y Ciberseguridad
-- ASIGNATURA: Backend / Bases de Datos
-- PROFESOR: Marcelo Alvarado
-- ALUMNO: Entrega de Trabajo Final
-- TEMA: Resolución Ejercicio de Normalización de Base de Datos (Diapositiva 24)
-- ============================================================================

-- ============================================================================
-- 1. ELIMINACIÓN DE TABLAS PREVIAS (SI EXISTEN)
-- ============================================================================
DROP TABLE IF EXISTS INSCRIPCION;
DROP TABLE IF EXISTS CLASE;
DROP TABLE IF EXISTS ESTUDIANTE;
DROP TABLE IF EXISTS SALON_TITULAR;

-- ============================================================================
-- 2. CREACIÓN DE TABLAS EN TERCERA FORMA NORMAL (3FN)
-- ============================================================================

-- TABLA 1: SALON_TITULAR (Entidad Salón / Titular a cargo)
-- Cumple 3FN: Elimina la dependencia transitiva entre Estudiante -> Salón -> Titular
CREATE TABLE SALON_TITULAR (
    NumeroSalon INT PRIMARY KEY,
    Tratamiento VARCHAR(10) NOT NULL,       -- 'Sr.', 'Srita.', 'Dr.', etc.
    ApellidoTitular VARCHAR(100) NOT NULL   -- 'Rodriguez', 'Jimenez', etc.
);

-- TABLA 2: ESTUDIANTE (Entidad Estudiante)
-- Cumple 3FN: Los datos del estudiante dependen únicamente de su PK (CodEstudiante)
CREATE TABLE ESTUDIANTE (
    CodEstudiante INT PRIMARY KEY,
    NumeroSalon INT NOT NULL,
    CONSTRAINT FK_Estudiante_Salon FOREIGN KEY (NumeroSalon) 
        REFERENCES SALON_TITULAR(NumeroSalon)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
);

-- TABLA 3: CLASE / ASIGNATURA
-- Cumple 3FN: Identificador único y nombre atómico de la asignatura
CREATE TABLE CLASE (
    CodClase INT PRIMARY KEY,
    NombreClase VARCHAR(100) NOT NULL UNIQUE
);

-- TABLA 4: INSCRIPCION (Tabla Intermedia / Relación N:M Estudiante - Clase)
-- Cumple 3FN: Resuelve la relación muchos a muchos con clave primaria compuesta
CREATE TABLE INSCRIPCION (
    CodEstudiante INT NOT NULL,
    CodClase INT NOT NULL,
    FechaInscripcion DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY (CodEstudiante, CodClase),
    CONSTRAINT FK_Inscripcion_Estudiante FOREIGN KEY (CodEstudiante) 
        REFERENCES ESTUDIANTE(CodEstudiante)
        ON UPDATE CASCADE 
        ON DELETE CASCADE,
    CONSTRAINT FK_Inscripcion_Clase FOREIGN KEY (CodClase) 
        REFERENCES CLASE(CodClase)
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
);

-- ============================================================================
-- 3. INSERCIÓN DE DATOS ORIGINALES DEL EJERCICIO (DIAPOSITIVA 24)
-- ============================================================================

-- Inserción de Salones y Titulares
INSERT INTO SALON_TITULAR (NumeroSalon, Tratamiento, ApellidoTitular) VALUES 
(101, 'Sr.', 'Rodriguez'),
(201, 'Srita.', 'Jimenez');

-- Inserción de Estudiantes
INSERT INTO ESTUDIANTE (CodEstudiante, NumeroSalon) VALUES 
(102, 101),
(412, 201);

-- Inserción de Clases
INSERT INTO CLASE (CodClase, NombreClase) VALUES 
(1, 'Matemáticas'),
(2, 'Literatura'),
(3, 'Química'),
(4, 'Biología'),
(5, 'Geografía'),
(6, 'Cálculo');

-- Inserción de Inscripciones (Relación Estudiante - Clase)
INSERT INTO INSCRIPCION (CodEstudiante, CodClase) VALUES 
(102, 1), -- Estudiante 102 en Matemáticas
(102, 2), -- Estudiante 102 en Literatura
(102, 3), -- Estudiante 102 en Química
(412, 4), -- Estudiante 412 en Biología
(412, 5), -- Estudiante 412 en Geografía
(412, 6); -- Estudiante 412 en Cálculo

-- ============================================================================
-- 4. CONSULTA DE VERIFICACIÓN (RECONSTRUCCIÓN DE LA VISTA ORIGINAL SIN REDUNDANCIA)
-- ============================================================================
SELECT 
    e.CodEstudiante AS [Estudiante#],
    CONCAT(st.Tratamiento, ' ', st.ApellidoTitular) AS [Nombre del titular],
    st.NumeroSalon AS [Salón],
    c.NombreClase AS [Clase#]
FROM INSCRIPCION i
JOIN ESTUDIANTE e ON i.CodEstudiante = e.CodEstudiante
JOIN SALON_TITULAR st ON e.NumeroSalon = st.NumeroSalon
JOIN CLASE c ON i.CodClase = c.CodClase
ORDER BY e.CodEstudiante ASC, c.CodClase ASC;
