# ==============================================================================
# SCRIPT: 04_test_clustering.R 
# ==============================================================================

library(testthat)

# Dinamismo en la ruta para evitar problemas de slash final
path_base      <- "C:/Users/iavit/OneDrive/ESPOL/Maestria en Estadistica Aplicada/Clases Maestria en Estadistica Aplicada/Modulo 9/TEC ESTADIS AVANZ PARA MINERIA DE DATOS/METODOS DE CLASIFICACION/Taller/EJER1"
path_processed <- file.path(path_base, "Data", "processed")

# --- [1] Carga de datos con verificación de existencia ---
test_that("Los archivos de datos procesados existen", {
  expect_true(file.exists(file.path(path_processed, "protein_scaled.rds")))
  expect_true(file.exists(file.path(path_processed, "wilks_results.rds")))
})

# --- [2] Pruebas de Integridad ---
test_that("Los datos escalados mantienen la consistencia dimensional", {
  data <- readRDS(file.path(path_processed, "protein_scaled.rds"))
  
  # 25 países europeos confirmados
  expect_equal(nrow(data), 25) 
  
  # Corregido: Son 10 columnas según el script 01 (4 a la 13 inclusive)
  expect_equal(ncol(data), 10)  
})

test_that("El estadístico Wilks' Lambda es válido y consistente", {
  wilks <- readRDS(file.path(path_processed, "wilks_results.rds"))
  
  # Verificación de rango: debe ser entre 0 y 1
  # Corregido: Uso de '&' para evaluación vectorizada
  expect_true(all(wilks >= 0 & wilks <= 1))
  
  # Verificación de tipo
  expect_type(wilks, "double")
  
  # Verificación de tendencia: Wilks' Lambda debe bajar al aumentar K
  expect_true(all(diff(wilks) < 0))
})