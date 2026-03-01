# ==============================================================================
# SCRIPT: 01_data_preprocessing.R 
# ==============================================================================

# --- [1] Configuración de Entorno ---

path_base      <- "C:/Users/iavit/OneDrive/ESPOL/Maestria en Estadistica Aplicada/Clases Maestria en Estadistica Aplicada/Modulo 9/TEC ESTADIS AVANZ PARA MINERIA DE DATOS/METODOS DE CLASIFICACION/Taller/EJER1"
path_data      <- file.path(path_base, "Data", "raw" ,"protein.txt")
path_processed <- file.path(path_base, "Data", "processed")

# Crear directorio si no existe
if (!dir.exists(path_processed)) dir.create(path_processed, recursive = TRUE)



# --- [2] Extracción y Limpieza ---

# Importamos el archivo. header = TRUE porque la primera fila son los nombres.
# El argumento 'check.names = FALSE' evita que R cambie ".country." por "X.country."
protein_raw <- read.table(path_data, header = TRUE, sep = "", check.names = FALSE)

# Limpiamos los nombres de las columnas (quitamos los puntos extras)
colnames(protein_raw) <- gsub("\\.", "", colnames(protein_raw))

# Selección de variables numéricas para el análisis (excluimos categóricas)
# Usamos columnas de la 4 a la 13 (redmeat hasta total)
protein_numeric <- protein_raw[, 4:13]
rownames(protein_numeric) <- protein_raw$country

# Escalamiento de datos (Media 0, Desviación Estándar 1)
protein_scaled <- scale(protein_numeric)



# --- [3] Persistencia de Datos ---
saveRDS(protein_scaled, file = file.path(path_processed, "protein_scaled.rds"))
write.csv(protein_raw, file = file.path(path_processed, "protein_cleaned.csv"), row.names = FALSE)


# ==============================================================================
# Sincronización Automática con GitHub
# ==============================================================================

# Cambiar el directorio de trabajo a la raíz del proyecto para que Git funcione
nombre_repo <- "Clustering_Ejercicio_2" 
nombre_user <- "iviterirambay"
remote_url <- paste0("https://github.com/", nombre_user, "/", nombre_repo, ".git")
setwd(path_base)

# 2. Preparar el mensaje del commit
# Usamos shQuote para que los espacios y caracteres especiales no rompan el comando
fecha_ejecucion <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
mensaje_texto <- paste0("feat(eta): ", fecha_ejecucion, " | Añadir .rds protein_scaled.rds como salida")
comando_commit <- paste0('git commit -m ', shQuote(mensaje_texto))

# 3. Ejecutar Pipeline de Git
message("Iniciando carga a GitHub...")

# Agregar cambios (Respeta el .gitignore de la configuración en el script 00)
system("git add .")

# Intentar hacer el commit
try(system(comando_commit), silent = TRUE)

# 4. Sincronizar con el servidor
# Hacemos un pull primero por si acaso hubo cambios manuales en el repo de GitHub
system("git pull origin main --rebase")

# Subir los cambios
exit_code <- system("git push origin main")

if(exit_code == 0) {
  message("Sincronización exitosa: Código, datos (.gz) y outputs actualizados.")
} else {
  message("Error en el push. Revisa la consola de Git o tus credenciales.")
}


# ==============================================================================
# FINAL DEL SCRIPT
# ==============================================================================