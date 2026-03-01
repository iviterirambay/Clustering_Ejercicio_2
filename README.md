# Motor de Auditoría Nutricional: Análisis de Proteínas en Europa

Este microservicio implementa un flujo de **Aprendizaje No Supervisado** (Clustering) de alto rendimiento para la segmentación de perfiles dietéticos en 25 naciones europeas. El sistema identifica patrones de consumo proteico mediante técnicas multivariantes, permitiendo la clasificación geográfica y nutricional con rigor estadístico.

---

##  1. Arquitectura Técnica
El sistema opera mediante un pipeline de datos desacoplado en tres fases críticas:

El servicio está diseñado bajo un principio de **desacoplamiento funcional**, dividido en tres módulos de ejecución secuencial que garantizan la integridad de los datos y la reproducibilidad de los resultados.

### Diagrama de Flujo Lógico (ASCII)

```text
[ INGESTA ]           [ PROCESAMIENTO ]          [ ANÁLISIS ]           [ QA & VALIDACIÓN ]          [ OUTPUTS ]
      |                      |                       |                        |                        |
      v                      v                       v                        v                        v
 protein.txt  ----->  01_preprocessing.R  ----->  02_clustering.R  ----->  04_test_clustering.R  -----> a) Modelos Validados
 (Data Raw)          - Limpieza (Regex)         - Hierarchical          - Unit Testing (testthat)     - b) Reportes PDF
                     - Escalado (Z-score)       - PAM (K=3)             - Valid. Wilks' Lambda        - c) Dataset RDS
                     - Persistencia (.rds)      - PCA Reduction         - Integridad Dimensional      - d) Sync GitHub
```
---

## 2. Estructura del Repositorio
Siguiendo las mejores prácticas para proyectos de análisis de datos en R y estándares:

* `R/`: Lógica central y scripts de ejecución secuencial.
  * `00_conn_r_git.R`: Configuración de entorno y dependencias.
  * `01_data_preprocessing.R`: ETL, limpieza con Regex y escalado.
  * `02_clustering_analysis.R`: Modelado estadístico (PAM, Ward.D2).
* `Data/`: Gestión de activos de datos.
  * `raw/`: Fuente de datos inmutable [`protein.txt`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/Data/raw/protein.txt)
  * `processed/`: Datos transformados y serializados (`.rds, .csv`).
* `tests/`: Suite de pruebas unitarias automatizadas con el framework testthat.
  * `testthat/`: Scripts de pruebas unitarias (`04_test_clustering.R`) que aseguran la integridad del modelo.
* `plots/`: Artefactos visuales generados (PCA, Dendrogramas, Siluetas).
  * [`hierarchical_trees.pdf`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/plots/hierarchical_trees.pdf): Dendrogramas de agrupación.
  * [`pam_analysis.pdf`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/plots/pam_analysis.pdf): Análisis de siluetas y clusters.
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

### Auditoría de Calidad y Seguridad (Code Review)
**Análisis del Script** `03_test_validation.R`
* **Gestión de Rutas**: El script utiliza rutas absolutas (`C:/Users/...`). En un entorno de microservicios o CI/CD (Continuous Integration), esto provocará fallos de ejecución. Se recomienda el uso de rutas relativas basadas en el directorio del proyecto.
* **Integridad de Datos**: La validación de valores nulos y la consistencia de clústeres en PAM ($K=3$) son correctas y siguen las especificaciones del modelo.
* **Lógica de Negocio**: La prueba de Wilks' Lambda es fundamental. Al verificar que disminuye monótonamente con $K$, se asegura que la partición captura la varianza de forma incremental, validando la eficacia del PCA previo.

### Ejecución de Pruebas con `testthat`
Parte vital del script `04_test_clustering.R`. El resultado final fue:
`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 7 ]`
Esto significa que pasó las 7 pruebas que programadas. Aquí el detalle de lo validado:

#### A. Existencia de archivos (2 pruebas)
* Se confirmó que `protein_scaled.rds` (datos normalizados) y `wilks_results.rds` existen en la carpeta `Data/processed`. Si el script de preprocesamiento hubiera fallado, esta prueba te habría avisado.

