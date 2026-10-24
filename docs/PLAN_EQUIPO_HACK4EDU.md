# Plan de trabajo del equipo · Hack4Edu, reto 2

Versión del 23 de octubre de 2026. Plan propuesto para dos desarrolladores activos y un tercer integrante de apoyo. No presupone que el coordinador haya aceptado trabajo previo en modalidad innovadora: resolver primero lo indicado en `HACK4EDU_RETO_02.md`.

Actualización de alcance: el equipo decidió conservar los fondos, botones y personajes ilustrados del proyecto original y aportar las imágenes para Matemática. No se adopta la maqueta Aventura/Aula como sustitución visual. Los componentes y contratos de este plan pueden implementarse bajo esa estética. Consultar `CORRECCIONES_LENGUAJE.md` para las correcciones y el audio ya incluidos.

## Producto que construiremos

Una experiencia de alfabetización con un solo mundo de Lenguaje, tres tipos de actividad, guía con voz incluida y perfiles locales. Funciona en Windows y Android, conserva resultados al cerrar y los sincroniza cuando vuelve la conectividad. Una función pequeña de adaptación local debe poder explicarse y compararse con una alternativa sencilla.

Objetivo inicial: una misión con vocales. El abecedario anterior se conserva como material de referencia o exploración según permita la modalidad. No desarrollar ahora Matemática, Enciclopedia, Diccionario, conversación por micrófono ni un nuevo entorno 3D.

## Reparto por áreas

Los nombres siguientes identifican responsabilidades; el equipo puede intercambiarlas según sus fortalezas. No son una asignación ya aceptada por cada compañero.

| Responsable propuesto | Entregas | Archivos que debería liderar |
| --- | --- | --- |
| Tú · aplicación y datos | Inicio, navegación, tema visual, perfiles, guardado, cliente de sincronización y paquetes Windows/Android | `scenes/app/`, `scenes/ui/`, `scripts/app/`, `scripts/services/`, `resources/themes/` |
| Compañero de Lenguaje · experiencia educativa | Retos, instrucciones, corrección del trazado, modelo de habilidades local, guía y audio de la misión | `scenes/activities/`, `scripts/language/`, `scripts/learning/`, `data/language/`, recursos de la misión |
| Tercer integrante · verificación y presentación | Guion, revisión de contenido con docente, inventario de recursos, pruebas en dispositivos, incidencias, capturas y presentación | `docs/`, `tests/manual/`, contenido de presentación |

El receptor de sincronización es una tarea compartida y acotada: servicio mínimo con recepción, deduplicación y consulta docente. Reservar una sesión de integración para él; no añadir usuarios administrativos complejos, mensajería o estadísticas generales al primer alcance.

Con dos desarrolladores el alcance sigue siendo exigente para tres días. Se debe construir primero una actividad completa que atraviese todas las capas; la segunda y tercera reutilizan componentes. Si el circuito de datos o Android no están listos, se reduce el número de actividades antes que fingir funcionamiento o sumar materias.

## Acuerdos antes de modificar pantallas

1. Seleccionar la dirección visual. Recomendada: Aventura, con una misión principal, un cuaderno y un acceso para docentes.
2. Definir un boceto de inicio y actividad, más estados: esperando, respondiendo, ayuda, acierto y guardado.
3. Cerrar una lista corta de palabras, consignas y archivos de audio. Revisarla con una persona que conozca alfabetización.
4. Acordar el resultado que emite cada actividad y quién guarda. La actividad no escribe por su cuenta en varios archivos ni realiza peticiones de red.
5. Configurar y abrir una exportación Android vacía en el dispositivo previsto.
6. Resolver modalidad, material previo, atribuciones y elección conjunta de licencia. No asignar unilateralmente una licencia a la obra de los tres autores.

La maqueta es material previo de diseño y su sincronización está simulada. No copiarla o presentarla como desarrollo del periodo oficial sin aclarar antes las condiciones de la modalidad con la sede.

## Contratos para trabajar en paralelo sin pisarnos

### La actividad entrega un resultado

Una señal común, por ejemplo `activity_finished(result)`, aporta:

- `activity_id`, `content_version` y `skill_id`.
- Resolución, número de intentos y ayuda utilizada.
- Duración de la sesión medida localmente, sin usarla como diagnóstico.

La actividad también emite solicitud de volver y de repetir una consigna. La aplicación decide la navegación; el gestor de audio decide qué reproducción tiene prioridad. Así se evita que cada ejercicio invente sus propios menús, guardados y controles.

### El servicio de progreso garantiza el guardado

La aplicación añade identidad de perfil, sesión, dispositivo y evento. Guarda localmente y devuelve confirmación. Solo después la interfaz anuncia que se conservó el resultado. Los resultados pendientes permanecen disponibles aunque la red falle.

### El recomendador entrega una sugerencia explicable

Recibe evidencias de una habilidad bien definida y propone la siguiente actividad con una razón. No contiene la interfaz ni llama a servicios de red. Las reglas de navegación y el modelo probabilístico deben poder probarse por separado. Parámetros supuestos y datos sintéticos se etiquetan como tales.

### El cliente de sincronización transmite eventos confirmados

