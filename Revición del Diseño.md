# Gathel — Extracción y análisis por temas

Basado en el caso **“Caso #3 - Gathel, Gaming the life - 45%”** del repositorio `vsurak/cursostec`, este documento resume y extrae las partes clave solicitadas, organizadas por tema.

## 1. Reglas de negocio

Gathel es un juego digital de predicciones sobre acciones y eventos reales de personas. La dinámica central es que un jugador crea una proposición sobre otra persona, esa proposición pasa por validaciones y después otros usuarios predicen si ocurrirá o no.

Reglas principales:

- Cada jugador inicia con **100 puntos**.
- Una proposición puede ser rechazada por la persona afectada.
- Si la persona rechaza la proposición, pierde **1 punto** y la propuesta se cierra.
- Si la acepta, la proposición pasa a estado activo y se define una fecha límite para recibir predicciones.
- Los jugadores pueden apostar con **puntos virtuales**, **dinero real** o ambos, según el evento.
- Con puntos, el máximo permitido por predicción es **1 punto**.
- Con dinero real, el monto es libre, pero no puede modificarse después del cierre de la etapa de predicciones.
- La plataforma debe validar antes de aceptar una proposición que la persona afectada tenga margen para cubrir posibles penalizaciones.
- Si el sistema no logra validar un resultado, devuelve los recursos a los participantes y aplica una penalización del **15% de los puntos actuales** al jugador asociado a la proposición.

## 2. Seguridad

Puntos de seguridad relevantes:

- El acceso a contenido de redes sociales requiere **autorización explícita** del usuario.
- La plataforma analiza contenido antes de publicar proposiciones para bloquear temas ilegales, violentos, sexuales, discriminatorios, fraudulentos o contrarios a las reglas.
- Existen reglas claras y términos de uso para proteger la integridad moral, física y de salud de las personas.
- El sistema debe impedir que usuarios no autorizados visualicen información sensible, como el detalle de proposiciones más votadas.
- La seguridad también abarca la protección de saldos, transacciones y resultados del juego.
- El caso sugiere una arquitectura con control fuerte de acceso, validación y trazabilidad de operaciones.

## 3. Economía del juego

Componentes económicos:

- Los puntos funcionan como moneda virtual interna.
- El balance inicial es de 100 puntos por jugador.
- Los jugadores pueden perder puntos al apostar, al rechazar proposiciones o por penalizaciones.
- Los puntos perdidos en apuestas se distribuyen proporcionalmente entre los ganadores, descontando comisiones.
- La plataforma también maneja dinero real para apuestas y pagos.
- Los jugadores pueden retirar ganancias mediante transferencias bancarias u otros métodos soportados.
- Si un jugador se queda sin puntos, puede comprarlos directamente.
- Comercios afiliados pueden ofrecer productos o servicios canjeables por puntos.
- Gathel mantiene actividad continua, con eventos y proposiciones permanentes entre usuarios conectados.

## 4. Transferencias y pagos

El sistema maneja operaciones financieras reales, por lo que necesita control transaccional y contable sólido.

Aspectos clave:

- Las apuestas con dinero real deben registrarse como transacciones controladas.
- El dinero apostado puede aumentar antes del cierre de la proposición.
- Una vez cerrada la etapa de predicciones, no se permiten cambios.
- Al resolverse el evento, el dinero acumulado se distribuye entre ganadores.
- La plataforma descuenta comisiones antes de entregar premios.
- Los retiros de ganancias deben integrarse con métodos de pago y transferencias bancarias.
- Las compras de puntos también forman parte del flujo financiero.
- Todo movimiento debe quedar registrado para auditoría y conciliación.

## 5. Procesamiento de AI

La inteligencia artificial es una capa central del flujo de Gathel.

Funciones de AI descritas en el caso:

- Analizar automáticamente contenido antes de publicar proposiciones.
- Detectar temas prohibidos o conflictivos.
- Validar evidencia multimedia.
- Detectar manipulación o falsificación.
- Interpretar si una proposición se cumplió.
- Solicitar evidencia adicional cuando exista ambigüedad.
- Permitir validación manual cuando el sistema automático no sea concluyente.

El caso no solo pide usar AI, sino modelar un proceso de validación automatizado con posibilidad de revisión humana.

## 6. Integración con redes sociales

Gathel depende directamente de redes sociales para capturar evidencia y verificar proposiciones.

Lo que se extrae del caso:

- Un jugador puede vincular una o varias cuentas de redes sociales.
- Ejemplos explícitos: Instagram y TikTok.
- La plataforma solicita autorización para acceder a contenido público o autorizado por el usuario.
- El sistema consulta publicaciones, historias, reels, videos y otro contenido similar.
- La evidencia del evento debe incluir referencias o hashtags asociados a Gathel.
- Las redes sociales sirven tanto para detectar el contexto de una proposición como para validar su resultado.

## 7. Normalización

El modelo debe estar normalizado para evitar redundancia y facilitar el mantenimiento.

Principios observables en el caso:

- Separación clara entre jugadores, proposiciones, predicciones, resultados, pagos, balances, redes sociales y auditoría.
- Catálogos independientes para tipos, estados, métodos y fuentes.
- Historial separado de la entidad principal para conservar trazabilidad.
- Evitar guardar información repetida en tablas operativas.
- Uso de tablas intermedias para relaciones muchos-a-muchos.
- El diseño favorece una estructura escalable y modular.

Una buena normalización aquí permite que el sistema soporte crecimiento sin duplicar lógica ni mezclar responsabilidades.

## 8. Diseño optimizado para altos volúmenes de inserts y pocos updates