#### B. Integridad de los datos (2 pruebas)
* **Filas**: Se verificó que hay exactamente **25 países** europeos.
* **Columnas**: Hay **10 variables** (las fuentes de proteína). Esto asegura que no se perdió información ni se cargó columnas extra (como IDs o nombres) en el modelo.

#### C. Consistencia estadística: Wilks' Lambda (3 pruebas)
* **Rango**: Se validó que el estadístico $\Lambda$ de Wilks esté entre $0$ y $1$.
* **Tipo**: Nos aseguramos que el resultado sea un número decimal (`double`).
* **Tendencia**: Esta es la más importante. Se validó que `diff(wilks) < 0`.
  * Explicación: A medida que se aumenta el número de clusters ($K$), la variabilidad no explicada debe disminuir. Si el $\Lambda$ de Wilks no bajara al aumentar $K$, el modelo de clasificación no estaría discriminando bien los grupos. Tus datos cumplen con la teoría.

---

## 4. Guía de Ejecución
**Instalación y Configuración**
1. **Clonar el repositorio**:

  `git clone https://github.com/iviterirambay/Clustering_Ejercicio_2.git`

2. **Configurar entorno**: Ejecutar [`00_conn_r_git.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/00_conn_r_git.R) para inicializar dependencias y variables de entorno.
3. **Ejecutar el Pipeline**:
* [`01_data_preprocessing.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/01_data_preprocessing.R): Limpieza y escalado.
* [`02_clustering_analysis.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/R/02_clustering_analysis.R): Generación de modelos y gráficos.
* [`03_testthat.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/tests/03_testthat.R): Validación de resultados.
* [`04_test_clustering.R`](https://github.com/iviterirambay/Clustering_Ejercicio_2/blob/main/tests/testthat/04_test_clustering.R): Validación de resultados.


### Motores de Segmentación
El sistema emplea un enfoque híbrido para garantizar que los clústeres sean tanto estadísticamente significativos como interpretables:

* **Clustering Jerárquico:** Evaluación de métodos (*Average, Single, Complete, Ward.D2*). Se determina que **Ward.D2** es el método óptimo al minimizar la varianza interna de los grupos.
* **PAM (Partitioning Around Medoids):** Algoritmo robusto frente a valores atípicos (outliers) para la definición de $K=3$ clústeres, utilizando medoides en lugar de centroides para mayor estabilidad.
* **Validación de Wilks' Lambda:** Evaluación de la significancia de la partición mediante la medición de la reducción de la varianza no explicada tras la reducción de dimensionalidad por **PCA** (Análisis de Componentes Principales).

> **Nota:** La arquitectura está optimizada para la reproducibilidad, permitiendo que cualquier ajuste en los hiperparámetros de segmentación se refleje automáticamente en los reportes de validación.

### Resultados del Clustering (PAM/Silhouette)
Antes de las pruebas, el log muestra una pequeña tabla de resumen del algoritmo **PAM** (Partitioning Around Medoids):

| Cluster | Size | Ave. Sil. Width |
| :--- | :--- | :--- |
| 1 | 8 | 0.25 |
|2 | 15 | 0.36 |
|3 | 2 | 0.43 |

> **¿Qué significa?** El **Cluster 3** es el más "sólido" o cohesivo (tiene el ancho de silueta más alto, **0.43**), aunque solo tiene 2 países. El **Cluster 2** es el más grande con 15 países y una estructura aceptable (0.36). En general, valores cercanos a 0.5 sugieren una estructura razonable en los datos.


---

## Registro de Cambios (Changelog)
### [1.2.2] - 2026-03-01
* **feat(qa)**: Implementación exitosa de suite de pruebas unitarias con `testthat` (7/7 tests aprobados).
* **docs**: Actualización del manual técnico con métricas reales de silueta y Wilks' Lambda.

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
**Autor:** [Irwin Viteri Rambay](https://github.com/iviterirambay)