Usa identificadores estables, reintenta con espera y marca como enviados solo los eventos reconocidos por el receptor. Los resultados no se eliminan al pulsar un botón ni por detectar Wi-Fi. El servidor no duplica un evento si la respuesta anterior se perdió.

## Orden de implementación

| Hito | Qué se integra | Evidencia de cierre |
| --- | --- | --- |
| Base común | Tema, botones, navegación y paquete de cada plataforma | Se abre la misma pantalla en Windows y Android |
| Primer recorrido | Un reto con voz, respuesta, ayuda y salida | Se puede completar con ratón y con dedo |
| Persistencia | Perfil y resultado con identidad estable | Cerrar y abrir conserva el progreso correcto |
| Reconexión | Cola local, receptor y vista docente mínima | Enviar dos veces no duplica; perder red no borra |
| Acompañamiento local | Estimación y elección de práctica | Dos historiales de prueba producen decisiones justificadas sin red |
| Acabado | Segundo y tercer tipo de reto, guía y transiciones | Misión completa con componentes consistentes |
| Presentación | Paquetes finales, guion y evidencias | Ensayo en el tiempo disponible y copia de respaldo |

No dejar la exportación, el audio o el servidor para después de terminar todas las ilustraciones. Si una pieza crítica falla, resolverla antes de ampliar contenido.

## Organización de los días de desarrollo

Este reparto es una propuesta para un periodo autorizado de tres días; las condiciones de participación las determina la organización.

**Día 1:** ambos cierran la interfaz de resultado. Una persona levanta la aplicación y prueba Android; la otra desarrolla el primer reto con audio. Integrar al final del día un recorrido que guarde algo real, aunque solo use una vocal. El tercer integrante prueba instrucciones y reúne atribuciones.

**Día 2:** completar cola y receptor de sincronización mientras Lenguaje añade variantes, corrige el trazado y prueba adaptación local. Integrar a mitad del día. Probar desconexión, reinicio y duplicación de envío. El tercero registra problemas reproducibles y prepara la historia de la demo.

**Día 3:** cerrar la misión, ajustar contraste, tacto, volumen y navegación. Exportar en ambos sistemas y ensayar. Evitar nuevas materias, modelos grandes o cambios de arquitectura durante las últimas horas. Congelar una versión demostrable y conservar un vídeo de respaldo identificado como grabación.

No asumir que todo el plan cabe en las horas disponibles: el primer objetivo es el recorrido completo de una actividad. Añadir contenido solo cuando el circuito básico esté verificado.

## Reglas prácticas del repositorio

- Una rama por entrega pequeña. Revisar e integrar cambios terminados al menos una vez al día.
- Compartir primero la limpieza completa y sus rutas nuevas; no mezclar carpetas de copias anteriores.
- Evitar que dos personas editen la misma escena. Usar escenas hijas para actividades y componentes.
- El tema y el contrato de resultados tienen un responsable, con cambios avisados al otro desarrollador.
- Cada tarea incluye qué cambia y cómo se comprueba. “Hacer más bonito” se sustituye por una entrega observable: estado de botón, pantalla adaptable o consigna audible.
- Registrar qué existía antes y qué se hizo en el evento. Conservar commits y referencias de origen, sin alterar fechas o historia para aparentar elegibilidad.
- No subir claves, credenciales de exportación ni datos identificables de niños. Los datos de demostración se reconocen como ficticios.

## Lista de pruebas del tercer integrante

| Prueba | Resultado esperado |
| --- | --- |
| Instalar sin red | La primera actividad y su audio están disponibles |
| Abrir sin voz española del sistema | Las instrucciones esenciales siguen oyéndose |
| Tocar respuestas erróneas | Hay pista útil y posibilidad de reintentar |
| Saltar del inicio al final de una letra | No se registra un trazo completo |
| Dibujar siguiendo el camino | Se acepta con tolerancia apropiada |
| Cambiar de perfil | Los logros no se mezclan |
| Cerrar y reabrir | Se conserva el resultado confirmado |
| Red caída, servidor caído o respuesta perdida | El juego sigue y conserva pendientes |
| Reenviar el mismo evento | El docente ve un solo registro |
| Pantalla Android pequeña | No hay controles cortados o superpuestos |
| Silenciar y repetir | Los botones hacen lo que indican |
| Reducir movimiento | La información se conserva sin efectos innecesarios |

Las pruebas con niños se coordinan mediante el centro y sus procedimientos. Un ensayo interno entre adultos no se presenta como evidencia de comprensión infantil. El modelo local tampoco se valida solo con casos inventados.

## Guion para explicar la propuesta a los colegas

“Vamos a concentrarnos en una aventura de Lenguaje para Windows y Android. Construiremos la interfaz con componentes reales y una guía con audio incluido. Lo esencial será aprender y guardar sin internet, y sincronizar sin perder resultados cuando vuelva la red. Primero integraremos una actividad completa; después reutilizaremos la base para ampliar la misión. Dos personas desarrollan y la tercera prueba, revisa contenido y prepara la presentación. Antes de reutilizar el proyecto actual, aclararemos la modalidad con el coordinador.”

Esta es una propuesta de acuerdo, no un mensaje enviado al equipo.
