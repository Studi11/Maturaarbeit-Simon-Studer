//  *************************************************************************
//  *  Dies ist ein Arduino Yun Programm, das für die Maturaarbeit 2014/15  *
//  *                  von Simon Studer entwickelt wurde.                   *
//  *   Es ist zum Zeitpunkt der Abgabe (5.1.2015) die finale Version des   *
//  *   Programms und wird in Zukunft verbessert oder verändert im Ordner   *
//  *                             /postRelease/                             *
//  *                             aktualisiert.                             *
//  *************************************************************************

// Dieses Programm/Sketch wird mithilfe der Arduino IDE auf den Arduino Yun geladen
                                        

// Aufrufen der zusätzlich benötigten Libraries
#include <Process.h>
#include <Bridge.h>
#include <YunServer.h>
#include <YunClient.h>

// globale Variablen
 int sniffing=0;        // Speichert aktueller Zustand 1:an / 0:aus
 int interval=5*60;     // Intervaldauer in Sekunden
 long currTime=0L;      // Speichert ständig aktualisierte Zeit auf dem Arduino in Unixtime
 long loopStart=5L;     // Speichert die Zeit beim Start eines Intervals
 String currSniff="0";  // Speichert die aktuelle Versuchsnummer
 String workingDir="";  // Speicher den aktuellen Arbeitsordner
 
 YunServer server;      // Initialisiert einen neuen server-Handler für den Access Point
 Process process;       // Initialisiert einen neuen process-Handler für Befehle an den Linux-Prozessor
  
  
  
  
  
  
void setup() {                      // wird zu Beginn des Programs einmal ausgeführt
  pinMode(13, OUTPUT);              // stellt den Pin Nummer 13 auf Output, was das Kontrollieren der roten LED auf dem Arduino ermöglicht
  digitalWrite(13, HIGH);           // schaltet die LED ein
  Bridge.begin();                   // erstellt eine Verbindung zum Linux-Prozessor und wartet auf eine positive Rückmeldung
  server.listenOnLocalhost();       // sagt dem server-Handler nur auf Anfragen von Clients zu reagieren
  server.begin();                   // startet den server-Handler mit den eingestellten Einstellungen
  digitalWrite(13, LOW);            // schaltet die LED aus um das Ende des ersten Setupteilse zu signalisieren
  delay(1000);                      // wartet 1 Sekunde
  
  
  
  
  
  
 // Kommunikation mit verbundene Clients, um weiter Einstellungen vorzunehmen 
  int continuevar=0;                                            // wenn ungleich 0 wird die folgende Schleife nicht mehr ausgeführt (Schleifenkontrolle)
  while (continuevar==0){                                       // Schleife um Clientanfragen immer wieder zu behandeln bis continuevar ungleich 0 ist
    YunClient client=server.accept();                           // Versucht eine Verbindung mit einem möglichen Client aufzubauen
    if (client) {                                               // wenn der Verbindungsaufbau mit dem Client erfolgreich ist, führt dies folgende Befehle aus, sonst wird direkt die Verbindung gestoppt und gewartet
      String urlcmd=client.readStringUntil('/');                  // liest den ersten Teil (bis zum ersten "/") des REST Befehls und speichert ihn
      urlcmd.trim();                                              // entfernt Leerzeichen im Befehl
      if (urlcmd=="sync") {                                       // falls der Befehl "sync" ist und somit synchronisiert werden soll
        String synctime= client.readStringUntil('/');               // liest den zweiten Teil (bis zum nächsten "/") des REST Befehls und speichert ihn
        synctime.trim();                                            // entfernt Leerzeichen im Befehl
        synctime=synctime.substring(0,synctime.indexOf('.'));       // entfernt die Angabe der Millisekunden
        Process setTime;                                            // Initialisiert einen neuen process-Handler mit dem namen setTime
        String cmdTimeStrg = "date +%s -s @" + synctime;            // speichert den Befehl für den process setTime (Befehl: setze die Arduino-Zeit auf synctime Sekunden nach Unixtime)
        setTime.runShellCommand(cmdTimeStrg);                       // führt den process setTime aus
      } else if (urlcmd=="continue") {                            // falls der Befehl "continue" ist...
        continuevar=1;                                              // ... wird continuevar auf ungleich 0 gesetzt und somit im Programmcode nach der while-Schleife weitergefahren
      } else if (urlcmd=="arduinoTime") {                         // falls der Befehl "arduinoTime" ist
        String jk=boardTime("date");                                // speichert die aktuelle Arduino-Zeit
        client.print(jk);                                           // gibt dem Client die aktuelle Zeit als Antwort zurück (wird mit Javascript auf der Website empfangen)
      } else if (urlcmd=="interval") {                            // falls der Befehl "interval" ist (wurde auf der Website deaktiviert)
        String lange= client.readStringUntil('/');                  // liest den zweiten Teil (bis zum nächsten "/") des REST Befehls und speichert ihn als intervallänge
        lange.trim();                                               // entfernt Leerzeichen im Befehl
        interval=lange.toInt();                                     // setzt globale Variable auf die übertragene Dauer
        }
    }
    client.stop();                                              // beendet die Verbindung mit dem Client in jedem Fall
    delay(10);                                                  // wartet 10 Millisekunden, um den Arduino nicht zu überlasten
  }
  processCommand("airmon-ng start wlan0");          // lässt den Arduino aus Access Point Modus zu Monitormodus umschalten
  delay(20000);                                     // wartet 20 Sekunden, um den Monitormodus sicher aktiviert zu haben
  processCommand("airmon-ng stop wlan0");           // beendet den Monitor scheinbar wieder, wechselt allerdings nicht mehr zum Access Point Modus
  delay(2000);                                      // wartet 2 Sekunden, um dem vorderen Befehl genügend Zeit zu geben
  currTime=toLong(boardTime("since70"));            // aktualisiert currTime
  startSniff();                                     // startet die Sniff-Vorbereitung, fährt anschliessend weiter in der Haupt loop()
}






