; -------------------------------------------------------------------------
; 📁 CUSTOM IDENTIFIER (Gibt den Pfad zur Spieler-Charakterdatei zurück)
; -------------------------------------------------------------------------
alias charfile {
  ; $mircdir liefert "C:\Steve\" -> wir hängen "database\" und den Dateinamen an
  return $mircdir $+ database\ $+ $1 $+ .char
}

; -------------------------------------------------------------------------
; 🤖 1. BOT-START (Bereinigt alte Login-Leichen bei einem Bot-Neustart)
; -------------------------------------------------------------------------
on *:START: {
  echo -a 🤖 Minecraft-RPG-System wird geladen...

  ; Schleife durch alle Charakterdateien, um IsLoggedIn beim Serverstart zurückzusetzen
  var %search_path = $mircdirdatabase\*.char
  var %total_files = $findfile($mircdirdatabase, *.char, 0)
  var %i = 1
  while (%i <= %total_files) {
    var %current_file = $findfile($mircdirdatabase, *.char, %i)
    ; Das spieler_template ignorieren wir natürlich
    if (spieler_template.char !isin %current_file) {
      writeini %current_file Info IsLoggedIn 0
    }
    inc %i
  }

  .timerMC_Cycle 0 600 mcrpg_time_cycle
}

alias mcrpg_time_cycle {
  var %sys_dat = $mircdirsystem.dat
  var -s %current = $readini(%sys_dat, Environment, TimeOfDay)

  if (%current == Tag) {
    writeini %sys_dat Environment TimeOfDay Nacht
    if ($chan(0) > 0) { msg $chan(1) 🌑 *Die Sonne geht unter und ein unheimliches Stöhnen hallt durch die Ferne... Die Nacht bricht an! Mobs sind nun aggressiver!* }
  }
  else {
    writeini %sys_dat Environment TimeOfDay Tag
    var %days = $readini(%sys_dat, Settings, WorldAgeDays)
    inc %days
    writeini %sys_dat Settings, WorldAgeDays %days
    if ($chan(0) > 0) { msg $chan(1) ☀️ *Die Sonnenstrahlen durchbrechen die Dunkelheit und verbrennen die Untoten. Ein neuer Tag bricht an! (Tag %days $+ )* }
  }
}

; -------------------------------------------------------------------------
; 🔐 2. REGISTRIERUNGS- & LOGIN-SYSTEM (Mit integriertem $charfile-Alias)
; -------------------------------------------------------------------------

on *:TEXT:!register:#: {
  var %player = $nick
  ; Auch hier den Backslash zwischen $mircdir und database entfernen!
  var %template = $mircdir $+ database\spieler_template.char

  ; Prüfen, ob der Spieler bereits eine Datei besitzt via $charfile
  if ($exists($charfile(%player))) {
    msg $chan ❌ %player $+ , du besitzt bereits einen Charakter! Nutze !login [Passwort] in einer PN an mich.
    halt
  }

  ; Prüfen, ob das Template existiert
  if (!$exists(%template)) {
    msg $chan ❌ Systemfehler: Das Spieler-Template fehlt! Bitte den Admin benachrichtigen.
    halt
  }

  ; Passwort generieren (Zufälliger 6-stelliger Code)
  var %pass = $rand(A,Z) $+ $rand(10,99) $+ $rand(A,Z) $+ $rand(10,99)
  var %crypt_pass = $encode(%pass, m)

  ; Template kopieren direkt an den Pfad von $charfile
  .copy -o %template $charfile(%player)

  ; --- NEU: ZUFÄLLIGES START-BIOM WÜRFELN ---
  var %world_db = $mircdirworld.db
  var %biom_liste = $readini(%world_db, Oberwelt_Biome, Liste)
  var %total_biomes = $numtok(%biom_liste, 46)
  var %random_index = $rand(1, %total_biomes)
  var %start_biom = 3 $gettok(%biom_liste, %random_index, 46) 

  ; Daten in die neue Charakterdatei schreiben
  writeini $charfile(%player) Info Name %player
  writeini $charfile(%player) Info Password %crypt_pass
  writeini $charfile(%player) Location Biom %start_biom
  writeini $charfile(%player) Location X $rand(-1000, 1000)
  writeini $charfile(%player) Location Z $rand(-1000, 1000)

  msg $chan 📝 %player wurde erfolgreich registriert und ist in einem fernen Biom ( $+ %start_biom $+ ) erwacht! Dein Passwort wurde dir per PN zugeschickt.

  ; Daten schreiben mit dem neuen Identifier
  writeini $charfile(%player) Info Name %player
  writeini $charfile(%player) Info Password %crypt_pass

  .msg %player 🗝️ Hallo %player $+ ! Dein generiertes Passwort lautet: ** %pass ** -> Melde dich im Channel an mit: /msg $me !login  %pass  an
}

