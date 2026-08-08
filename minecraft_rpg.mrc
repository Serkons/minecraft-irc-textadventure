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

  ; Daten schreiben mit dem neuen Identifier
  writeini $charfile(%player) Info Name %player
  writeini $charfile(%player) Info Password %crypt_pass

  msg $chan 📝 %player wurde erfolgreich in der Welt registriert! Dein Passwort wurde dir per PN zugeschickt.
  .msg %player 🗝️ Hallo %player $+ ! Dein generiertes Passwort lautet: ** %pass ** -> Melde dich im Channel an mit: /msg $me !login  %pass  an
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

    ; HIER DEINE NEUE LOGIK: Prüfen, ob IsLoggedIn in der Datei bereits auf 1 steht
    var %already_online = $readini($charfile(%player), Info, IsLoggedIn)
    if (%already_online == 1) {
      .msg %player ❌ Du bist bereits im Spiel eingeloggt! Ein doppelter Login ist nicht erlaubt.
      halt
    }

    ; Wert in der Datei auf 1 setzen
    writeini $charfile(%player) Info IsLoggedIn 1  

    .msg %player ✨ Erfolgreich angemeldet! Du hast nun Voice-Rechte im Channel erhalten. Viel Spaß beim Überleben!

    ; --- STANDORT-DATEN AUS DER CHARAKTERDATEI LESEN ---
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
      msg %main_chan 📍 [%player] Du erwachst im Biom:  3 $+ %biom  ( $+ %dimension $+ ) - Position:  7X:  %x  07Y:  %y  07Z:  %z
    }
  }
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
