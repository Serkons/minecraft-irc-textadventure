; Befehl im Channel: !eat [Gegenstand] (z.B. !eat Brot)
on *:TEXT:!eat *:#: {
  var %player = $nick
  var %food_name = $2-

  ; 1. Registrierungs- und Login-Check via $charfile
  if (!$exists($charfile(%player))) {
    msg $chan ❌ %player $+ , du musst dich zuerst mit !register registrieren!
    halt
  }
  var %online = $readini($charfile(%player), Info, IsLoggedIn)
  if (%online != 1) {
    msg $chan ❌ %player $+ , du musst eingeloggt sein, um etwas zu essen!
    halt
  }

  ; 2. Prüfen, ob der Spieler das Item überhaupt im Inventar hat
  var %file = $charfile(%player)
  var %has_amt = $readini(%file, Inventar, %food_name)
  if (%has_amt == $null) { var %has_amt = 0 }

  if (%has_amt < 1) {
    msg $chan 🎒 ❌ %player $+ , du hast die Nahrung 4 %food_name  nicht in deinem Rucksack!
    halt
  }

  ; 3. Nährwerte aus der items.db auslesen
  var %items_db = $mircdiritems\items.db
  var %type = $readini(%items_db, %food_name, Type)

  ; Sicherheitshalber prüfen, ob es wirklich essbar ist
  if (%type != Food) {
    msg $chan 🧱 ❌ %player $+ , du kannst 4 %food_name  nicht essen! Das ist keine Nahrung.
    halt
  }

  var %heal_val = $readini(%items_db, %food_name, Heal)
  var %food_val = $readini(%items_db, %food_name, Food)

  ; 4. Aktuelle Spieler-Stats auslesen
  var %cur_hp = $readini(%file, Stats, CurrentHP)
  var %max_hp = $readini(%file, Stats, MaxHP)
  var %cur_food = $readini(%file, Stats, CurrentFood)
  var %max_food = $readini(%file, Stats, MaxFood)

  ; Prüfen, ob der Spieler überhaupt hungrig oder verletzt ist
  if (%cur_hp >= %max_hp) && (%cur_food >= %max_food) {
    msg $chan 🎒 ❌ %player $+ , du bist bereits komplett satt und hast volle Lebenspunkte! Du musst nichts verschwenden.
    halt
  }

  ; 5. NEUE STATS BERECHNEN & AM MAXIMUM KAPPPEN
  var %new_hp = %cur_hp + %heal_val
  if (%new_hp > %max_hp) { var %new_hp = %max_hp }

  var %new_food = %cur_food + %food_val
  if (%new_food > %max_food) { var %new_food = %max_food }

  ; 6. INVENTAR & STATS AKTUALISIEREN
  var %new_inv_amt = %has_amt - 1
  writeini %file Inventar %food_name %new_inv_amt
  writeini %file Stats CurrentHP %new_hp
  writeini %file Stats CurrentFood %new_food

  ; 7. Schöne, atmosphärische Ausgabe ( 04=Rot für HP,  05=Braun für Hunger)
  msg $chan 🍎 😋 ** %player ** verputzt genüsslich ** $+ %food_name $+ **! *Mampf, schmatz...*
  msg $chan ❤️ [ %player ] Sättigung:  5 %new_food $+ / $+ %max_food  ♦ Gesundheit:  4 %new_hp $+ / $+ %max_hp ❤️
}


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

  ; Info im Channel ausgeben
  msg %chan 🎒 %player $+ , ich habe dir eine Übersicht deines Rucksacks per Privatnachricht gesendet!

  ; 3. KATEGORIEN-VARIABLEN ABSOLUT LEER VORBEREITEN
  var %file = $charfile(%player)
  var %items_db = $mircdiritems\items.db

  var %inv_bloecke = $null
  var %inv_material = $null
  var %inv_essen = $null
  var %inv_crafting = $null

  ; 4. DYNAMISCHE SCHLEIFE DURCH ALLE ITEMS IN DER DATEI
  var %total_items = $ini(%file, Inventar, 0)
  var %i = 1

  while (%i <= %total_items) {
    var %item_name = $ini(%file, Inventar, %i)
    var %item_count = $readini(%file, Inventar, %item_name)

    ; Nur verarbeiten, wenn die Anzahl wirklich größer als 0 ist
    if (%item_count > 0) {

      var %type = $readini(%items_db, %item_name, Type)
      ; Formatierung des Items: Itemname(Anzahl in Orange)
      var %format_item = %item_name $+ ( $+ %item_count $+  )

      if (%type == Block) {
        if (%inv_bloecke == $null) { %inv_bloecke = %format_item }
        else { %inv_bloecke = %inv_bloecke $+ , %format_item }
      }
      elseif (%type == Material) {
        if (%inv_material == $null) { %inv_material = %format_item }
        else { %inv_material = %inv_material $+ , %format_item }
      }
      elseif (%type == Food) {
        if (%inv_essen == $null) { %inv_essen = %format_item }
        else { %inv_essen = %inv_essen $+ , %format_item }
      }
      elseif (%type == Crafting) || (%type == Tool) || (%type == Weapon) || (%type == Armor) {
        if (%inv_crafting == $null) { %inv_crafting = %format_item }
        else { %inv_crafting = %inv_crafting $+ , %format_item }
      }
    }
    inc %i
  }

  ; 5. SELEKTIVE AUSGABE PER PN (Nur senden, wenn die Variable nicht $null ist!)
  .msg %player 📋 🎒 ********** **INVENTAR - %player ** **********
  if (%inv_bloecke != $null) { .msg %player 14[Blöcke]  %inv_bloecke }
  if (%inv_material != $null) { .msg %player 12[Material]  %inv_material }
  if (%inv_essen != $null) { .msg %player 3[Essen]  %inv_essen }
  if (%inv_crafting != $null) { .msg %player 15[Ausrüstung & Crafting]  %inv_crafting }

  ; Falls der Rucksack komplett leer sein sollte
  if (%inv_bloecke == $null) && (%inv_material == $null) && (%inv_essen == $null) && (%inv_crafting == $null) {
    .msg %player 🧳 *Dein Rucksack ist im Moment komplett leer...*
  }
  .msg %player ***************************************************
}

; Kleiner Hilfs-Alias, der 0 zurückgibt, falls ein Item noch gar nicht in der Datei steht
alias -l get_amt {
  var %val = $readini($1, Inventar, $2)
  return $iif(%val == $null, 0, %val)
}