; Befehl im Channel: !move
on *:TEXT:!move:#: {
  var %player = $nick

  if (!$exists($charfile(%player))) {
    msg $chan ❌ %player $+ , du musst dich zuerst mit !register registrieren!
    halt
  }
  var %online = $readini($charfile(%player), Info, IsLoggedIn)
  if (%online != 1) {
    msg $chan ❌ %player $+ , du musst eingeloggt sein, um dich zu bewegen!
    halt
  }

  ; --- NEU: HUNGER-CHECK ---
  var %current_food = $readini($charfile(%player), Stats, CurrentFood)
  if (%current_food <= 0) {
    msg $chan 🍖 ❌ ** %player ** du bist völlig am Ende deiner Kräfte und hast verdammt großen Hunger! Du bist zu erschöpft, um weiterzuwandern. Iss erst ein 7!eat [Essen]!
    halt
  }

  ; 1. Aktuelle Koordinaten auslesen
  var %old_x = $readini($charfile(%player), Location, X)
  var %old_z = $readini($charfile(%player), Location, Z)
  var %new_y = 64

  ; 2. HIMMELSRICHTUNG & DISTANZ WÜRFELN (30 bis 500 Blöcke)
  var %dist = $rand(30, 500)
  var %dir_roll = $rand(1, 4)
  var %richtung = Norden

  if (%dir_roll == 1) { var %richtung = Norden | var %new_x = %old_x | var %new_z = %old_z + %dist }
  if (%dir_roll == 2) { var %richtung = Süden | var %new_x = %old_x | var %new_z = %old_z - %dist }
  if (%dir_roll == 3) { var %richtung = Osten | var %new_x = %old_x + %dist | var %new_z = %old_z }
  if (%dir_roll == 4) { var %richtung = Westen | var %new_x = %old_x - %dist | var %new_z = %old_z }

  ; --- NEU: HUNGER-ABZUG BERECHNEN (Distanz / 100, mindestens 1 Punkt Abzug) ---
  var %food_loss = $floor($calc(%dist / 100))
  if (%food_loss < 1) { var %food_loss = 1 }

  var %new_food = %current_food - %food_loss
  if (%new_food < 0) { var %new_food = 0 }

  ; 3. STANDARD-BIOM WÜRFELN (Falls kein geheimer Posten getroffen wird)
  var %world_db = $mircdirworld.db
  var %biom_liste = $readini(%world_db, Oberwelt_Biome, Liste)
  var %total_biomes = $numtok(%biom_liste, 46)
  var %new_biom = $gettok(%biom_liste, $rand(1, %total_biomes), 46)
  var %entdeckung_text = Du hast ein neues Biom entdeckt:  3 $+ %new_biom 

  ; 4. CHECK AUF UNENDLICHE STRUKTUREN (Raster-Logik)
  var %mod_x = $calc(%new_x \\ 2500)
  var %mod_z = $calc(%new_z \\ 2500)
  if (%mod_x < 0) { var %mod_x = %mod_x + 2500 }
  if (%mod_z < 0) { var %mod_z = %mod_z + 2500 }

  if (%mod_x >= 1200) && (%mod_x <= 1300) && (%mod_z >= 1200) && (%mod_z <= 1300) {
    var %new_biom = Antike_Stadt
    var %new_y = -52
    var %entdeckung_text = 💀 ⚠️ **GEHEIMER ORT ENTDECKT:** Du bist in eine gewaltige, verlassene Stadt tief unter der Erde gestolpert... Stille umgibt dich, der Warden wacht!
  }
  elseif (%mod_x >= 400) && (%mod_x <= 600) && (%mod_z >= 1600) && (%mod_z <= 1800) {
    var %new_biom = Ozeanmonument
    var %entdeckung_text = 🔱 🌊 **GEHEIMER ORT ENTDECKT:** Aus den tiefen Wellen ragt ein monumentaler Prismin-Palast auf. Die Wächter haben dich im Visier!
  }
  elseif (%mod_x >= 2100) && (%mod_x <= 2200) && (%mod_z >= 200) && (%mod_z <= 300) {
    var %new_biom = Waldanwesen
    var %entdeckung_text = 🏰 🌲 **GEHEIMER ORT ENTDECKT:** Mitten im dichten, dunklen Wald ragt ein gigantisches, unheimliches Holzgebäude auf. Hier hausen die Illager!
  }

  ; 5. Neue Daten abspeichern (Inklusive neuer Sättigung!)
  writeini $charfile(%player) Location Biom %new_biom
  writeini $charfile(%player) Location X %new_x
  writeini $charfile(%player) Location Y %new_y
  writeini $charfile(%player) Location Z %new_z
  writeini $charfile(%player) Stats CurrentFood %new_food

  ; 6. Ausgabe im Channel ( 05=Braun für Hunger)
  msg $chan 🧭 🏃 ** %player ** wandert %dist Blöcke nach  12 $+ %richtung $+  ... ( 5- $+ %food_loss 🍖 )
  msg $chan 🗺️ [ %player ] %entdeckung_text $chr(124) Position:  7X:  %new_x  7Y:  %new_y  7Z:  %new_z
}


