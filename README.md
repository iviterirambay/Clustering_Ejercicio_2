# Motor de Auditoría Nutricional: Análisis de Proteínas en Europa

Este microservicio implementa un flujo de **Aprendizaje No Supervisado** (Clustering) de alto rendimiento para la segmentación de perfiles dietéticos en 25 naciones europeas. El sistema identifica patrones de consumo proteico mediante técnicas multivariantes, permitiendo la clasificación geográfica y nutricional con rigor estadístico.

---

##  1. Arquitectura Técnica
El sistema opera mediante un pipeline de datos desacoplado en tres fases críticas:

El servicio está diseñado bajo un principio de **desacoplamiento funcional**, dividido en tres módulos de ejecución secuencial que garantizan la integridad de los datos y la reproducibilidad de los resultados.

### Diagrama de Flujo Lógico (ASCII)

```text
[ DATOS RAW ]          [ PROCESAMIENTO ]          [ ANÁLISIS ]           [ QA & VALIDACIÓN ]          [ OUTPUTS ]
      |                        |                        |                       |                        |
      v                        v                        v                       v                        v
 protein.txt  ----->  01_preprocessing.R  ----->  02_clustering.R  ----->  03_test_validation.R  -----> a) Artefactos Finales
 (Ingesta)           - Limpieza (Regex)         - Hierarchical          - Unit Testing (testthat)     - b) Reportes PDF
                     - Escalado (Z-score)       - K-means / PCA         - Consistencia de Clusters    - c) Modelos Validados
                     - Persistencia (.rds)      - Wilks' Lambda         - Verificación de Varianza    - d) Zero Technical Debt
```
---

## 2. Estructura del Repositorio
Siguiendo las mejores prácticas para proyectos de análisis de datos en R y estándares:

* `R/`: Lógica central del negocio y scripts de procesamiento.
* `data/`: Gestión de activos de datos.
  * `raw/`: Fuente de datos inmutable.
  * `processed/`: Datos transformados y serializados (.rds, .csv).
* `tests/`: Suite de pruebas unitarias automatizadas con el framework testthat.
* `plots/`: Artefactos visuales generados (PCA, Dendrogramas, Siluetas).
* `README.md`: Documentación técnica principal.

---

## 3. Especificaciones Técnicas

El núcleo analítico se basa en un procesamiento estadístico avanzado que garantiza la comparabilidad de las variables y la robustez de las agrupaciones.

### Pipeline de Datos (ETL)
El flujo de transformación asegura que la heterogeneidad de las fuentes de datos no sesgue los algoritmos de agrupación:

* **Estandarización:** Aplicación de transformación **Z-score** para asegurar que todas las fuentes proteicas tengan el mismo peso en el cálculo de distancias:
    $$Z = \frac{x - \mu}{\sigma}$$
* **Higiene de Datos:** Limpieza de metadatos y normalización de cabeceras mediante expresiones regulares para eliminar caracteres no alfanuméricos.

### Motores de Segmentación
* **Clustering Jerárquico**: Evaluación de métodos como Average, Single, Complete y Ward.D2. Se determinó que **Ward.D2** es el más eficaz para minimizar la varianza interna de los grupos. 
    [Ver resultados de Clustering Jerárquico (PDF)](plots/hierarchical_trees.pdf)
* **PAM (Partitioning Around Medoids)**: Utilización de un algoritmo robusto frente a valores atípicos para definir $K=3$ clústeres.
* **Validación de Wilks' Lambda**: Evaluación de la significancia de la partición mediante la reducción de la varianza no explicada tras la reducción de dimensionalidad por PCA.

### Auditoría de Calidad y Seguridad (Code Review
**Análisis del Script** `03_test_validation.R`
* **Gestión de Rutas**: El script utiliza rutas absolutas (`C:/Users/...`). En un entorno de microservicios o CI/CD (Continuous Integration), esto provocará fallos de ejecución. Se recomienda el uso de rutas relativas basadas en el directorio del proyecto.
* **Integridad de Datos**: La validación de valores nulos y la consistencia de clústeres en PAM ($K=3$) son correctas y siguen las especificaciones del modelo.
* **Lógica de Negocio**: La prueba de Wilks' Lambda es fundamental. Al verificar que disminuye monótonamente con $K$, se asegura que la partición captura la varianza de forma incremental, validando la eficacia del PCA previo.

---

## 4. Guía de Ejecución
**Instalación y Configuración**
1. **Clonar el repositorio**:

  `git clone https://github.com/iviterirambay/Clustering_Ejercicio_2.git`

2. **Configurar entorno**: Ejecutar [`00_conn_r_git.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/00_conn_r_git.R) para inicializar dependencias y variables de entorno.
3. **Ejecutar el Pipeline**:
[`01_data_preprocessing.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/01_data_preprocessing.R)
[`02_clustering_analysis.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/02_clustering_analysis.R)

### Motores de Segmentación
El sistema emplea un enfoque híbrido para garantizar que los clústeres sean tanto estadísticamente significativos como interpretables:

* **Clustering Jerárquico:** Evaluación de métodos (*Average, Single, Complete, Ward.D2*). Se determina que **Ward.D2** es el método óptimo al minimizar la varianza interna de los grupos.
* **PAM (Partitioning Around Medoids):** Algoritmo robusto frente a valores atípicos (outliers) para la definición de $K=3$ clústeres, utilizando medoides en lugar de centroides para mayor estabilidad.
* **Validación de Wilks' Lambda:** Evaluación de la significancia de la partición mediante la medición de la reducción de la varianza no explicada tras la reducción de dimensionalidad por **PCA** (Análisis de Componentes Principales).

> **Nota:** La arquitectura está optimizada para la reproducibilidad, permitiendo que cualquier ajuste en los hiperparámetros de segmentación se refleje automáticamente en los reportes de validación.

---

## Registro de Cambios (Changelog)
### [1.2.1] - 2026-03-01
* **feat(test)**: Incorporación de `03_test_validation.R` para auditoría de modelos.
* **fix(arch)**: Desacoplamiento de la lógica de pruebas de la lógica de procesamiento.
* **docs**: Actualización del manual técnico para incluir la suite de pruebas unitarias.

### [1.2.0] - 2026-03-01
* **feat(core)**: Implementación de validación estadística mediante Wilks' Lambda basada en componentes principales (PCA).
* **docs(refactor)**: Reestructuración completa del README para cumplir con estándares de arquitectura de microservicios.

### [1.1.0] - 2026-02-28
* **feat:** Integración del script `01_data_preprocessing.R` para automatización de ETL.
* **refactor:** Migración de rutas absolutas a rutas relativas dinámicas.
* **fix:** Normalización de nombres de columnas eliminando caracteres no alfanuméricos.
* **docs:** Actualización de README con diagrama de flujo y guía de ejecución.

### [1.0.0] - 2024-05-24
* **feat:** Implementación inicial de análisis jerárquico y particionado.
* **fix:** Limpieza de caracteres especiales en el dataset `protein.txt`.
* **docs:** Creación de README profesional y documentación técnica.

---
**Autor:** [iviterirambay](https://github.com/iviterirambay)