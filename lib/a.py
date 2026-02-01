import os
import shutil

def copiar_archivos_dart(carpeta_origen, carpeta_destino):
    """
    Busca archivos .dart en la carpeta_origen (y subcarpetas)
    y los copia a la carpeta_destino.
    """
    # 1. Crear la carpeta de destino si no existe
    try:
        os.makedirs(carpeta_destino, exist_ok=True)
        print(f"✅ Carpeta de destino asegurada en: **{carpeta_destino}**")
    except OSError as e:
        print(f"❌ Error al crear la carpeta de destino {carpeta_destino}: {e}")
        return

    archivos_encontrados = 0

    # 2. Recorrer la carpeta de origen de forma recursiva (os.walk)
    #    root: ruta actual del recorrido
    #    dirs: lista de subcarpetas en root
    #    files: lista de archivos en root
    for root, dirs, files in os.walk(carpeta_origen):
        for nombre_archivo in files:
            # 3. Verificar si el archivo termina con ".dart"
            if nombre_archivo.endswith(".dart"):
                # Crear la ruta completa del archivo de origen
                ruta_origen = os.path.join(root, nombre_archivo)
                # Crear la ruta completa del archivo de destino (mismo nombre)
                ruta_destino = os.path.join(carpeta_destino, nombre_archivo)

                try:
                    # 4. Copiar el archivo
                    shutil.copy2(ruta_origen, ruta_destino)
                    print(f"   Copiado: **{nombre_archivo}** de {root}")
                    archivos_encontrados += 1
                except Exception as e:
                    print(f"❌ Error al copiar **{nombre_archivo}**: {e}")

    # 5. Resumen final
    if archivos_encontrados > 0:
        print(f"\n🎉 Proceso completado. Se copiaron **{archivos_encontrados}** archivos .dart.")
    else:
        print("\n🔍 No se encontraron archivos .dart en la carpeta de origen.")


# --- CONFIGURACIÓN ---
# ¡Asegúrate de cambiar estas rutas!
# Ruta de donde buscar (recursivamente)
CARPETA_DE_BUSQUEDA = "C:\\Users\\pedro\\StudioProjects\\HefestoCS\\lib"

# Ruta donde se copiarán todos los archivos .dart
CARPETA_DE_DESTINO = "\\Users\\pedro\\StudioProjects\\HefestoCS\\lib\\zdart"

# Ejecutar la función
if __name__ == "__main__":
    copiar_archivos_dart(CARPETA_DE_BUSQUEDA, CARPETA_DE_DESTINO)