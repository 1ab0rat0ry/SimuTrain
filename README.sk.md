# SimuTrain
[English](README.md)

SimuTrain je knižnica skriptov pre hru **Train Simulator Classic**, ktorá simuluje
fungovanie brzdového systému železničných vozidiel. Pre čo najvernejšiu simuláciu
jednotlivých komponentov využíva fyzikálne rovnice a vzorce.

⚠️ Projekt je vo veľmi ranom štádiu vývoja. Očakávajte chyby, chýbajúce či nedokončené
funkcie a možné zásadné zmeny v kóde. ⚠️

## Funkcie
- **Simulácia na úrovni jednotlivých vozňov:**
  - každý vozeň v súprave má simulované vlastné brzdové vybavenie
  - vozidlá produkujú brzdnú silu podľa ich konfigurácie a tlaku v brzdovom valci
- **Fyzikálne riadená simulácia:**
  - tlak sa počíta podľa stavovej rovnice ideálneho plynu
  - prietok vzduchu je určený vlastnosťami vzduchu, pomerom tlakov a veľkosťou dýzy
  - hydrodynamický model brzdového potrubia simuluje realistické šírenie tlakových vĺn
  v súprave, čo vedie k oneskorenej a pomalšej odozve pri brzdení a odbrzďovaní súpravy
- **Simulované zariadenia:**
  - brzdič **Dako BS2**
  - rozvádzač **Dako BV1**

## Obmedzenia
Aj keď cieľom je dosiahnuť čo najrealistickejšiu simuláciu, vzhľadom na obmedzenia hry
a potrebu vyváženia realizmu a náročnosti na výpočtový výkon, sú urobené 
niektoré zjednodušenia. 

- simulácia prebieha iba v skripte vozidla ovládaného hráčom
- brzdná sila sa nedá aplikovať na jednotlivé vozidlá — ovplyvňuje
iba celú súpravu prostredníctvom hodnoty `TrainBrakeControl`
- vozidlá musia mať v simulačnom blueprint-e správne nastavené pole `Max force 
percent of vehicle weight`, aby bola simulovaná správna brzdná sila
- automatické skladanie súpravy podľa vozňov pridaných v hre nie je podporované
- všetky procesy sú simulované ako izotermické, s pevne danou teplotou vzduchu 0 °C