# Hack4Edu 2026 · Reto 02: Aprender sin conexión

Revisión del 23 de octubre de 2026. Equipo: tres integrantes, aproximadamente dos desarrolladores activos. Plataformas previstas: Windows y Android. Modalidad comunicada por el equipo: innovadora.

## Conclusión

**El proyecto encaja en el problema del reto, pero su versión actual no lo resuelve por completo y su modalidad necesita aclaración.** Tiene contenido, guardado y 300 audios locales incluidos. Carece de sincronización, perfiles para equipos compartidos, exportaciones verificadas y una función de IA integrada. Las [correcciones de Lenguaje](CORRECCIONES_LENGUAJE.md) actualizan el diagnóstico técnico de esta revisión. Por decisión del equipo se mantiene la estética ilustrada original; las alternativas visuales de este documento no son un rediseño acordado.

Esta revisión compara evidencia del repositorio con documentación pública. No acredita inscripción, selección ni aceptación por parte de la organización.

## Bases verificadas y punto pendiente

Se consultó el PDF **hack4edu_2026_Bases_de_participacion.pdf**, nueve páginas, enlazado desde la presentación de la web oficial; se descartaron como referencia vigente los PDF de ediciones anteriores.

- Innovadora: desarrollo exclusivo del 3–5 de noviembre; trabajo previo admitido en sénior y declarado.
- Inscripción individual: hasta el 30 de octubre; adhesión de sedes: 27 de octubre. Final internacional: 7 de noviembre.
- Entrega: preparar presentación de cinco minutos, vídeo de tres y repositorio. Las bases 3 y 5 difieren entre «o» e «y»: confirmar con la sede y preparar ambos.
- Se requiere licencia libre para el código y acreditar derechos del material.
- Sénior: innovación 20%, acabado 30%, transferencia 30%, educación con IA 20%.
- Premio ProFuturo: impacto, inclusión, sostenibilidad y uso responsable de IA, 25% cada uno.

