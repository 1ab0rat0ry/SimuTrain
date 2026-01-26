# SimuTrain
[Slovenčina](README.md)

SimuTrain is a script library for the game **Train Simulator Classic** that simulates
the functioning of railway brake systems. It uses physical equations and formulas
to achieve the most faithful representation of individual components.

⚠️ This project is in a very early stage of development. Expect bugs, missing
or incomplete features, and potentially major breaking changes. ⚠️

## Features
- **Per-vehicle simulation:**
  - each vehicle in a consist has its own simulated brake equipment
  - vehicles generate brake forces based on their configuration 
  and brake cylinder pressure
- **Physics-based modeling:**
  - pressure calculated using the ideal gas law
  - airflow determined by air properties, pressure ratio, and orifice area
  - a fluid dynamics brake pipe model simulates realistic propagation
  of pressure waves within a consist, causing delayed and slower response
  in brake application and release
- **Simulated equipment:**
  - brake valve **Dako BS2**
  - distributor **Dako BV1**

## Limitations
While the goal is to provide the most realistic simulation possible,
some simplifications are necessary due to game limitations
or to balance realism and performance.

- all simulation runs in the script of the player-driven vehicle
- brake force cannot be applied individually per vehicle — only to the entire consist
using the `TrainBrakeControl` value
- vehicles must have the field `Max force percent of vehicle weight`
correctly configured in their simulation blueprint to produce proper brake force
- automatic consist composition based on vehicles added in-game is not supported
- all simulated processes are currently assumed to be isothermal,
with air temperature fixed at 0 °C
