# Aprende sin Límites: análisis y propuesta

Revisión del 23 de octubre de 2026. Basada en el código, los recursos, la ejecución en Godot y tres pantallas renderizadas a 1280 × 800. Las propuestas siguientes todavía no están implementadas.

**Actualización:** se identificó Hack4Edu 2026, reto 02 «Aprender sin conexión», y se revisaron sus bases. Las decisiones vigentes están en [la evaluación específica del reto](HACK4EDU_RETO_02.md) y [el plan de dos desarrolladores](PLAN_EQUIPO_HACK4EDU.md). El equipo comunicó modalidad innovadora; la reutilización de este proyecto previo necesita aclaración con la sede.

El resto conserva el diagnóstico inicial. Sus propuestas de IA docente y alcance eran preliminares: ahora la prioridad es aprendizaje local, sincronización y acompañamiento que funcione sin red. No interpretar los criterios generales de presentación de este análisis como la rúbrica oficial.

**Correcciones posteriores:** se mantiene por decisión del equipo el estilo ilustrado original. Los fallos de trazado, escuchas y navegación identificados aquí se corrigieron; el estado vigente y los 300 audios incluidos se detallan en [Correcciones de Lenguaje](CORRECCIONES_LENGUAJE.md). Este documento conserva el diagnóstico previo y no es una lista actual de errores pendientes.

## 1. Diagnóstico principal

El proyecto tiene identidad visual y una base funcional de alfabetización. La ambientación andina, los personajes, el cóndor guía y el funcionamiento local pueden formar una propuesta reconocible. No hace falta desechar ese trabajo.

Actualmente la experiencia funciona sobre todo como un **explorador ilustrado de contenidos**. El niño selecciona una letra, ve ejemplos y puede practicar su trazado. Falta conectar esas acciones mediante una meta, decisiones, retos y una consecuencia visible. Por eso puede sentirse estático aunque incluya cientos de fotogramas de animación.

La mejora más importante sería convertir esa exploración en una aventura breve con objetivos educativos verificables. Para un proyecto con IA, además, debe quedar claro qué problema resuelve el modelo y cómo se comprueba su utilidad. La estética, el juego, la pedagogía y la tecnología necesitan sostenerse mutuamente.

## 2. Lo que existe y lo que falta

| Componente | Estado observado | Consecuencia |
| --- | --- | --- |
| Inicio | Nueve opciones, saludos, personajes y despedida | Presentación vistosa, pero muchas opciones no llevan a actividades completas |
| Lenguaje | 27 letras y 270 ejemplos en JSON | Buen contenido base para construir retos |
| Lectura de palabras | Síntesis de voz del sistema | Puede funcionar sin conexión si hay voz española instalada; no es reconocimiento de voz |
| Progreso de palabras | Se guarda al mostrar un ejemplo | Mide exposición, no escucha completada ni comprensión |
| Trazado | 27 formas, entrada por ratón/táctil, diez repeticiones por letra | Actividad real, pero repetición y reconocimiento necesitan revisión |
| Cuatro actividades adicionales de Lenguaje | Mensajes de disponibilidad futura | Las ilustraciones prometen más interacción que la disponible |
| Seis áreas restantes | Pantallas provisionales | El alcance aparente es mucho mayor que el producto terminado |
| Configuración | Mensajes informativos | El usuario no puede ajustar realmente sonido o accesibilidad |
| Personajes 3D | Escenas de demostración independientes | No forman parte del recorrido de aprendizaje |
| IA integrada | No se encontró inferencia, entrenamiento ni conexión a un modelo | Debe desarrollarse y evaluarse si la convocatoria exige IA dentro del producto |

La narración del cóndor menciona actividades y micrófono que todavía no funcionan. Conviene actualizar esa narración o presentar esas opciones claramente como futuras.

## 3. Hallazgos que afectan al aprendizaje

### El progreso se concede al mirar

`_render_example()` llama a `_mark_example_completed()`. Entrar en Lenguaje ya registra el primer ejemplo. Pasar ejemplos llena estrellas aunque no se escuche ni se responda nada. La narración habla de escuchar todas las palabras, pero el código registra visitas.

