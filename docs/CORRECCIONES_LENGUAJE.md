# Correcciones de Lenguaje y voz · 23 de octubre de 2026

Se mantiene el diseño ilustrado del compañero. La propuesta de interfaz presentada en la conversación no reemplaza el juego. Matemática continúa pendiente de los recursos y secciones que aportará el equipo.

## Voz incluida

Se generaron 300 WAV en español con la voz masculina Microsoft Raul (México) instalada en Windows: 270 palabras, 27 letras, una bienvenida alternativa de Conde y dos instrucciones de trazado. Todos los audios del paquete usan esa voz masculina; las letras se generan con su nombre pronunciado (be, hache, eñe, etc.). No son grabaciones de una persona ni una voz neural creada para el proyecto; su calidad es la de la síntesis del sistema.

El catálogo asigna un identificador y una ruta a cada frase. El juego reproduce primero el archivo incluido. El gestor `Narration` centraliza cancelación y finalización de las palabras y letras; evita que cada pantalla sustituya los avisos de voz de otra. Las grabaciones previas de inicio y felicitaciones se conservan.

La bienvenida de Conde utiliza la grabación masculina original del compañero, con sus subtítulos originales y la animación del personaje. La alternativa generada se conserva en el paquete, pero no se utiliza para esta bienvenida.

En Aprende el abecedario, tocar una letra de la tira o la letra grande reproduce su nombre y anima a Conde. Esto no suma palabras escuchadas al progreso. En trazado, el control inferior es un botón azul con icono de borrador y texto «Borrar»: limpia el intento actual y permite volver a dibujar desde el punto uno sin modificar los ejercicios guardados.

El generador permite producir todo el lote automáticamente sin grabar palabra por palabra. Para voces con otra interpretación se pueden sustituir los audios conservando sus identificadores, una vez disponibles y con procedencia documentada. No se requiere instalar la voz Raul en los equipos que solo ejecutan el juego con el paquete incluido.

## Progreso y compatibilidad

- Ver o pasar un ejemplo no concede una escucha.
- Se cuenta la palabra cuando termina el audio; interrumpirlo al navegar no otorga progreso.
- La pantalla dice «escuchadas». No se presenta escuchar una palabra como demostrar comprensión.
- Se conserva la clave antigua `progreso/ejemplos`, que contenía visitas. Las nuevas escuchas se guardan en `progreso/escuchados`, con versión 2. Los contadores antiguos pueden diferir porque ahora miden otra acción; los datos previos no se borraron.
- Cada guardado se escribe primero en un archivo temporal y se conserva una copia `.bak` del anterior. Si no se puede guardar se avisa, y el lector puede recuperar una copia válida.
- Se conservan secciones ajenas de la configuración al actualizar el progreso.
- «Árbol» aparece como «A de Árbol». Se normalizan vocales acentuadas para comprobar la inicial, conservando la escritura original y distinguiendo Ñ de N.

## Reconocimiento del trazado

Se inspecciona el trayecto entre eventos y solo se avanza por muestras cercanas en el orden de la guía. De ese modo se aceptan movimientos rápidos sobre una línea y se rechazan atajos por el interior de letras curvas o con esquinas. Cerrar una O en su punto inicial no aprueba sin recorrerla.

Se conserva la práctica tolerante y la posibilidad de soltar y retomar un trazo. Si el movimiento sale del camino se muestra una indicación. Otro dedo no toma el control del trazo activo. Los puntos y números se dibujan centrados.

Las guías muestreadas se calculan al establecer una letra o cambiar el tamaño del panel; ya no se reconstruyen para cada evento de movimiento y cada dibujo. Esto reduce cálculos repetidos. No se afirma una cifra de mejora de rendimiento sin medir dispositivos reales.

## Navegación y mensajes

- Entrar al trazado usa la letra seleccionada en Lenguaje.
- El mensaje de ayuda y el contador de ejercicios se sitúan fuera de la zona tapada por el abecedario.
- «Siguiente» tiene una posición visible y se habilita al completar las diez repeticiones y terminar la felicitación.
- El paso a la letra siguiente es explícito. Se eliminó el avance automático diferido que podía mover la selección después de otra acción.
- Completar Z no se confunde con completar todas las letras.
- La placa muestra el número real de letras completadas.
- Volver conserva abierta la lección, sin llevar inesperadamente al inicio.
- Salir de una actividad detiene su narración y audio.

## Comprobaciones

Las herramientas del README validan rutas, catálogo de audio, archivos WAV no vacíos, contenido y compilación. Las pruebas de funcionamiento cubren navegación y recuperación de progreso. Las regresiones cubren las 27 letras en dos tamaños, movimientos continuos y espaciados, atajos de A/O/L/V, retomar un trazo, varios dedos, audio completo e interrumpido, conservación de visitas antiguas, copia de guardado y desbloqueo de la siguiente letra.

Se revisan visualmente las pantallas renderizadas en Windows. No se ha ejecutado esta versión en un dispositivo Android físico; la presencia de entrada táctil y recursos compatibles no sustituye esa prueba. Las otras cuatro actividades de Lenguaje, Matemática, sincronización e IA continúan pendientes.

## Cómo continuaremos Matemática

El equipo aportará las imágenes del fondo, botones, personajes y las secciones que debe tener cada pantalla. Se integrarán como recursos separados, conservando el estilo. Las zonas clicables, ejercicios, respuestas, navegación, animaciones, audio y guardado se implementarán en Godot.

Conviene enviar las capas separadas cuando existan y una referencia de su colocación. Una captura única también sirve como guía, pero no contiene por sí sola los estados o las interacciones. Para narración bastará definir los textos del ejercicio y del feedback; el catálogo y la reproducción permiten automatizar su integración.
