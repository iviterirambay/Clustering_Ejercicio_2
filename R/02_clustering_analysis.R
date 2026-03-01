# ==============================================================================
# SCRIPT: 02_clustering_analysis.R 
# ==============================================================================

# --- [1] Configuración de Entorno ---
library(cluster)
library(factoextra)

path_base      <- "C:/Users/iavit/OneDrive/ESPOL/Maestria en Estadistica Aplicada/Clases Maestria en Estadistica Aplicada/Modulo 9/TEC ESTADIS AVANZ PARA MINERIA DE DATOS/METODOS DE CLASIFICACION/Taller/EJER1"
path_processed <- file.path(path_base, "Data", "processed")
path_plots     <- file.path(path_base, "plots")

if (!dir.exists(path_plots)) dir.create(path_plots, recursive = TRUE)

# Cargar datos pre-procesados
protein_scaled <- readRDS(file.path(path_processed, "protein_scaled.rds"))

# --- [2] Análisis Jerárquico (Pregunta a) ---
dist_matrix <- dist(protein_scaled, method = "euclidean")
methods <- c("average", "single", "complete", "ward.D2")

pdf(file.path(path_plots, "hierarchical_trees.pdf"), width = 10, height = 8)
par(mfrow = c(2, 2))
for(m in methods) {
  hc <- hclust(dist_matrix, method = m)
  plot(hc, main = paste("Método:", m), xlab = "Países", sub = "", cex = 0.7)
}
dev.off()

# --- [3] Análisis PAM y Silueta (Pregunta b) ---
# Se eligen K=3 basándose en la estructura regional europea [cite: 1, 2]
set.seed(42)
pam_res <- pam(protein_scaled, k = 3)

pdf(file.path(path_plots, "pam_analysis.pdf"))
print(fviz_cluster(pam_res, data = protein_scaled, main = "Clústeres PAM (Espacio PCA)"))
print(fviz_silhouette(pam_res))
dev.off()


# --- [4] K-means y Wilks' Lambda (Pregunta c) ---

# 1. Realizamos el PCA
pca_res <- prcomp(protein_scaled)

# 2. Seleccionamos las primeras 4 componentes 
# Esto reduce p (variables) de 10 a 4, solucionando el problema de rango
data_pca <- pca_res$x[, 1:4]

# 3. Definimos la función
calculate_wilks <- function(k, data) {
  set.seed(123) 
  km <- kmeans(data, centers = k, nstart = 25)
  # Realiza MANOVA sobre los datos proporcionados
  fit <- manova(as.matrix(data) ~ as.factor(km$cluster))
  return(summary(fit, test = "Wilks")$stats[1, 2])
}

# 4. Definimos el rango de clústeres a probar
ks <- 2:6

# 5. ¡IMPORTANTE!: Usar 'data_pca' aquí en lugar de 'protein_scaled'
wilks_stats <- sapply(ks, function(x) calculate_wilks(x, data_pca))

# Guardar y graficar
saveRDS(wilks_stats, file.path(path_processed, "wilks_results.rds"))

plot(ks, wilks_stats, type = "b", pch = 19, 
     xlab = "Número de Clústeres (k)", 
     ylab = "Wilks' Lambda",
     main = "Evolución de Wilks' Lambda (basado en PCA)")


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
mensaje_texto <- paste0("feat(tests): ", fecha_ejecucion, " | Implementar suite de validacion unitaria para modelos de clustering y calidad de datos.")
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