# ==============================================================================
# SCRIPT: 03_test_validation.R 
# ==============================================================================

# --- [1] Configuración de Entorno ---
library(testthat)
library(cluster)

# Definir rutas
path_base      <- "C:/Users/iavit/OneDrive/ESPOL/Maestria en Estadistica Aplicada/Clases Maestria en Estadistica Aplicada/Modulo 9/TEC ESTADIS AVANZ PARA MINERIA DE DATOS/METODOS DE CLASIFICACION/Taller/EJER1"
path_processed <- file.path(path_base, "Data", "processed")

# --- [2] Carga de Objetos para Validación ---
if (!file.exists(file.path(path_processed, "protein_scaled.rds"))) {
  stop("No se encuentran los datos procesados. Ejecuta el Script 01 y 02 primero.")
}

protein_scaled <- readRDS(file.path(path_processed, "protein_scaled.rds"))
wilks_values   <- readRDS(file.path(path_processed, "wilks_results.rds"))

# --- [3] Ejecución de Pruebas Directas ---
test_check_data <- function() {
  test_that("Integridad: Datos escalados sin valores nulos", {
    expect_equal(sum(is.na(protein_scaled)), 0)
  })
  
  test_that("Consistencia: El modelo PAM mantiene K=3", {
    set.seed(42)
    res <- pam(protein_scaled, k = 3)
    expect_equal(length(unique(res$clustering)), 3)
  })
  
  test_that("Convergencia: Wilks' Lambda disminuye monótonamente con K", {
    # Validación de la reducción de varianza no explicada
    expect_true(all(diff(wilks_values) < 0))
  })
}

test_check_data()

cat("\n--- Verificación completada ---\n")