; Befehl im Channel: !status oder !pos (Reagiert auf beide Schreibweisen)
on *:TEXT:!status:#: { mcrpg_show_status $nick $chan }
on *:TEXT:!pos:#: { mcrpg_show_status $nick $chan }

alias mcrpg_show_status {
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
    msg %chan ❌ %player $+ , du musst eingeloggt sein, um deinen Status zu sehen! Nutze !login in einer PN.
    halt
  }

  ; 3. Sämtliche Daten via $charfile auslesen
  var %level = $readini($charfile(%player), Stats, Level)
  var %hp = $readini($charfile(%player), Stats, CurrentHP)
  var %max_hp = $readini($charfile(%player), Stats, MaxHP)
  var %mana = $readini($charfile(%player), Stats, CurrentMana)
  var %max_mana = $readini($charfile(%player), Stats, MaxMana)
  var %streak = $readini($charfile(%player), Stats, Killstreak)

  ; NEU: Sättigung auslesen
  var %food = $readini($charfile(%player), Stats, CurrentFood)
  var %max_food = $readini($charfile(%player), Stats, MaxFood)
  var %streak = $readini($charfile(%player), Stats, Killstreak)

  var %dimension = $readini($charfile(%player), Location, Dimension)
  var %biom = $readini($charfile(%player), Location, Biom)
  var %x = $readini($charfile(%player), Location, X)
  var %y = $readini($charfile(%player), Location, Y)
  var %z = $readini($charfile(%player), Location, Z)

  var %waffe = $readini($charfile(%player), Equipment, Waffe)

  ; NEU: Spitzhacke und Haltbarkeit auslesen
  var %pick = $readini($charfile(%player), Equipment, Spitzhacke)
  var %dur = $readini($charfile(%player), Equipment, Spitzhacke_Haltbarkeit)

  ; 4. Schöne, farbige Ausgabe im Channel generieren ( 03=Grün,  04=Rot,  07=Gold,  11=Hellblau,  =Reset)
  msg %chan 📊 ⚔️ **[ STATUS - %player ]**  $chr(124) Level:  7 %level  $chr(124) HP:  4 %hp $+ / $+ %max_hp  4  $chr(124) Ausdauer:  11 $+ %mana $+ / $+ %max_mana  11⚡ $chr(124) 11 Hunger:  5 %food / %max_food 
  msg %chan 📍 位置:  3 $+ %biom  ( $+ %dimension $+ ) $chr(124) Koordinaten:  7X:  %x  7Y:  %y  7Z:  %z  $chr(124) Killserie:  4 %streak   $chr(124) Waffe: %waffe . Picke: %pick ( $+ %dur $+ )
}



