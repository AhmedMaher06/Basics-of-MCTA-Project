#include <Servo.h>
#include <SoftwareSerial.h>

SoftwareSerial A2Serial(2, 3);

Servo gateServo;
const int gateServoPin = 12;
const int gateClosed   = 180;
const int gateOpen     = 90;
const unsigned long gateTime = 600;

const int liftEn    = 11;
const int liftPin1  = 10;
int       liftSpeed = 100;

const int limitPin    = 4;
const int shootPin1   = 6;
const int shootPin2   = 5;
const int shootSensor = 7;

const int startSwitch = 8;
const int stopSwitch  = 9;

const int SPEED_TABLE[] = { 255, 255, 200, 150, 80, 40, 0 };
const int TABLE_SIZE    = sizeof(SPEED_TABLE) / sizeof(SPEED_TABLE[0]);
const int           RAMP_STEP_SIZE = 5;
const unsigned long RAMP_STEP_MS   = 10;
const unsigned long SHOOT_HOLD_MS  = 800;
const unsigned long DEBOUNCE_MS    = 90;
enum ShootState { IDLE, SHOOTING, RETURNING };
ShootState shootState = IDLE;

int  clickCount      = 0;
bool lastSwitchState = HIGH;
unsigned long lastDebounceTime = 0;
unsigned long shootStartTime   = 0;
int           currentSpeed = 0;
int           rampTarget   = 0;
unsigned long lastRampTime = 0;

bool gameRunning = false;
bool stopPending = false;
bool lastStartState = HIGH;
bool lastStopState  = HIGH;



void setup() {
  A2Serial.begin(9600);

  gateServo.attach(gateServoPin);
  gateServo.write (gateClosed);

  pinMode(liftEn,   OUTPUT);
  pinMode(liftPin1, OUTPUT);

  pinMode(shootPin1,   OUTPUT);
  pinMode(shootPin2,   OUTPUT);
  pinMode(shootSensor, INPUT );
  pinMode(limitPin,    INPUT_PULLUP);

  pinMode(startSwitch, INPUT_PULLUP);
  pinMode(stopSwitch,  INPUT_PULLUP);
}



void loop() {
  checkPhysicalSwitches();

  if (A2Serial.available()) {
    char cmd = (char)A2Serial.read();

    if (cmd == 'G') {
      gameRunning = true;
      openGateLift();
    }
    else if (cmd == 'N' && gameRunning) {
      openGateLift();
    }
    else if (cmd == 'X' && gameRunning) {
      stopPending = true;
    }
  }

  if (gameRunning) {
    updateRamp();
    Shooting();
  }
}



void checkPhysicalSwitches() {
  bool startState = digitalRead(startSwitch);
  bool stopState  = digitalRead(stopSwitch);

  if (startState == LOW && lastStartState == HIGH && !gameRunning) {
    gameRunning = true;
    openGateLift();
    A2Serial.print('G');
  }

  if (stopState == LOW && lastStopState == HIGH && gameRunning) {
    stopPending = true;
    A2Serial.print('X');
  }

  lastStartState = startState;
  lastStopState  = stopState;
}



void openGateLift() {
  gateServo.write(gateOpen);
  delay(gateTime);
  gateServo.write(gateClosed);
  analogWrite (liftEn, liftSpeed);
  digitalWrite(liftPin1, HIGH);
}



void Shooting() {
  switch (shootState) {

    case IDLE:
      if (digitalRead(shootSensor) == LOW) {
        digitalWrite(liftPin1, LOW);
        analogWrite (liftEn  , 0);
        delay(2000);
        clickCount     = 0;
        shootStartTime = millis();
        motorForward(SPEED_TABLE[0]);
        currentSpeed = SPEED_TABLE[0];
        rampTarget   = SPEED_TABLE[0];
        shootState   = SHOOTING;
      }
      break;

    case SHOOTING:
      if (millis() - shootStartTime >= SHOOT_HOLD_MS) {
        motorForward(SPEED_TABLE[0]);
        currentSpeed = SPEED_TABLE[0];
        rampTarget   = SPEED_TABLE[0];
        lastRampTime = millis();
        clickCount   = 0;
        shootState   = RETURNING;
      }
      break;

    case RETURNING:
      if (readLimit()) {
        clickCount++;
        int nextSpeed = SPEED_TABLE[clickCount];

        if (nextSpeed == 0) {
          motorStop();
          currentSpeed = 0;
          rampTarget   = 0;
          clickCount   = 0;
          shootState   = IDLE;

          A2Serial.print('D');

          if (stopPending) {
            gameRunning  = false;
            stopPending  = false;
            digitalWrite(liftPin1, LOW);
            analogWrite (liftEn  , 0);
            gateServo.write(gateClosed);
          }
        } else {
          rampTarget = nextSpeed;
        }
      }
      break;

    default:
      motorStop();
      currentSpeed = 0;
      rampTarget   = 0;
      shootState   = IDLE;
      break;
  }
}

void updateRamp() {
  if (currentSpeed <= rampTarget) return;

  if (millis() - lastRampTime >= RAMP_STEP_MS) {
    lastRampTime  = millis();
    currentSpeed -= RAMP_STEP_SIZE;
    if (currentSpeed < rampTarget) currentSpeed = rampTarget;
    motorForward(currentSpeed);
  }
}

bool readLimit() {
  bool currentState = digitalRead(limitPin);

  if (currentState == LOW && lastSwitchState == HIGH) {
    if (millis() - lastDebounceTime > DEBOUNCE_MS) {
      lastDebounceTime = millis();
      lastSwitchState  = LOW;
      return true;
    }
  }

  if (currentState == HIGH) lastSwitchState = HIGH;

  return false;
}

void motorForward(int spd) {
  analogWrite(shootPin1, spd);
  analogWrite(shootPin2, 0);
}

void motorStop() {
  analogWrite(shootPin1, 0);
  analogWrite(shootPin2, 0);
}
