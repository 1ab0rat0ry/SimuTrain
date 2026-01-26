# SimuTrain

[//]: # ([English]&#40;README.en.md&#41;)

SimuTrain je knižnica skriptov pre hru **Train Simulator Classic**, zameraná
na simuláciu brzdového systému železničných vozidiel.

Projekt je v ranom štádiu vývoja. Očakávajte chyby, chýbajúce či nedokončené
funkcie a možné zásadné zmeny v kóde.

## Inštalácia

Knižnicu je možné naištalovať použitím automatického inštalátora alebo manuálne.
Všetky verzie nájdete na stránke [releases](https://github.com/1ab0rat0ry/SimuTrain/releases).

### Automatická

Stiahnite si súbor označený ako **installer.exe**. Po spustení inštalátora skotrolujte,
či je správne zvolený priečinok s hrou. Inštalátor odstráni starú verziu a naištaluje novú.

### Manuálna

Stiahnite si súbor označený ako **manual.zip**. Pred naištalovaním novej verzie sa odporúča
odstrániť priečinok **Assets/1ab0rat0ry/SimuTrain**. Rozbaľte archív a priečinok **Assets**
skopírujte do priečinka **RailWorks**.

## Funkcie
- **Simulácia založená na fyzike:**
  - tlak sa počíta podľa stavovej rovnice ideálneho plynu
  - prietok vzduchu je určený vlastnosťami vzduchu, pomerom tlakov a veľkosťou dýzy
  - hydrodynamický model brzdového potrubia simuluje realistické šírenie tlakových vĺn
  v súprave, čo vedie k oneskorenej a pomalšej odozve pri brzdení a odbrzďovaní súpravy
- **Simulované zariadenia:**
  - brzdič **DAKO BS2**
  - rozvádzač **DAKO BV1**
  - rýchlomer **Hasler Bern**

## Obmedzenia
Aj keď cieľom je dosiahnuť čo najrealistickejšiu simuláciu, vzhľadom na obmedzenia hry
a potrebu vyváženia realizmu a náročnosti na výpočtový výkon, sú urobené niektoré
zjednodušenia. 

- simulácia prebieha iba v skripte vozidla ovládaného hráčom
- brzdná sila sa nedá aplikovať na jednotlivé vozidlá — ovplyvňuje
iba celú súpravu prostredníctvom hodnoty `TrainBrakeControl`
- vozidlá musia mať v simulačnom blueprinte správne nastavené pole `Max force 
percent of vehicle weight`, aby bola simulovaná správna brzdná sila
- automatické skladanie súpravy podľa vozňov pridaných v hre nie je podporované
- všetky procesy sú simulované ako izotermické, s pevne danou teplotou vzduchu 0 °C