# ⛏️ Minecraft IRC-Textadventure (v1.21.11)

Willkommen im Repository des **Minecraft IRC-Textadventure**! Dies ist ein umfangreiches, textbasiertes Rollenspiel (RPG), das komplett über einen **mIRC-Bot (mIRC Scripting Language - MSL)** gesteuert wird. Tauche ein in die Welt von Minecraft 1.21.11 („Mounts of Mayhem“) – direkt über dein IRC-Terminal.

Das Spiel kombiniert das klassische Sammeln und Erkunden von Minecraft mit einem taktischen, **rundenbasierten Kampfsystem**, gefährlichen Dungeons und interaktiven NPCs.

---

## 🎮 Features
* **🌍 64 Biome entdecken:** Reise durch die Welten der Oberwelt, des Nethers und des Endes.
* **⛏️ Ressourcen sammeln:** Baue Hölzer, Erze, Steine und Naturblöcke ab, um dein Inventar zu füllen.
* **⚔️ Rundenbasiertes Kampfsystem:** Kämpfe strategisch gegen die Monster der Minecraft-Welt mit Aktionen wie Angreifen, Blocken oder Heilen.
* **🏰 Dungeons & Strukturen:** Erkunde Minenschächte, Festungen und die neuen Trial Chambers, um seltenen Loot zu bergen.
* **🗣️ NPC- & Handelssystem:** Triff Dorfbewohner (Villager) und reisende Händler für Quests, Tauschgeschäfte und Story-Fortschritt.
* **🎒 RPG-Mechaniken:** Verwalte dein Inventar, steige im Level auf, verbessere deine Attribute und schmiede mächtige Rüstungen.
* **🤖 mIRC-Power:** Volle Steuerung über einfache Chat-Befehle direkt im IRC-Kanal.

---

## 📂 Projekt-Struktur
Das Projekt ist modular aufgebaut, um Daten und Programmlogik sauber voneinander zu trennen:

* 📁 **/biome/** – Listen aller Biome, getrennt nach Dimensionen.
  * `biome_oberwelt.txt`
  * `biome_nether.txt`
  * `biome_ende.txt`
  * `biome_spezial.txt`
* 📁 **/blocks/** – Ressourcen-Listen für die Oberwelt.
  * `oberwelt_holzbloecke.txt`
  * `oberwelt_steinsorten.txt`
  * `oberwelt_erze_mineralien.txt`
  * `oberwelt_naturbloecke.txt`
* 📁 **/database/** – Lokaler Datenspeicher für Spielerprofile (HP, Inventar, Level).
* 📄 `minecraft_rpg.mrc` – Das Hauptskript des Bots (MSL).
* 📄 `.gitignore` – Sicherheitsfilter, damit Passwörter und Serverdaten privat bleiben.

---

## 🚀 Erste Schritte (Installation)
*Die genaue Installationsanleitung folgt, sobald das Hauptskript `minecraft_rpg.mrc` einsatzbereit ist!*

---

## 📜 Lizenz
Dieses Projekt ist unter der **MIT-Lizenz** lizenziert. Du kannst den Code gerne für deine eigenen IRC-Bots nutzen, modifizieren und erweitern.

