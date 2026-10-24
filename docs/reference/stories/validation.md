# Registro de validación de Cuentos

Fecha: 24 de octubre de 2026. Windows, Godot `4.7.2.stable.official.ed1daf0bf`, renderizador Compatibility.

Ejecución final: `tools/validate.ps1`. Registros locales aislados en `.godot/validation/run-025f895f47d8442a83f3efa8c3a55aa4/`.

| Comprobación | Resultado |
| --- | --- |
| Importación y auditoría de recursos/contenido | Correcta |
| Navegación general | 0 fallos |
| Lenguaje y trazado | 143 comprobaciones, 0 fallos |
| Números | 52 comprobaciones, 0 fallos |
| Menús matemáticos | 196 comprobaciones, 0 fallos |
| Cuentos | 502 comprobaciones, 0 fallos |
| Total numerado | 893 comprobaciones, 0 fallos |

La prueba de Lenguaje provoca deliberadamente una recuperación de progreso y emite su aviso esperado. No hubo errores de script ni errores del motor en la ejecución final.

Cuentos verifica los 16 identificadores, ocho cuadros diferentes por atlas, decodificación de 128 narraciones y 64 preguntas, las cuatro entradas, el ajuste de las tarjetas de biblioteca en los cuatro modos, finalización explícita de lectura, pausa y cancelación sin crédito, terminación real del audio, avance automático, orden correcto/incorrecto, pista de escena, reintentos, conservación del mejor resultado, rechazo de identificadores inexistentes y conservación de secciones de guardado antiguas.

Revisión visual con OpenGL real: biblioteca, menú, lectura, narración y resaltado, orden, preguntas, resultado y controles de sonido. Se revisaron las 64 dobles páginas y 64 preguntas sin desbordamiento de navegación a 1280 × 800 y 960 × 600. Las capturas PNG de esta carpeta provienen del juego ejecutado. No se probó una tablet Android física.

La revisión visual encontró y corrigió el recorte de las tarjetas con títulos largos. La comprobación funcional encontró y corrigió la comparación entre índices enteros de escenas y números decimales cargados desde JSON, que impedía aceptar un orden correcto.
