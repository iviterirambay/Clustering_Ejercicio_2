# ==============================================================================
# SCRIPT: 00_conn_r_git.R 
# ==============================================================================

# --- [1] Dependencias ---
deps <- c("usethis", "gitcreds", "processx", "desc")
new_deps <- deps[!(deps %in% installed.packages()[, "Package"])]
if (length(new_deps)) install.packages(new_deps)
invisible(lapply(deps, library, character.only = TRUE))

# --- [2] Variables de Identidad ---
nombre_repo <- "Clustering_Ejercicio_2" 
email_user  <- "ejemplo"
nombre_user <- "iviterirambay"

# --- [3] Limpieza Profunda (Reseteo de Git) ---
if (file.exists(".git/index.lock")) {
  file.remove(".git/index.lock")
  message("Bloqueo index.lock eliminado.")
}

if (dir.exists(".git")) {
  unlink(".git", recursive = TRUE, force = TRUE)
  message("🗑️ Historial antiguo eliminado para limpiar archivos pesados.")
}

# --- [4] Reinicialización Automatizada ---
# Usamos init directamente para evitar el menú interactivo de usethis
system("git init")
system(paste0('git config user.name "', nombre_user, '"'))
system(paste0('git config user.email "', email_user, '"'))

# Optimizaciones para el archivo de 50MB
system("git config http.postBuffer 524288000")
system("git config core.compression 0")

# --- [5] Configuración de Archivos y Higiene ---
if (!file.exists("DESCRIPTION")) {
  usethis::use_description(fields = list(Package = nombre_repo, Title = "Setup Project"), check_name = FALSE)
}

# .gitignore reforzado para nunca volver a trackear archivos .txt pesados
#usethis::use_git_ignore(c(".Rhistory", ".RData", ".Rproj.user", ".DS_Store", "*.log", "data/*.txt", ".env"))

# Crear archivos .gitkeep en las carpetas faltantes
dir_crear <- c("plots", "tests")
for(d in dir_crear) {
  if(!dir.exists(d)) dir.create(d)
  file.create(file.path(d, ".gitkeep"))
}

# --- [6] Pipeline de Commit Limpio ---
message("Creando primer commit sin archivos pesados...")
system("git add .")
# Asegurar que data/*.txt no entre al stage por error
system("git rm --cached data/*.txt --ignore-unmatch") 
system('git commit -m "feat: fresh start with clean history and optimized data storage"')
system("git branch -M main")

# --- [7] Vinculación y Push Forzado ---
message("Sincronizando con GitHub...")
remote_url <- paste0("https://github.com/", nombre_user, "/", nombre_repo, ".git")

# Intentar agregar el remoto (si falla es porque ya existe, lo cual está bien)
try(system(paste0("git remote add origin ", remote_url)), silent = TRUE)

# Forzar el push para limpiar el historial de 177MB que quedó en la nube
system("git push -f -u origin main")

message("Listo! El historial ha sido reseteado y el repo está limpio.")

# ==============================================================================
# FINAL DEL SCRIPT
# ==============================================================================