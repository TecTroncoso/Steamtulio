# Instalador de Luatools (Legacy) + Millennium + Steamtools

Este es un script de instalación desatendida en **PowerShell** diseñado para configurar un entorno completo de personalización de Steam utilizando la versión heredada (legacy) de **Millennium (v2.36.4)**, **Steamtools** y el **plugin de Luatools**.

El script se encarga de automatizar todo el proceso, desde la instalación del propio Steam hasta la descarga y configuración de los plugins, manejando dependencias sin requerir intervención manual del usuario.

## 🚀 Características y Flujo de Ejecución

1. **Verificación e Instalación de Steam:**
   - Busca en el registro de Windows si Steam está instalado.
   - Si no lo encuentra, **descarga automáticamente** el instalador oficial de Steam y lo instala de manera silenciosa (`/S`).
   - Cierra completamente cualquier proceso de Steam que esté corriendo en segundo plano antes de parchear.

2. **Instalación de Steamtools (OpenSteamTool):**
   - Comprueba la existencia de los archivos parcheados (`dwmapi.dll`, `xinput1_4.dll`).
   - Si no están, consulta la API de GitHub para descargar la última *Release* estable de **OpenSteamTool**.
   - Extrae e instala automáticamente las dependencias en la raíz de Steam y crea la carpeta `config\lua`.

3. **Instalación de Millennium (Legacy v2.36.4):**
   - Incorpora de forma embebida (dentro del mismo archivo) el instalador de Millennium para evitar depender de llamadas web externas (`Invoke-RestMethod`), asegurando disponibilidad offline de la lógica.
   - Descarga y extrae Millennium en la carpeta de Steam.

4. **Instalación del Plugin de Luatools:**
   - Descarga siempre la última versión del plugin directamente desde el repositorio `piqseu/ltsteamplugin`.
   - Limpia posibles duplicados de instalaciones anteriores en `<Steam>\plugins` para evitar conflictos.
   - Descomprime el nuevo plugin directamente en su respectivo directorio.

5. **Configuraciones Finales y Limpieza:**
   - Modifica el archivo `<Steam>\ext\config.json` para activar el plugin recién instalado.
   - **IMPORTANTE:** Apaga las actualizaciones automáticas de Millennium (`general.checkForMillenniumUpdates = false`) para evitar que salte a versiones modernas (`3.x+`) que romperían esta configuración heredada.
   - Limpia basura residual (`steam.cfg`, flags del registro `SteamCmdForceX86`, banderas Beta y fuerza la desactivación del modo offline).
   - Inicia Steam automáticamente con el flag `-clearbeta`.

## 🛠️ Cómo Usar

1. Descargá o cloná el archivo `install-plugin-legacy (1).ps1`.
2. Hacé clic derecho sobre el archivo y seleccioná **Ejecutar con PowerShell**.
3. (Recomendado) Si falla por permisos, abrí una consola de PowerShell como Administrador y ejecutalo manualmente.
4. Relajate. El script hará todo el trabajo sucio, bajará lo necesario y al final va a reiniciar Steam con los plugins ya cargados.

## 🌐 Idiomas Soportados
El script detecta automáticamente el idioma de tu sistema operativo y muestra los mensajes de la consola en:
- Inglés (`en`) - *Default*
- Español (`es`)
- Portugués (`pt-BR`)
- Francés (`fr`)

---
*Este instalador es una variante Legacy.*
