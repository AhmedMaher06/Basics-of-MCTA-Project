#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

SoftwareSerial A1Serial (3, 2);
SoftwareSerial AppSerial(4, 5);

const int motionSen     = A1;
const int colorSen      = A2;
const int scoreSenRight = 6;
const int scoreSenLeft  = 9;
const int missSenRight  = 7;
const int missSenLeft   = 8;

const int motorEN       = 10;
const int motorPin1     = 11;
const int motorPin2     = 12;
const int joyPin        = A0;
const int limitA        = 13;
const int limitB        = A3;

const int MOTOR_PWM  = 70;
const int JOY_CENTER = 512;
const int THRESHOLD  = 400;

bool multiPlayer  = false;
bool gameRunning  = false;
bool stopPending  = false;
int  points       = 0;
int  points2      = 0;

bool colorSensing       = false;
bool isWhite            = false;
bool ballDetected       = false;
bool currentMotionState = false;
bool prevMotionState    = false;
unsigned long colorSenseStart = 0;

bool anyFired                   = false;
int  lastSensor                 = -1;
unsigned long lastFiredMillis   = 0;
const unsigned long SETTLE_TIME = 700;

// Incoming byte buffers — one per serial port
String appBuffer = "";
String a1Buffer  = "";



void setup() {
  AppSerial.begin(9600);
  A1Serial.begin (9600);

  pinMode(motionSen    , INPUT);
  pinMode(colorSen     , INPUT);
  pinMode(scoreSenRight, INPUT);
  pinMode(scoreSenLeft , INPUT);
  pinMode(missSenRight , INPUT);
  pinMode(missSenLeft  , INPUT);
  pinMode(motorPin1    , OUTPUT);
  pinMode(motorPin2    , OUTPUT);
  pinMode(motorEN      , OUTPUT);
  pinMode(limitA       , INPUT_PULLUP);
  pinMode(limitB       , INPUT_PULLUP);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Waiting for app");
}



void loop() {
  joyStick();

  AppSerial.listen();
  unsigned long tApp = millis();
  while (millis() - tApp < 5) {
    if (AppSerial.available()) {
      char c = (char)AppSerial.read();
      if (c == '\n' || c == '\r') {
        if (appBuffer.length() > 0) {
          handleAppCommand(appBuffer.charAt(0));
          appBuffer = "";
        }
      } else {
        appBuffer += c;
      }
    }
  }
  if (appBuffer.length() == 1) {
    handleAppCommand(appBuffer.charAt(0));
    appBuffer = "";
  }

  A1Serial.listen();
  unsigned long tA1 = millis();
  while (millis() - tA1 < 5) {
    if (A1Serial.available()) {
      a1Buffer += (char)A1Serial.read();
    }
  }
  for (int i = 0; i < (int)a1Buffer.length(); i++) {
    handleA1Command(a1Buffer.charAt(i));
  }
  a1Buffer = "";

  if (gameRunning) {
    checkBallColor();
    checkScoring();
  }
}



void handleAppCommand(char cmd) {
  switch (cmd) {
    case 'S': startGame();         break;
    case 'X': stopGame();          break;
    case 'M': multiPlayer = true;  break;
    case '1': multiPlayer = false; break;
  }
}



void handleA1Command(char message) {
  if (message == 'G' && !gameRunning) {
    gameRunning = true;
    stopPending = false;
    points  = 0;
    points2 = 0;

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(multiPlayer ? "   Multi mode   " : "  Single mode   ");
  }
  else if (message == 'X' && gameRunning) {
    stopPending = true;
  }
  else if (message == 'D') {
    if (stopPending && !ballDetected && !anyFired) {
      gameRunning = false;
      stopPending = false;
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Game over");

      AppSerial.listen();
      AppSerial.print("STOPPED\n");
    }
  }
}



void startGame() {
  gameRunning = true;
  stopPending = false;
  points  = 0;
  points2 = 0;

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(multiPlayer ? "   Multi mode   " : "  Single mode   ");

  A1Serial.listen();
  A1Serial.print('G');
}



void stopGame() {
  A1Serial.listen();
  A1Serial.print('X');
  stopPending = true;
}