[Bases 2026, páginas 2–6](https://drive.google.com/file/d/1L151uGDggEYGm7MJs4u6ZzBib7a7gXii/view). Las horas de los plazos se indican como locales; la sede debe confirmar su aplicación al equipo.

**Aplicación a este caso:** el repositorio y esta preparación ya existen antes del evento. Para continuar sobre ellos, la opción coherente es consultar el cambio a sénior. Si el equipo permanece en innovadora, debe acordar con el coordinador qué preparación, recursos y herramientas puede aprovechar y qué deberá producir durante el periodo admitido. Cambiar el nombre, abrir una rama vacía o rehacer la apariencia no demuestra desarrollo exclusivo durante el hackathon. No se debe presentar trabajo previo como creado durante esos días.

Pendiente externo: situación de inscripción de los tres participantes, sede adherida, modalidad aceptada y decisión del coordinador sobre trabajo previo. No se han enviado comunicaciones ni aceptado bases en nombre del equipo.

## Qué exige el reto 2 y cómo estamos

El reto propone educación que funcione con conectividad limitada y sincronice información al recuperarla. Incluye como posibilidades contenidos, actividades, progreso, comunicación docente e IA local. No impone en su descripción un chatbot, 3D, Google Play o un modelo generativo grande. [Catálogo oficial, Reto 02](https://profuturo.education/hack4edu/).

| Aspecto | Evidencia del proyecto | Estado |
| --- | --- | --- |
| Contenido local | Ilustraciones, grabaciones y abecedario dentro del proyecto | Base disponible |
| Actividades utilizables sin internet | Explorador y trazado | Parcial: faltan pruebas de primera ejecución en equipos limpios |
| Audio autónomo | Grabaciones anteriores y paquete de 300 voces locales | Implementado para las palabras, letras e instrucciones actuales; falta prueba Android |
| Progreso | Escuchas completas y trazados, guardados con copia | Corregido el crédito por visitas; no constituye una evaluación de dominio |
| Sincronización al reconectar | No se encontró cliente de red ni protocolo | Pendiente |
| Dispositivos compartidos | Un guardado por usuario del sistema | Pendiente: mezcla potencial del progreso de diferentes niños |
| Windows | Ejecutado en este equipo | Falta paquete distribuible y prueba en otra máquina |
| Android | Sin perfil de exportación ni prueba en dispositivo aportada | Pendiente |
| IA local | No se encontró un modelo ni motor de inferencia | Pendiente |
| Licencias y procedencia | No hay LICENSE ni inventario completo de atribuciones | Pendiente de autores y equipo |
| Evidencia educativa | No se aportaron sesiones o resultados de un piloto | Pendiente; no sustituible por capturas |

Los estados son una auditoría técnica propia, no puntuaciones del jurado. La descripción del reto permite IA local; la conveniencia de la función propuesta y su evaluación deben justificarse.

## Propuesta de producto

**Aprende sin Límites: una aventura de alfabetización que conserva actividades, audio y progreso en el dispositivo, acompaña la práctica con un modelo local y comparte resultados docentes al recuperar conexión.**

Una primera experiencia para alfabetización inicial, aproximadamente 5–7 años, ajustada por habilidad con revisión docente. Se mantiene la identidad andina. Windows permite la demostración de escritorio y Android el uso táctil; ninguno debe depender de una cuenta infantil en línea para empezar.

Primera entrega: un mundo de Lenguaje con las cinco vocales, tres tipos de reto y una misión breve. El abecedario existente puede mantenerse como biblioteca, pero no contará como 27 misiones terminadas. Las otras materias quedan fuera de la primera demo.

El niño entra con un avatar local, continúa una misión, escucha una consigna corta, actúa, recibe ayuda y ve un logro concreto. El adulto puede revisar resultados y estado de envío. El juego nunca debe esperar una respuesta de internet para corregir un ejercicio conocido.

## Cómo conseguir un acabado de aplicación

### Interfaz

El problema actual es que varias pantallas completas, textos y estados se pintaron dentro de PNG. Las imágenes son adecuadas para ilustrar; los botones, instrucciones y lógica requieren componentes editables.

Construir en Godot escenas pequeñas con `Control`, contenedores, `Button`, `Label`, recursos `Theme` y estilos compartidos. Su sistema de contenedores admite composiciones adaptables y los temas permiten centralizar apariencia. [Contenedores](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html), [temas de Godot](https://docs.godotengine.org/en/stable/tutorials/ui/gui_skinning.html).

Dirección visual propuesta:

- Fondo sencillo y poco contrastado; superficie opaca bajo la actividad.
- Texto oscuro y legible, verde como acción principal y un acento cálido para logros.
- Un objetivo visible por pantalla; instrucciones orales y breves textos.
- Botones grandes, separados, con estados de pulsación, foco y desactivación.
- Un sistema de tamaños, márgenes, radios y tipografías para todas las actividades.
- Decoración andina concentrada en los bordes y en el mapa, dejando libre el centro.

Usar contraste de texto de 4,5:1 como objetivo de diseño, y 3:1 en texto grande según los criterios aplicables. Hay que medir las combinaciones reales; una paleta atractiva no acredita accesibilidad. [W3C: contraste](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

Se prepararon dos direcciones explorables: **Aventura**, con misión principal y recorrido, y **Aula**, con navegación por áreas. La recomendación para niños es Aventura. El ejemplo solo muestra navegación, respuesta, cuaderno y estados simulados; no incorpora sincronización real, voces finales ni IA. No sustituye la implementación en Godot.

### Personajes y movimiento

Priorizar un solo guía bien resuelto. Conde necesita estados coherentes: espera, explica, señala, anima y celebra. Usar ilustración por capas o animación 2D para ojos, alas y cabeza. Relacionar el gesto con la acción del niño y reservar el movimiento de boca para frases reproducidas. Evitar que flote o hable continuamente.

Conservar al resto de personajes para una etapa posterior. Más personajes o un modelo 3D no solucionan una instrucción confusa. La primera versión puede tener calidad profesional con animación 2D, si las transiciones, el tacto y las respuestas están cuidados.

### Audio

Una voz guía consistente, frases cortas y grabaciones incluidas en el paquete. Igualar niveles, limpiar silencios y evitar saturación. Un gestor de audio detiene la frase anterior, prioriza instrucciones, regula música y permite repetir o silenciar.

Para el primer mundo, grabar solo las consignas, vocales, ejemplos y mensajes que realmente aparecen. Mantener transcripción visible. El TTS puede ser un complemento, pero ninguna instrucción esencial dependerá de descargar una voz. Sincronizar los gestos con marcadores de la grabación y comprobarlos en el dispositivo.

## IA local: propuesta acotada

Para este reto cambia la prioridad del informe anterior: un generador docente conectado deja de ser el núcleo. Propongo estudiar **seguimiento bayesiano del conocimiento**, un modelo probabilístico de habilidades usado en tutores educativos. La investigación original modela la estimación del conocimiento a partir de las respuestas; no demuestra por sí misma eficacia para vocales o para este público. [Corbett y Anderson: modelado del alumno](https://escholarship.org/uc/item/5bs755pr).

Aplicación propuesta, aún por desarrollar:

1. Definir habilidades muy concretas: por ejemplo, reconocer la grafía A entre tres alternativas.
2. Actualizar una estimación por habilidad al responder a ejercicios diferentes.
3. Elegir una demostración, otra práctica o una variante según esa estimación.
4. Guardar modelo y resultados localmente; el dispositivo sigue tomando decisiones sin conexión.
5. Mostrar al docente qué observaciones motivaron la siguiente práctica.

El modelo es pequeño y puede expresarse con cálculos locales, sin un servidor de generación ni una descarga de gran tamaño. La política que elige actividades puede usar umbrales; debe distinguirse del modelo probabilístico que estima el conocimiento. Los parámetros iniciales serían supuestos documentados, no entrenamiento validado con niños.

Comparar esta alternativa con una secuencia fija y con reglas simples. Si no aporta mejora, no afirmar que personaliza mejor. Contar respuestas de primera oportunidad, separar la ayuda y evitar inflar la estimación por repetir el mismo ejercicio. No utilizar las visitas actuales ni el trazado defectuoso como si fueran evidencia fiable de aprendizaje.

Antes de prometer esta línea como componente válido para la puntuación de IA, confirmar con la organización si su encaje satisface la convocatoria. No presentarlo como IA generativa, modelo entrenado por el equipo ni diagnóstico. El niño ve una práctica adecuada; los detalles del modelo corresponden al espacio del docente y a la documentación.

## Diseño del funcionamiento sin conexión

### Lo que debe venir instalado

Un paquete inicial con actividades, ilustraciones, tipografía y audio esenciales. Primera ejecución sin registro ni descarga obligatoria. Se crean perfiles locales mediante alias y avatar; no hace falta pedir nombres completos. No enviar grabaciones o trazos crudos para demostrar el circuito de sincronización.

### Guardado local

Cada resultado válido se guarda antes de mostrar «guardado». Separar exploración, práctica y resolución. Incluir versión de contenido y eventos con identidad estable. Para un volumen pequeño se puede empezar con archivos estructurados y escritura segura, manteniendo copia recuperable. Evaluar una base de datos solo cuando el volumen y las consultas la justifiquen; no añadir una dependencia nativa sin probarla en Android.

### Sincronización

Una cola conserva los eventos pendientes. El servidor reconoce identificadores únicos y devuelve confirmaciones. Solo entonces el cliente marca los eventos como enviados. Si se pierde la respuesta, el mismo evento se reintenta sin duplicarlo. Una red Wi-Fi conectada no garantiza que el servidor esté disponible.

Campos mínimos propuestos: identificador de evento, perfil local, dispositivo, sesión, actividad, habilidad, versión de contenido, resultado, ayuda y secuencia local. No depender únicamente del reloj del dispositivo para ordenar o resolver conflictos.

Para la primera demo, cada perfil trabaja en un dispositivo y el docente consulta su resumen. La fusión simultánea de un mismo perfil en varias tablets es una ampliación: exige unir eventos sin sobrescribir historiales. La aplicación local no debe bloquearse por tokens caducados, tiempos de espera o ausencia del servidor; el acceso docente se configura cuando haya conexión.

### Prueba que debe poder ver el jurado

1. Instalar y abrir sin internet en un equipo preparado desde cero.
2. Resolver una actividad; cerrar y volver a abrir.
3. Ver el progreso y seguir practicando mientras hay resultados pendientes.
4. Recuperar red y enviarlos a un receptor real.
5. Comprobar en la vista docente que aparecen una sola vez.
6. Cortar la conexión durante un envío y verificar que el reintento no pierde ni duplica datos.

Un botón que cambia de «sin conexión» a «enviado» dentro de una maqueta no demuestra este requisito. Tampoco lo demuestra solo un vídeo si se presenta como funcionamiento en vivo. El receptor puede ser pequeño y estar en una máquina accesible durante la demo; debe describirse honestamente dónde corre y qué conectividad usa.

## Windows y Android

Conservar Godot y Compatibility como punto de partida. Godot ofrece exportación Android y su documentación sitúa Compatibility como opción para 2D y equipos antiguos; eso no garantiza compatibilidad con cualquier tablet. [Renderizadores](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html), [exportar a Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).

Probar el paquete Android desde el primer día de implementación, no al final. Falta conocer el modelo real del dispositivo. Medir tamaño, arranque, memoria, fluidez, audio y precisión táctil. Establecer después requisitos mínimos verificables. No evaluar rendimiento solo en el ordenador con GPU donde se revisó la versión actual.

Un instalador local permite demostrar calidad sin publicar previamente en Google Play. La tienda sería otra fase con sus propias comprobaciones. La referencia de calidad visual sirve para diseñar; no debe convertirse en una promesa de publicación o certificación.

## Cuándo estará lista la primera versión

- Recorrido corto entendible por un niño, sin acompañamiento permanente.
- Controles reales y legibles en ambas plataformas.
- Un mundo completo con tres interacciones; no seis áreas de “próximamente”.
- Instrucciones y audio esenciales incluidos.
- Guardado separado por perfil, recuperable al reabrir.
- Progreso que describe acciones realmente evaluadas.
- Sincronización real con desconexión, reintento y deduplicación probados.
- Componente local de adaptación documentado y evaluable, con límites claros.
- Registro de procedencia, material anterior y trabajo realizado durante el evento.
- Evidencias de pruebas y limitaciones, sin resultados educativos inventados.

Estas son condiciones de aceptación propuestas para el equipo, no exigencias adicionales atribuidas a la organización. El reparto y el orden de implementación están en `PLAN_EQUIPO_HACK4EDU.md`.