Propuesta: separar tres conceptos: **explorado**, **practicado** y **resuelto sin ayuda**. Mantener las visitas actuales como historial de exploración; no convertirlas automáticamente en dominio al migrar los guardados. Los logros deben depender de un objetivo concreto.

### El trazado puede aprobar sin recorrer el camino

Se reprodujo con el reconocedor real: iniciar en el primer punto y finalizar directamente en el último completa los dos trazos de A. La búsqueda puede saltar hasta una muestra lejana y aprobar por distancia al final. No basta con verificar el porcentaje de la muestra más avanzada.

Propuesta: medir cobertura del camino en orden y limitar los saltos aceptados, interpolando los movimientos entre eventos para no perjudicar dispositivos lentos. Evaluar tolerancia, continuidad, dirección y cobertura con ejemplos válidos e inválidos. Probar curvas cerradas como O y letras con intersecciones, además de A. Esta corrección debe preceder a usar los resultados del trazado para entrenar IA.

### Diez repeticiones iguales no son diez retos distintos

La misma geometría se repite diez veces y cambia el contador. Puede servir de práctica, pero no demuestra una progresión de habilidades. El indicador 1/27 de trazado expresa la posición de la letra, no cuántas letras domina el niño.

Propuesta: mostrar «Letra 1 de 27» y diseñar una progresión guiada: demostración, trazo ancho, guía parcial y práctica con menos ayuda. El número de repeticiones debe responder a la necesidad observada, con revisión de un docente.

### Contenido y representación requieren revisión educativa

Hay vocabulario muy desigual: palabras familiares junto con «Xifoides», «Xerografía» o «Xenón». Algunos emojis solo aproximan el concepto: mesa y silla comparten representación; quena usa otra flauta. La cobertura de emojis depende del equipo.

Además, «Árbol» aparece como «A en Árbol» porque la comprobación no normaliza la tilde. Conviene distinguir letra y acento al construir la frase sin quitar las tildes de las palabras. Ñ debe seguir siendo una letra diferente de N.

Propuesta: revisar dificultad, vocabulario regional, relación palabra-imagen y sonido de cada ejemplo. Priorizar una pequeña selección muy bien ilustrada; reemplazar emojis por dibujos consistentes y verificables. No es necesario forzar diez palabras poco apropiadas por cada letra para la primera experiencia.

## 4. Público y alcance

Inicial y toda primaria abarcan habilidades muy diferentes. Propongo estos recorridos de diseño, sujetos a validación docente:

| Recorrido | Habilidad principal | Interacción sugerida |
| --- | --- | --- |
| Inicial, aproximadamente 4–6 años | Escuchar, reconocer sonidos y relacionar imágenes | Dos opciones grandes, guía oral, acciones cortas |
| Primeros cursos, aproximadamente 6–8 | Letras, sílabas y primeras palabras | Tres opciones, ordenar, completar y leer |
| Primaria posterior | Comprensión y resolución de problemas | Historias, decisiones y retos más complejos |

Para la siguiente versión demostrable, concentrarse en alfabetización de **5–7 años**, con posibilidad de ajustar por habilidad. Es una decisión de alcance propuesta, no una prescripción curricular. El currículo y la variante de español deben corresponder al lugar donde se pruebe el juego; celebrar una presentación en Salamanca no define por sí solo al alumnado destinatario.

## 5. Propuesta: Aventuras del Saber

Conservar Aprende sin Límites como marca. El niño ayuda a Conde a recuperar las páginas de un libro de su comunidad. Cada pequeña misión restaura una parte del paisaje o añade algo a un cuaderno de descubrimientos.

Recorrido propuesto:

**Entrar → continuar aventura → recibir una misión → resolver tres retos → ver lo conseguido → elegir continuar o descansar.**

Ejemplo de misión: «Ayuda a Conde a preparar su mochila».

1. Escucha «Abeja» y elige entre dos o tres imágenes. Objetivo: relacionar palabra y representación.
2. Encuentra la A entre pocas letras. Objetivo: discriminar la grafía.
3. Traza la A con guía. Objetivo: practicar el recorrido motor.
4. Coloca una pegatina en el cuaderno y ve cómo Conde recoge la página. La celebración nombra el logro: «Reconociste la A y seguiste su camino».