// Hauptschleife des Programms
void loop() {
  currTime=toLong(boardTime("since70"));                                    // aktualisiert currTime
  
  if (currTime>interval+loopStart && currTime<interval+loopStart+300) {     // überprüft vergangene Zeit und ob ein Intervall seit letztem Intervallstart vorbeigegangen ist
    restartInterval();                                                        // wenn das so ist wird ein neuer Intervalldurchgang gestartet
  }
  
  delay(40);                 // lässt den 
  digitalWrite(13, LOW);     // Arduino blinken
  delay(40);                 // während er den 
  digitalWrite(13, HIGH);    // Funk ausliest
}






// Sniff-Vorbereitung
void startSniff() {
  digitalWrite(13, HIGH);                                                                   // schaltet die LED ein, signalisiert den Beginn eines Sniffs
  currSniff=processCommand("lua /mnt/sda1/arduino/programs/analyseWlan/createFolder.lua");  // speichert/aktualisiert die neue Versuchsnummer
  
    workingDir="/mnt/sda1/arduino/programs/analyseWlan/output/"+currSniff+"/";              // erstellt den Namen des neuen Arbeitsverzeichnis anhand der neuen Versuchsnummer
    processCommand("mkdir "+workingDir);                                                    // erstellt den neuen Ordner/das neue Arbeitsverzeichnis
    sniffing=1;                                                                             // aktualisiert den aktuellen Sniffing-Zustand
    processCommand("airmon-ng stop wlan0");                                                 // stoppt alte Instanzen des Monitormodus, da sonst in der folgenden Zeile mehrere entstehen
    processCommand("airmon-ng start wlan0");                                                // startet den Monitormodus auf dem "wlan0"-Interface
    processCommand("airodump-ng -w "+workingDir+"outputFile wlan0 &");                      // startet das loggen des WLAN-Funkverkehr in die Datei "outputFile.csv"
    loopStart=currTime;;                                                                    // aktualisiert die Zeit des nun beginnenden Intervals
}




    
// Beginnt das nächst Intervall
void restartInterval() {
    //update analyse
    String currStringTime=boardTime("since70");                                                                     // ermittelt Unixtime                                   
    String fromFile="/mnt/sda1/arduino/programs/analyseWlan/output/"+currSniff+"/outputFile-01.csv";                // speichert den Dateipfad+Namen der Ausgabedatei von airodump-ng
    String toFile="/mnt/sda1/arduino/programs/analyseWlan/output/"+currSniff+"/outputFile-"+currStringTime+".csv";  // speichert den Dateipfad+Namen Kopierten Ausgabedatei von airodump-ng
    processCommand("cp "+fromFile+" "+toFile);                                                                      // kopiert die Ausgabedatei von airodump-ng zur "toFile"
 
 if (sniffing==0) {                   // wenn der Sniff gestoppt werden soll (fand in den Versuchen nie statt) und sniffing dazu bereits aktualisiert wurde
    stopSniff();                        // stopp den SniffVersuch
  } else {                            // sonst wird die Zeit des nun beginnenden Intervals aktualisiert 
    loopStart=currTime;;
  }
}








// stoppt den SniffVersuch (deaktiviert)
void stopSniff() {
  processCommand("airmon-ng stop mon0");                                              // stoppt den Monitormodus
  processCommand("airmon-ng stop mon1");                                              // stoppt allfällige ungewünschte Instanzen des Monitormodus
  
  processCommand("rm /mnt/sda1/arduino/programs/analyseWlan/output/*/*.netxml");      //nicht benötigte Dateien werden entfernt
  processCommand("rm /mnt/sda1/arduino/programs/analyseWlan/output/*/*.kismet.csv");
}








// dient der Befehlsübergabe an Linux und die Antwort Rückerhaltung und Ausgabe
String processCommand (String command) {
  process.runShellCommand(command);
  String b="";
  delay(20);
  while (process.available() > 0) {
    char c = process.read();
    b=b+c;
  }
  return b;
}






// verwandelt eine Zahl in Wort/String Form in eine Zahl des Typs long um (ähnlich toInt, das es bereits gibt)
long toLong(String sWhat) {
  return atol(sWhat.c_str());       // The Arduino Compiler should accept C++ code. (Seen in: https://arduino.stackexchange.com/questions/816/c-vs-the-arduino-language , third comment by Adam Davis)
}






// ermittelt Unixtime oder das formatierte Datum ung gibt dies zurück
String boardTime(String para) {
  Process time;
  time.begin("date");
  if (para=="since70") {
    time.addParameter("+%s");
  } else if (para=="date") {
    time.addParameter("+%H:%M.%S  %d.%m.%Y");
  }
  time.run();
  String boardTime="";
  while (time.available()>0) {
    char c=time.read();
    if (c!='\n');
    boardTime +=c;
  }
  if (para=="since70"){boardTime=boardTime.substring(0,10);}
  return boardTime;
}



