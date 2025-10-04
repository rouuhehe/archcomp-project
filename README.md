# archcomp-project

# FSM y Diseño de la ALU en Punto Flotante (IEEE-754) — Basys3

> Documento: diagrama de estados, descripción de etapas, señales, ejemplos de micro-ops y un esqueleto Verilog para la FSM.

---

## Resumen rápido

Diseño secuencial (FSM) que implementa operaciones FP (half/single) en una ALU para Basys3. El flujo general sigue etapas claras: carga de operandos, descomposición, alineamiento, operación aritmética, normalización, redondeo y salida. `start` arranca la FSM; `valid_out` indica que el resultado está listo. `mode_fp` selecciona half (0) o single (1).

---

## Diagrama de Estados (alto nivel)

```
IDLE --(start)--> LOAD
LOAD --> DECODE
DECODE --> ALIGN
ALIGN --> EXECUTE
EXECUTE --> NORMALIZE
NORMALIZE --> ROUND
ROUND --> WRITEBACK
WRITEBACK --> DONE
DONE --(ack/reset?)--> IDLE
```

### Notas breves sobre transiciones

* `IDLE`: espera `start=1` y operandos estables.
* `LOAD`: latch de `op_a/op_b`, clear flags temporales.
* `DECODE`: extrae signo, exponente, mantisa, detecta NaN/Inf/zero/denormal, decide atajos (p.ej. si NaN → saltar a WRITEBACK con NaN).
* `ALIGN`: (suma/resta) alinea mantisas por diferencia de exponentes; (mul/div) prepara operandos para mantissa op.
* `EXECUTE`: operación aritmética principal — suma/resta/alínea+sum, mul con producto entero de mantisas, div con algoritmo iterativo (o usar unidad combinacional si cabe).
* `NORMALIZE`: ajusta el resultado (shift left/right), corrige exponente.
* `ROUND`: aplica round-to-nearest-even (y prepara `inexact` flag si difiere).
* `WRITEBACK`: empaqueta signo+exponente+mantisa, setea flags finales (overflow, underflow, div-by-zero, invalid, inexact).
* `DONE`: `valid_out=1` hasta que `start` baje o se haga `ack` (según interfaz).

---

## Señales principales y handshake sugerido

* Entradas: `op_a[31:0]`, `op_b[31:0]`, `op_code[2:0]`, `mode_fp`, `clk`, `rst`, `round_mode`, `start`.
* Salidas: `result[31:0]` (si `mode_fp=0` usar lower 16 bits), `valid_out`, `flags[4:0]`.

Handshake simple: `start` es pulso (1 ciclo) y la FSM guarda operandos en LOAD. `valid_out` se mantiene en 1 hasta que el sistema detecta `start=0` y vuelve a IDLE (o hasta que `ack` sea 1 si añades ack).

---

## Etapas (micro-op) detalladas

### DECODE

* Separar: `sign = bits[N-1]`, `exp = bits[N-2:mant_width]`, `frac = bits[mant_width-1:0]`.
* Detectar especiales: `isNaN`, `isInf`, `isZero`, `isDenormal`.
* Para denormales, el exponente efectivo es `1 - bias` y la mantisa no tiene el implicit leading 1.

### ALIGN (solo add/sub)

* Calcular `exp_diff = exp_a - exp_b` (abs).
* Shift right la mantisa del operando con menor exponente por `exp_diff` (cuidar guard/round/sticky bits).
* Guard/round/sticky: mantener 2-3 bits extras para rounding seguro.

### EXECUTE

* ADD/SUB: suma/resta de mantisas alineadas (usar signed mantissa si es resta o signos distintos).
* MUL: multiplicación entera de mantisas (m+1 * n+1 -> 2*(mant_width+1) bits), sumar exponentes y ajustar bias.
* DIV: implementar algoritmo de división (resto-resto o shift-subtract iterativo) o uso de módulo combinacional/recurrencia si tiempo lo permite.

### NORMALIZE

* Si MSB fuera 0 (subnormalizar), shift left y decrementar exponente.
* Si overflow en mantisa (por ejemplo producto con carry), shift right y aumentar exponente.

### ROUND