void checkBallColor() {
  currentMotionState = (digitalRead(motionSen) == LOW);

  if (currentMotionState && !prevMotionState) {
    ballDetected    = true;
    anyFired        = false;
    isWhite         = false;
    lastSensor      = -1;
    lastFiredMillis = 0;
    colorSenseStart = millis();
    colorSensing    = true;
  }

  if (colorSensing) {
    if (digitalRead(colorSen) == LOW) {
      isWhite      = true;
      colorSensing = false;
    } else if (millis() - colorSenseStart >= 400UL) {
      colorSensing = false;
    }

    if (!colorSensing) {
      lcd.clear();
      lcd.setCursor(0, 0);
      if (!multiPlayer) {
        lcd.print(isWhite ? "   White ball   " : "   Black ball   ");
        lcd.setCursor(0, 1);
        lcd.print(isWhite ? " Score this one " : " Miss this one  ");
      } else {
        lcd.print(isWhite ? "   White ball   " : "   Black ball   ");
        lcd.setCursor(0, 1);
        lcd.print(isWhite ? " Player 1 turn  " : " Player 2 turn  ");
      }
    }
  }

  prevMotionState = currentMotionState;
}



void checkScoring() {
  bool reading[4];
  reading[0] = (digitalRead(scoreSenRight) == LOW);
  reading[1] = (digitalRead(scoreSenLeft)  == LOW);
  reading[2] = (digitalRead(missSenRight)  == LOW);
  reading[3] = (digitalRead(missSenLeft)   == LOW);

  for (int i = 0; i < 4; i++) {
    if (reading[i] && !anyFired) {
      lastSensor      = i;
      anyFired        = true;
      lastFiredMillis = millis();
    }
  }

  if (anyFired && ballDetected && (millis() - lastFiredMillis >= SETTLE_TIME)) {
    bool isMiss  = (lastSensor == 2 || lastSensor == 3);
    bool isRight = (lastSensor == 0 || lastSensor == 2);

    lcd.clear();
    lcd.setCursor(0, 0);

    if (!multiPlayer) {
      if (!isMiss) {
        if      ( isWhite &&  isRight) points += 2;
        else if ( isWhite && !isRight) points += 1;
        else if (!isWhite &&  isRight) points -= 2;
        else if (!isWhite && !isRight) points -= 1;
        lcd.print(isWhite ? "   Brilliant!   " : "     OUCH!      ");
      } else {
        lcd.print(isWhite ? "   Missed :(    " : "  Nice dodge :) ");
      }
    } else {
      if (isWhite && !isMiss) {
        if (isRight) points  += 2; else points  += 1;
        lcd.print("   P1 scores!   ");
      } else if (!isWhite && !isMiss) {
        if (isRight) points2 += 2; else points2 += 1;
        lcd.print("   P2 scores!   ");
      } else if (isWhite && isMiss) {
        lcd.print("   P1 missed!   ");
      } else {
        lcd.print("   P2 missed!   ");
      }
    }

    lcd.setCursor(0, 1);
    if (!multiPlayer) {
      lcd.print("Score: ");
      lcd.print(points);
    } else {
      lcd.print("P1:");
      lcd.print(points);
      lcd.print("  P2:");
      lcd.print(points2);
    }

    AppSerial.listen();
    AppSerial.print("P1:");
    AppSerial.print(points);
    AppSerial.print(",P2:");
    AppSerial.print(points2);
    AppSerial.print('\n');

    if (!stopPending) {
      A1Serial.listen();
      A1Serial.print('N');
    }

    lastSensor      = -1;
    lastFiredMillis = 0;
    anyFired        = false;
    isWhite         = false;
    ballDetected    = false;
  }
}



void joyStick() {
  bool switchA = (digitalRead(limitA) == LOW);
  bool switchB = (digitalRead(limitB) == LOW);

  int  joyDev    = analogRead(joyPin) - JOY_CENTER;
  bool pushRight = (joyDev >  THRESHOLD);
  bool pushLeft  = (joyDev < -THRESHOLD);

  if (pushRight) {
    if (switchA) motorStop();
    else         motorForward();
  } else if (pushLeft) {
    if (switchB) motorStop();
    else         motorBackward();
  } else {
    motorStop();
  }
}

void motorForward() {
  digitalWrite(motorPin1, HIGH);
  digitalWrite(motorPin2, LOW);
  analogWrite (motorEN, MOTOR_PWM);
}

void motorBackward() {
  digitalWrite(motorPin1, LOW);
  digitalWrite(motorPin2, HIGH);
  analogWrite (motorEN, MOTOR_PWM);
}

void motorStop() {
  digitalWrite(motorPin1, LOW);
  digitalWrite(motorPin2, LOW);
  analogWrite (motorEN, 0);
}
