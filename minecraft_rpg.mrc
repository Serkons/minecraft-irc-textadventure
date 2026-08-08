; -------------------------------------------------------------------------
; 📁 CUSTOM IDENTIFIER (Gibt den Pfad zur Spieler-Charakterdatei zurück)
; -------------------------------------------------------------------------
alias charfile {
  ; $mircdir liefert "C:\Steve\" -> wir hängen "database\" und den Dateinamen an
  return $mircdir $+ database\ $+ $1 $+ .char
}

; -------------------------------------------------------------------------
; 🤖 1. BOT-START & TAG/NACHT-TIMER (Simuliert den Minecraft-Tageszyklus)
; -------------------------------------------------------------------------
on *:START: {
  echo -a 🤖 Minecraft-RPG-System wird geladen...
  ; Starte den Tag/Nacht-Wechsel-Timer (600 Sekunden = 10 Minuten pro Phase)
  .timerMC_Cycle 0 600 mcrpg_time_cycle
}

alias mcrpg_time_cycle {
  var %sys_dat = $mircdirsystem.dat
  var %current = $readini(%sys_dat, Environment, TimeOfDay)

  if (%current == Tag) {
    writeini %sys_dat Environment TimeOfDay Nacht
    if ($chan(0) > 0) { msg $chan(1) 🌑 *Die Sonne geht unter und ein unheimliches Stöhnen hallt durch die Ferne... Die Nacht bricht an! Mobs sind nun aggressiver!* }
  }
  else {
    writeini %sys_dat Environment TimeOfDay Tag
    ; Hier wurde der Punkt im INI-Pfad korrigiert
    var %days = $readini(%sys_dat, Settings, WorldAgeDays)
    inc %days
    writeini %sys_dat Settings, WorldAgeDays %days

    ; HIER IST DIE KORREKTUR: Leerzeichen vor und nach %days eingefügt, damit mIRC die Variable sauber erkennt!
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