* Implementar round-to-nearest-even: usar guard, round y sticky para decidir increment.
* Detectar `inexact` si bits truncados no eran todos cero.

### WRITEBACK

* Componer `result`: signo || exp || frac (truncar o saturar en caso de overflow a Inf, setear NaN según regla).
* Setear flags: overflow, underflow (exponente fuera de rango), divide-by-zero (para DIV cuando op_b=0 y op_a≠0), invalid (e.g., 0/0, Inf-Inf, sqrt(neg) if aplicara), inexact.

---

## Tamaños y bias

* **Single (32-bit)**: sign=1, exp=8, frac=23, bias=127.
* **Half (16-bit)**: sign=1, exp=5, frac=10, bias=15.

Ajuste: cuando `mode_fp=0` (half), debes convertir/interpretar los 16 LSB de `op_a/op_b` o bien aceptar que `op_a/op_b` vienen ya en los 32 bits con formato half en lower bits.

---

## Esqueleto FSM en Verilog (pseudocódigo)

```verilog
// Solo FSM + señales; detalles aritméticos en módulos separados
module fp_alu_fsm(
  input clk, rst,
  input start,
  input mode_fp,
  input [31:0] op_a, op_b,
  input [2:0] op_code,
  output reg [31:0] result,
  output reg valid_out,
  output reg [4:0] flags
);
  typedef enum logic [3:0] {IDLE, LOAD, DECODE, ALIGN, EXECUTE, NORMALIZE, ROUND, WRITEBACK, DONE} state_t;
  state_t state, next_state;

  // registros intermedios
  reg [31:0] a_reg, b_reg;
  // señales: sign_a, exp_a, frac_a, ... (dependen de mode_fp)

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else state <= next_state;
  end

  always @(*) begin
    // default
    next_state = state;
    case (state)
      IDLE: if (start) next_state = LOAD;
      LOAD: next_state = DECODE;
      DECODE: /* shortcuts if special */ next_state = ALIGN;
      ALIGN: next_state = EXECUTE;
      EXECUTE: next_state = NORMALIZE;
      NORMALIZE: next_state = ROUND;
      ROUND: next_state = WRITEBACK;
      WRITEBACK: next_state = DONE;
      DONE: if (!start) next_state = IDLE; // or wait ack
    endcase
  end

  // Lógica de cada estado en bloques separados (o módulos)

endmodule
```

> Nota: separa la aritmética compleja en módulos (`fp_decode`, `fp_align`, `fp_addsub`, `fp_mul`, `fp_div`, `fp_normalize`, `fp_rounder`) para mantener el código limpio y testeable.

---

## Consideraciones prácticas para Basys3

* No esperes ejecutar operaciones muy complejas en un único ciclo por recursos; mejor uso de FSM secuencial.
* Multiplicación de mantisas (24x24) y división pueden consumir muchos LUTs; optimiza con shifts y reuse de lógica.
* Usa `XDC` para mapear LEDs y switches para probar: por ejemplo, switches para `start`, `mode_fp`, `op_code`, displays/leds para `valid_out` y `flags`.

---

## Testbench y verificación

* Testbench debe poder: generar aleatorios (5000+ vectores), chequear contra una referencia (C/Python con `struct` y `numpy.float32`/`float16`).
* Casos explícitos: NaN, Inf, -Inf, +0, -0, denormales, overflow, underflow, 0/0, x/0, Inf-Inf.
* Verificar `round-to-nearest-even` comparando bits.
* Registrar: número de vectores probados, fallos y traza (dump VCD + .csv con entradas/esperados/obtenidos).

---

## Sugerencias para empezar (pasos mínimos)

1. Implementa `fp_decode` y detección de especiales.
2. Implementa ADD/SUB pipeline de 5 estados (ALIGN, ADD, NORMALIZE, ROUND, WRITEBACK).
3. Test bench: valida con una función de referencia en Python (usa `numpy.float32`/`float16`).
4. Añade MUL, luego DIV (si hay tiempo).

---

Si quieres, en la próxima versión te pongo:

* Diagrama de estados en dibujo (SVG ASCII o mermaid) listo para poner en el informe.
* Un skeleton de módulos con puertos y comentarios lista-para-copiar a tu repo.

Fin del documento.
