; Befehl im Channel: !inventar oder !inv (Reagiert auf beide Schreibweisen)
on *:TEXT:!inventar:#: { mcrpg_show_inventory $nick $chan }
on *:TEXT:!inv:#: { mcrpg_show_inventory $nick $chan }

alias mcrpg_show_inventory {
  var %player = $1
  var %chan = $2

  ; 1. Prüfen, ob der Charakter registriert ist
  if (!$exists($charfile(%player))) {
    msg %chan ❌ %player $+ , du musst dich zuerst mit !register registrieren!
    halt
  }

  ; 2. Prüfen, ob der Spieler eingeloggt ist
  var %online = $readini($charfile(%player), Info, IsLoggedIn)
  if (%online != 1) {
    msg %chan ❌ %player $+ , du musst eingeloggt sein, um dein Inventar zu sehen! Nutze !login in einer PN.
    halt
  }

  ; 3. DYNAMISCHE SCHLEIFE DURCH DIE INVENTAR-SEKTION
  var %file = $charfile(%player)
  var %total_items = $ini(%file, Inventar, 0)
  var %i = 1
  var %inv_string = ""

  while (%i <= %total_items) {
    ; Holt den Namen des Gegenstands (z.B. Brot)
    var %item_name = $ini(%file, Inventar, %i)
    ; Holt die Anzahl des Gegenstands (z.B. 3)
    var %item_count = $readini(%file, Inventar, %item_name)

    ; Nur Gegenstände anzeigen, die der Spieler auch wirklich besitzt (größer als 0)
    if (%item_count > 0) {
      ; Wir kleben die Gegenstände mit einem Punkt getrennt aneinander
      if (%inv_string == "") { var %inv_string = %item_name $+ ( 07 $+ %item_count $+  ) }
      else { var %inv_string = %inv_string  . %item_name $+ ( 07 $+ %item_count $+  ) }
    }
    inc %i
  }

  ; 4. Schöne Ausgabe im Channel generieren
  msg %chan 🎒 **[ INVENTAR - %player ]**
  if (%inv_string == "") {
    msg %chan    *Dein Rucksack ist im Moment komplett leer... Zeit, Materialien zu sammeln!*
  }
  else {
    msg %chan 📦 %inv_string
  }
}
