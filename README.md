# Mirror Anomaly Clone — Garry's Mod addon

Oryginalny addon do Garry's Mod inspirowany klimatem tajemniczej, samooskarżającej anomalii: byt losowo pojawia się obok gracza albo po komendzie, kopiuje aktualny playermodel gracza, zmienia barwy, chodzi za nim i wypowiada krótkie, niepokojące kwestie na czacie.

> Addon nie zawiera modeli, głosów, dialogów ani znaków towarowych z Monogatari. Żeby uniknąć kopiowania cudzej postaci 1:1, mechaniki są zaprojektowane jako autorska „lustrzana anomalia”.

## Inspiracja zachowaniami

Na podstawie publicznych opisów Ougi Oshino z wiki fanowskich i dyskusji społeczności, vibe przekładamy na mechaniki zamiast kopiować postać:

- humanoidalna „oddity/anomalia” o niepewnej tożsamości;
- pojawia się przy ważnych momentach, jakby była już częścią rozmowy;
- zna rzeczy, których gracz „nie powiedział”, więc addon używa playermodelu i nicku gracza;
- działa jak zewnętrzna autokrytyka: osądza decyzje, kłamstwa i wymówki;
- jest spokojna, dociekliwa, trochę protekcjonalna;
- nie musi atakować — ma obserwować, chodzić za graczem i wywoływać dyskomfort.

## Struktura folderów

```text
mirror_anomaly_clone/
├── addon.json
├── README.md
└── lua/
    ├── autorun/
    │   └── ougi_anomaly.lua
    └── entities/
        └── ougi_anomaly_clone/
            ├── cl_init.lua
            ├── init.lua
            └── shared.lua
```

## Instalacja

1. Skopiuj folder addonu do:
   `GarrysMod/garrysmod/addons/mirror_anomaly_clone/`
2. Uruchom mapę. Najlepiej działa na mapach z navmeshem NextBota.
3. Jeśli mapa nie ma navmesha, wpisz w konsoli serwera:
   `nav_generate`
   i zrestartuj mapę po zakończeniu generowania.

## Komendy

- `ougi_spawn` — tworzy anomalię przy miejscu, na które patrzy admin, kopiując losowego żywego gracza albo admina.
- `ougi_spawn fragment_nicku` — tworzy anomalię kopiując gracza dopasowanego po nicku albo SteamID.
- `ougi_remove` — usuwa wszystkie aktywne anomalie.

## ConVary

- `ougi_autospawn 1` — włącza losowe spawny.
- `ougi_autospawn_min 180` — minimalny czas między próbami autospawnu.
- `ougi_autospawn_max 420` — maksymalny czas między próbami autospawnu.
- `ougi_max_clones 3` — maksymalna liczba aktywnych klonów.
- `ougi_spawn_radius 1400` — promień losowego spawnu od gracza.
- `ougi_talk_interval_min 18` — minimalny odstęp między kwestiami.
- `ougi_talk_interval_max 45` — maksymalny odstęp między kwestiami.

## Jak rozszerzyć klimat

- Dodaj własne, oryginalne kwestie do tablicy `VOICE_LINES` w `lua/entities/ougi_anomaly_clone/shared.lua`.
- Podmień `EmitSound` na własne legalnie posiadane pliki dźwiękowe w `sound/`.
- Dodaj efekt cząsteczek albo screen fade po `ENT:Speak`, jeżeli chcesz bardziej surrealistycznego wejścia.
- Użyj hooków mapy/trybu, żeby anomalia pojawiała się po konkretnych zdarzeniach fabularnych.