Estos tres retos evalúan cosas distintas: acertar una imagen no demuestra reconocer un fonema aislado. Las instrucciones y las métricas deben describir la habilidad realmente practicada. Para conciencia fonológica, diseñar ejercicios específicos de sonido inicial con un educador.

El bucle debe permitir equivocarse con una pista útil, volver a intentar y cerrar una misión. Evitar castigar el error con pérdida de vidas. La duración propuesta para probar es de tres a cinco minutos por misión, ajustable tras observar a los niños; no es una duración científicamente establecida para este producto.

La investigación RITEC de UNICEF relaciona el diseño del juego con autonomía, sensación de logro y bienestar. La aplicación a este proyecto sería ofrecer elecciones comprensibles y progreso con significado, y comprobarlas con niños. [UNICEF: diseño de juego y bienestar](https://www.unicef.org/innocenti/projects/responsible-innovation-technology-children).

## 6. Diseño visual y movimiento

### Pantalla de inicio

Un botón dominante «Continuar aventura», una entrada secundaria «Explorar» y un acceso discreto para adultos. Las siete materias pueden quedar en un mapa, mostrando las futuras como zonas aún por abrir. Para la demostración solo se necesita una ruta completa y convincente.

### Pantalla de actividad

Una consigna, una zona central de acción y un indicador corto de misión. El abecedario de 27 letras puede quedar disponible en exploración; no necesita ocupar la pantalla durante cada reto. En el trazado actual, el selector inferior cubre la zona donde se colocaron mensajes de resultado: hay que devolverles espacio propio.

### Componentes editables

Usar ilustraciones como arte y controles reales para textos, botones y progreso. Varios elementos actuales están pintados dentro de PNG grandes, con áreas transparentes clicables encima. Esto dificulta cambiar instrucciones, mostrar estados, adaptar tamaños o añadir foco visible. La tira del alfabeto tiene 496 × 76 píxeles y se amplía mucho, con pérdida de nitidez.

Crear componentes reutilizables de botón, tarjeta de respuesta, consigna, progreso y diálogo. Unificar tipografía, sombras, colores y tamaños. Mantener la identidad andina con fondos menos detallados detrás de la tarea principal.

### Movimiento con función

- Entrada breve de una tarjeta al cambiar de reto.
- Respuesta visible al tocar o enfocar un botón.
- Una demostración del gesto antes de trazar.
- Conde mira o señala el objeto relevante.
- Una celebración breve al completar una misión y un cambio persistente en el mapa.

Como punto inicial de diseño, probar transiciones de 150–250 ms y celebraciones de alrededor de un segundo. Ofrecer volumen, subtítulos y reducción de movimiento reales. Evitar animaciones constantes encima de la tarea. Son parámetros propuestos que requieren pruebas de uso.

## 7. IA: una función demostrable

Primero hay que confirmar si las bases piden **desarrollar con herramientas de IA** o **integrar IA en el producto**. Son aportes diferentes y deben explicarse por separado.

### Ruta recomendada para una primera integración: asistente del docente

Un área para adultos permite solicitar variantes de una misión según habilidad, vocabulario y contexto. Un modelo genera una propuesta estructurada: objetivo, consigna, opciones, solución y pistas. Un validador comprueba el formato y la coherencia básica; un docente revisa y aprueba el contenido antes de que llegue al niño.

El juego descarga o importa solo los paquetes aprobados y los conserva localmente. Así se mantiene la experiencia infantil sin conexión. La generación requiere conexión si se utiliza un servicio externo; la generación local dependería del equipo y debe medirse antes de prometerla. Si el servicio falla, el juego sigue con su banco aprobado.

La demo podría mostrar una misión generada, una propuesta rechazada por el validador o docente y otra aprobada que aparece después en el juego. Eso hace visible el papel de la IA, sus límites y el control de calidad.

Medir: tiempo de preparación con y sin asistente, proporción de propuestas aceptadas sin corrección, errores de contenido y adecuación según una rúbrica docente. Guardar versión de modelo, instrucciones y contenido aprobado. No incrustar credenciales de un servicio en el juego distribuido.

UNESCO propone validar el uso educativo de IA con un enfoque centrado en las personas y en la adecuación pedagógica. En esta propuesta el docente mantiene la aprobación del material y el niño recibe actividades revisadas. [UNESCO: IA generativa en educación](https://www.unesco.org/en/articles/guidance-generative-ai-education-and-research).

### Segunda línea de investigación: tutor adaptativo

Registrar por habilidad intentos, aciertos, ayudas y resultados recientes. Una primera versión puede decidir con reglas transparentes: si necesita ayuda repetida, reducir opciones y mostrar una demostración; si resuelve sin ayuda en varias ocasiones, introducir una variante. **Esto es adaptación por reglas y no debe presentarse como un modelo aprendido.**

Con datos de calidad y tamaño suficiente, estudiar un modelo pequeño que estime la probabilidad de éxito en un próximo reto y comparar sus recomendaciones con las reglas. Mantener una salida comprensible para el docente: «Se sugirió esta práctica por dificultades recientes en estas tareas».

Separar entrenamiento y evaluación por niño para evitar que intentos de una misma persona contaminen ambos grupos. No entrenar con el progreso de visitas actual ni con trazados falsamente aprobados. Un conjunto sintético puede servir para demostrar el flujo técnico, pero no prueba utilidad educativa. Un piloto pequeño de usabilidad tampoco basta para afirmar que el modelo generaliza.

Si el modelo no mejora la alternativa sencilla, reportarlo con honestidad. No convertir el juego en un diagnóstico de dificultades o capacidades. La guía de UNICEF para IA infantil destaca transparencia, inclusión y protección de datos; esas propiedades deben poder demostrarse en el diseño. [UNICEF: IA e infancia](https://www.unicef.org/innocenti/reports/policy-guidance-ai-children).

### Voz y conversación

Dejar reconocimiento de pronunciación y conversación abierta para otra etapa. Requerirían una evaluación específica con voces infantiles, acentos, ruido y equipos disponibles. La voz del sistema actual solo lee texto; no escucha ni evalúa al niño. Un cóndor con diálogo guionado puede acompañar muy bien sin un chatbot abierto.

## 8. Prioridades de implementación

| Orden | Entrega | Condición para darla por terminada |
| --- | --- | --- |
| P0 | Corregir reconocimiento y significado del progreso | Saltos inicio-final no aprueban; trazos válidos sí; visitas y dominio se distinguen |
| P0 | Ajustar promesas y mensajes visibles | Narración y opciones describen lo que realmente funciona; resultados no quedan cubiertos |
| P1 | Una misión de Lenguaje completa | Tres retos, pista, reintento, logro y reanudación tras cerrar |
| P1 | Interfaz de aventura | Una acción principal, controles editables, foco visible y ajustes reales |
| P1 | IA para preparación docente | Generación real, validación, aprobación e importación de una misión; juego local de respaldo |
| P1 | Piloto de uso y revisión docente | Problemas observados registrados y corregidos; datos reales separados de expectativas |
| P2 | Modelo adaptativo evaluado | Comparación con reglas, datos adecuados y explicación de recomendaciones |
| P2 | Segundo mundo educativo | Misma calidad y componentes; por ejemplo, conteo con objetos |
| P3 | Más materias, voz evaluada y experiencias 3D | Añadirlas después de cerrar y probar el recorrido principal |

No propongo un plazo cerrado sin conocer la fecha de presentación y disponibilidad del equipo. El orden permite recortar alcance conservando una demostración coherente.

## 9. Arquitectura para crecer

La limpieza deja carpetas claras y datos de letras y trazos separados. Aún queda interfaz construida dentro de controladores de más de 400 líneas: ordenar carpetas no elimina esa deuda.

Siguiente separación recomendable:

- **Pantallas y componentes:** muestran consignas y respuestas; emiten acciones.
- **Lógica de misión:** objetivo, intentos, pistas, resolución y transición.
- **Contenido:** identificadores estables, idioma, habilidad, dificultad, solución y referencias a arte/audio.
- **Progreso local:** conserva resultados por perfil y versión de contenido; permite migración y recuperación.
- **Recomendador:** reglas primero; modelo evaluado después, con una interfaz intercambiable.
- **Herramienta del docente:** generación y revisión separadas del juego infantil.

No añadir un servicio global por cada función. Extraer componentes según los necesite la primera misión. Usar señales para comunicar actividad y navegación, evitando depender del nombre o posición de nodos para comprobar respuestas.

Las cuatro secuencias principales suman 404 PNG y unos 57 MiB de archivos fuente. Se cargan cientos de texturas durante la construcción de pantallas. El consumo de RAM puede ser mayor y todavía no está medido. Antes de cambiar formatos, medir arranque, memoria y fluidez en el ordenador de destino. Después estudiar carga diferida, tamaños adecuados y animación por partes; no prometer una mejora de rendimiento solo por mover archivos.

## 10. Cómo defenderlo en una presentación

Propuesta de valor a validar: **una aventura de alfabetización con identidad cultural, uso infantil sin conexión y actividades que el docente puede preparar con ayuda de IA y revisar antes de publicarlas**.

Una demostración propuesta de cuatro minutos:

1. Explicar el problema y mostrar a quién se dirige: una habilidad de alfabetización concreta.
2. Resolver una misión breve, incluyendo un error y la pista que ayuda a corregirlo.
3. Mostrar el logro y el progreso que se recupera al reabrir.
4. Mostrar cómo la IA propone una variante y cómo el docente la valida.
5. Desconectar el servicio de generación y demostrar que el banco aprobado sigue funcionando.
6. Cerrar con datos observados, límites y el siguiente experimento.

Si se muestran resultados pregrabados, identificarlos como tales. Distinguir prototipo, función terminada y plan futuro. Preparar también un registro del uso de IA durante el desarrollo: qué ayudó a producir, cómo se revisó y qué errores se detectaron. Eso responde al enfoque de desarrollo con IA si finalmente fuera el exigido.

Reunir autoría y procedencia de imágenes, voces y modelo 3D, y documentar qué se creó, generó o adaptó. Las herramientas y proveedores de IA aún deben seleccionarse según las bases, coste, conexión y equipos disponibles.

## 11. Validación educativa y de uso

Como primera investigación de usabilidad, proponer sesiones supervisadas con 6–10 participantes del grupo elegido, mediante el centro y sus procedimientos para pruebas con menores. Ese tamaño sirve para encontrar dificultades, no para demostrar eficacia ni entrenar un modelo generalizable.

Observar si comprenden la primera consigna, encuentran cómo empezar, entienden la pista y pueden volver a la actividad sin ayuda adulta. Registrar eventos mínimos con alias local; no hacen falta nombres, grabaciones o servicios externos para esos indicadores iniciales.

Para estudiar aprendizaje, diseñar con un educador una tarea breve previa y otra posterior equivalente, incluir ejemplos nuevos y observar retención en una sesión posterior. Una mejora inmediata sin comparación no demuestra que el juego sea su causa. Comparar métodos y reportar tamaño de muestra, ayudas recibidas y limitaciones.

Separar medidas:

| Dimensión | Ejemplo de evidencia |
| --- | --- |
| Uso | Consignas entendidas, finalización y ayuda adulta necesaria |
| Aprendizaje | Desempeño en tareas equivalentes y transferencia a ejemplos nuevos |
| Software | Errores, persistencia, arranque y fluidez en el equipo previsto |
| IA docente | Tiempo de preparación, correcciones y calidad del contenido aprobado |
| Modelo adaptativo futuro | Calidad de predicción y utilidad frente a reglas sencillas |

La EEF destaca la práctica y la evaluación como usos educativos relevantes de la tecnología. En este proyecto la animación debe acompañar oportunidades de práctica y resultados interpretables; la eficacia concreta tendrá que medirse. [EEF: tecnología para mejorar el aprendizaje](https://educationendowmentfoundation.org.uk/education-evidence/guidance-reports/digital).

La versión competitiva debe poder demostrar una misión terminada, una función de IA útil y un proceso de evaluación serio. Eso ofrece una defensa más sólida que ampliar el número de pantallas sin cerrar el aprendizaje que ocurre en cada una.