El caso menciona explícitamente la necesidad de soportar muchos inserts y pocos updates.

Eso implica:

- Modelo orientado a eventos y registros históricos.
- Preferencia por tablas append-only donde sea posible.
- Evitar actualizar balances o estados sin dejar huella.
- Mantener bitácoras y logs para cada cambio importante.
- Diseñar el flujo para que el sistema inserte transacciones, resultados y auditorías, en lugar de sobrescribir datos constantemente.
- Minimizar contención sobre filas de alta demanda.

Este enfoque es adecuado para apuestas, eventos y validaciones, donde cada operación debe quedar registrada.

## 9. Autenticación y autorización

La autenticación y la autorización deben estar bien separadas.

Del caso se desprende que:

- El usuario se registra e inicia sesión en la plataforma.
- Puede asociar redes sociales mediante autorización.
- Deben existir controles para decidir quién puede ver, crear o validar proposiciones.
- La persona afectada por una proposición tiene privilegios especiales sobre ciertos datos.
- El sistema necesita manejar roles, permisos y validaciones de acceso.
- El acceso a contenido, saldos y resultados no debe ser universal.

La autorización no solo aplica al backend, sino también a la visibilidad de información dentro del juego.

## 10. Eventos del juego

La lógica del juego está organizada alrededor de eventos y estados.

Secuencia general:

- 1. Un usuario publica o genera una proposición.
- 2. La AI revisa el contenido.
- 3. Otros usuarios votan.
- 4. Pasado el tiempo definido, se selecciona la propuesta ganadora.
- 5. La persona implicada acepta o rechaza.
- 6. Si acepta, se abre la etapa de predicciones.
- 7. Los usuarios apuestan con puntos o dinero.
- 8. El día del evento se publica evidencia.
- 9. La AI valida el resultado.
-  10. Se distribuyen premios o se aplican penalizaciones.

Esto hace que el modelo sea fuertemente temporal y basado en estados.

## 11. Monitoreo

El caso sugiere necesidad de monitoreo continuo del sistema.

Se debe monitorear:

- Creación de proposiciones.
- Votos recibidos.
- Cambios de estado.
- Validaciones automáticas.
- Fallas de la AI.
- Operaciones de pago.
- Retiros y compras.
- Errores de acceso o autorización.
- Casos de validación manual.

Monitorear este flujo permite detectar fallas operativas, fraude o desacoples entre módulos.

## 12. Observabilidad

La observabilidad debe permitir entender qué pasó, cuándo pasó y por qué pasó.

Debe incluir:

- Logs de procesos automáticos.
- Registro de solicitudes y respuestas de AI.
- Seguimiento de intentos de login.
- Registro de cambios sobre proposiciones y resultados.
- Trazabilidad de transacciones financieras.
- Evidencia de fuentes sociales consultadas.

La observabilidad es especialmente importante porque el sistema mezcla reglas del juego, análisis automático y dinero real.

## 13. Auditoría

La auditoría es indispensable porque el sistema maneja apuestas, balances y decisiones sensibles.

Debe auditarse:

- Quién creó una proposición.
- Quién votó.
- Quién aceptó o rechazó.
- Qué cambió en un resultado.
- Qué transacción financiera ocurrió.
- Qué validación hizo la AI.
- Qué operación produjo un cambio de saldo.
- Qué usuario ejecutó una acción administrativa.

El caso justifica que todo tenga registro histórico y que las acciones sean verificables.

## 14. Trazabilidad

La trazabilidad en Gathel es total y debe cubrir el ciclo completo de cada evento.

Debe poder rastrearse:

- Desde la red social de origen hasta la evidencia.
- Desde la proposición hasta su validación final.
- Desde una apuesta hasta su liquidación.
- Desde un login o intento fallido hasta su resultado.
- Desde una acción humana hasta el resultado automático o manual asociado.

Esto permite reconstruir casos de disputa, auditoría y análisis interno.

## 15. Rendimiento

El rendimiento es crítico porque la plataforma puede crecer rápido.

Requisitos derivados del caso:

- Consultas frecuentes sobre proposiciones activas.
- Lectura de votos y predicciones en tiempo real.
- Validación de evidencias multimedia.
- Cálculo de saldos y recompensas.
- Operaciones financieras concurrentes.
- Uso intensivo de inserciones.

La estrategia debe minimizar bloqueos, reducir consultas costosas y distribuir el trabajo entre tablas especializadas.

## 16. Particionamiento

El particionamiento es útil especialmente para tablas de alto crecimiento.

Candidatas naturales:

- Logs de auditoría.
- Procesos de AI.
- Transacciones de puntos y dinero.
- Intentos de login.
- Historial de resultados.
- Eventos y predicciones cerradas.

La partición puede ser por fecha o por estado, para mantener rendimiento y facilitar mantenimiento.

## 17. Índices

El caso sugiere crear índices en campos usados frecuentemente.

Campos clave para indexar:

- playerID
- propositionID
- predictedAt
- transactionDate
- estado de proposición
- estado de pago
- fecha de ejecución de procesos
- referencias a redes sociales
- identificadores de auditoría

Los índices deben apoyar tanto búsquedas operativas como consultas de trazabilidad y reportes.

## 18. Escalabilidad

Gathel está pensado para crecer en usuarios, eventos, apuestas y contenido.

La escalabilidad se logra mediante:

- Separación por módulos funcionales.
- Registro de eventos en tablas dedicadas.
- Procesamiento asíncrono de validación de AI.
- Minimización de updates masivos.
- Historial y auditoría bien estructurados.
- Índices adecuados.
- Posible particionamiento de tablas grandes.
- Arquitectura capaz de soportar muchas inserciones simultáneas.