; Befehl per PN (Private Nachricht): !login [Passwort]
on *:TEXT:!login*:?: {
  var %player = $nick
  var %input_pass = $2
  var %main_chan = #RPG-Mc

  ; Prüfen via $charfile, ob eine Charakterdatei existiert
  if (!$exists($charfile(%player))) {
    .msg %player ❌ Du bist noch nicht registriert! Tippe !register im Channel.
    halt
  }

  ; Gespeichertes Passwort via $charfile auslesen und entschlüsseln
  var -s %saved_crypt = $readini($charfile(%player), Info, Password)
  var -s %decrypted_pass = $decode(%saved_crypt, m)

  if (%input_pass == %decrypted_pass) {

    var %already_online = $readini($charfile(%player), Info, IsLoggedIn)
    if (%already_online == 1) {
      .msg %player ❌ Du bist bereits im Spiel eingeloggt!
      halt
    }

    writeini $charfile(%player) Info IsLoggedIn 1
    .msg %player ✨ Erfolgreich angemeldet! Du hast nun Voice-Rechte im Channel erhalten. Viel Spaß beim Überleben!

    ; --- DYNAMISCHER ERST-LOGIN-RADAR ---
    var %first = $readini($charfile(%player), Info, FirstLogin)
    if (%first == off) {
      ; Wenn es der allererste Login ist, schalten wir das Flag auf 'on' und senden die Anleitung per PN
      writeini $charfile(%player) Info FirstLogin on
      .msg %player 🔐 **WICHTIGER HINWEIS:** Dies ist dein erster Login mit einem generierten Passwort. Es wird dringend empfohlen, dein Passwort jetzt zu ändern!
      .msg %player 📝 Tippe hier in der PN einfach: !password MEIN_NEUES_PASSWORT um es zu ändern.
    }

    var %dimension = $readini($charfile(%player), Location, Dimension)
    var %biom = $readini($charfile(%player), Location, Biom)
    var %x = $readini($charfile(%player), Location, X)
    var %y = $readini($charfile(%player), Location, Y)
    var %z = $readini($charfile(%player), Location, Z)

    if ($me ison %main_chan) {
      mode %main_chan +v %player

      ; Erste Nachricht: Der Spieler betritt den Server
      msg %main_chan 👋 ☀️ ** %player ** hat die Welt betreten und schärft seine Fäuste! Willkommen zurück!

      ; Zweite Nachricht: Die farbliche Standortmeldung ( 03 = Grün,  07 = Orange/Gold,   = Reset)
      msg %main_chan 📍 [ %player ] Du erwachst im Biom:  3 $+ %biom  ( $+ %dimension $+ ) - Position:  7X:  %x  7Y:  %y  7Z:  %z
    }
  }
}

