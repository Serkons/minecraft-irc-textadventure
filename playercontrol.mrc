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