; Befehl im Channel: !logout
on *:TEXT:!logout:#: {
  var %player = $nick
  var %main_chan = #RPG-MC

  ; 1. Prüfen, ob der Spieler registriert ist und eine Datei hat
  if (!$exists($charfile(%player))) {
    msg $chan ❌ %player $+ , du hast noch gar keinen Charakter registriert!
    halt
  }

  ; 2. Prüfen, ob der Spieler überhaupt als eingeloggt markiert ist
  var %status = $readini($charfile(%player), Info, IsLoggedIn)
  if (%status != 1) {
    msg $chan 🎒 %player $+ , du bist aktuell gar nicht eingeloggt!
    halt
  }

  ; 3. Login-Status in der Datei auf 0 setzen
  writeini $charfile(%player) Info IsLoggedIn 0

  ; 4. Voice-Rechte im Channel entziehen und Verabschiedung ausgeben
  if ($me ison %main_chan) {
    mode %main_chan -v %player
    msg %main_chan 💤 ** %player ** hat sein Lager aufgeschlagen und sich abgemeldet. Bis zum nächsten Mal!
  }
}

; -------------------------------------------------------------------------
; 🔐 PASSWORT ÄNDERN (Nur per PN ausführbar)
; -------------------------------------------------------------------------
; -------------------------------------------------------------------------
; 🔐 PASSWORT ÄNDERN (Sichere Version mit Abfrage des alten Passworts)
; -------------------------------------------------------------------------
on *:TEXT:!password*:?: {
  var %player = $nick
  var %old_pass = $2
  var %new_pass = $3

  ; 1. Prüfen, ob der Charakter existiert
  if (!$exists($charfile(%player))) {
    .msg %player ❌ Du besitzt keinen Charakter! Registriere dich zuerst im Channel mit !register.
    halt
  }

  ; 2. NEUER SECURITY-CHECK: Prüfen, ob das Passwort bereits einmal geändert wurde
  var %changed = $readini($charfile(%player), Info, ChangedPass)
  if (%changed == on) {
    .msg %player ❌ Sicherheitssperre: Du hast dein Passwort bereits geändert. Eine erneute Änderung ist nicht erlaubt!
    halt
  }

  ; 2. Prüfen, ob der Spieler eingeloggt ist
  var %online = $readini($charfile(%player), Info, IsLoggedIn)
  if (%online != 1) {
    .msg %player ❌ Du musst eingeloggt sein, um dein Passwort zu ändern!
    halt
  }

  ; 3. SICHERHEITS-CHECK: Altes Passwort auslesen, entschlüsseln und prüfen
  var %saved_crypt = $readini($charfile(%player), Info, Password)
  var %decrypted_pass = $decode(%saved_crypt, m)

  if (%old_pass != %decrypted_pass) {
    .msg %player ❌ Sicherheitssperre: Das angegebene alte Passwort ist falsch! Änderung verweigert.
    halt
  }

  ; 4. Validierung des neuen Passworts
  if (%new_pass == $null) {
    .msg %player ❌ Fehler: Du musst ein neues Passwort angeben! Syntax: !password [altes_passwort] [neues_passwort]
    halt
  }
  if ($len(%new_pass) < 4) {
    .msg %player ❌ Dein neues Passwort muss mindestens 4 Zeichen lang sein!
    halt
  }

  ; 5. Neues Passwort verschlüsseln und speichern
  var %crypt_pass = $encode(%new_pass, m)
  writeini $charfile(%player) Info Password %crypt_pass

  ; 6. Flags aktualisieren (FirstLogin löschen, ChangedPass auf 'on' setzen)
  remini $charfile(%player) Info FirstLogin
  writeini $charfile(%player) Info ChangedPass on

  .msg %player 🔑 Dein Passwort wurde erfolgreich geändert und sicher verschlüsselt hinterlegt!
}

; -------------------------------------------------------------------------
; 🔄 AUTOMATISCHER LOGOUT (Setzt IsLoggedIn in der Datei wieder auf 0)
; -------------------------------------------------------------------------
on !*:PART:#MC-RPG: {
  if ($exists($charfile($nick))) {
    writeini $charfile($nick) Info IsLoggedIn 0
    echo -a 🤖 [$nick] Automatisch ausgeloggt (Channel verlassen).
  }
}

on !*:QUIT: {
  if ($exists($charfile($nick))) {
    writeini $charfile($nick) Info IsLoggedIn 0
    echo -a 🤖 [$nick] Automatisch ausgeloggt (Server verlassen).
  }
}
