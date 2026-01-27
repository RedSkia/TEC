#include <Arduino.h>

// Should we log
#define LOG

// Pins
constexpr uint8_t MOTOR = 33;

constexpr uint8_t HUMIDITY_SENSOR = 34;
constexpr uint8_t HUMIDITY_LED = 22;

constexpr uint8_t NEED_MORE_WATER_SENSOR = 35;
constexpr uint8_t NEED_MORE_WATER_LED = 5;

constexpr uint8_t WATER_LEVEL_LOW_SENSOR = 32;
constexpr uint8_t WATER_LEVEL_LOW_LED = 21;

float_t get_humidity(uint8_t pin) {
  // The max is typically 4095, but to make it scalable, in case it changes, we
  // have this
  static float_t MaxHum = 1;
  float_t hum_raw = analogRead(pin);
  MaxHum = max(MaxHum, hum_raw);

  // Get the humidity
  return ((MaxHum - hum_raw) / MaxHum) * 100;
}

void setup(void) {
  // Set the pin mode for the sensor
  pinMode(MOTOR, OUTPUT);
  pinMode(HUMIDITY_LED, OUTPUT);
  pinMode(NEED_MORE_WATER_LED, OUTPUT);
  pinMode(WATER_LEVEL_LOW_LED, OUTPUT);
  pinMode(NEED_MORE_WATER_SENSOR, INPUT);
  pinMode(WATER_LEVEL_LOW_SENSOR, INPUT);

  Serial.begin(115200);
}

void loop(void) {
  // Read the anolog value from the sensor

  float_t hum = get_humidity(HUMIDITY_SENSOR);
  bool nmw = !digitalRead(NEED_MORE_WATER_SENSOR);
  bool wll = digitalRead(WATER_LEVEL_LOW_SENSOR);
  bool hlb = hum <= 2;

  // Do we need to fill up the water
  static uint8_t NeedMoreWaterState = nmw;
  if (NeedMoreWaterState != nmw)
    digitalWrite(NEED_MORE_WATER_LED, NeedMoreWaterState = nmw);

  // Start/Stop the motor
  bool start_motor = wll || hlb;
  static uint8_t MotorState = start_motor;
  if (MotorState != start_motor)
    digitalWrite(MOTOR, !(MotorState = start_motor));

  // Is the humidity bad
  static uint8_t HumidityState = hlb;
  if (HumidityState != hlb)
    digitalWrite(HUMIDITY_LED, HumidityState = hlb);

  // Is the water level low
  static uint8_t WaterLevelLowState = wll;
  if (WaterLevelLowState != wll)
    digitalWrite(WATER_LEVEL_LOW_LED, WaterLevelLowState = wll);

#ifdef LOG
  Serial.printf("Motor: %d\n", MotorState);
  Serial.printf("Humidity: %d [%f%%]\n", hlb, hum);
  Serial.printf("Water Level: %d\n", WaterLevelLowState);
  Serial.printf("Need More Water: %d\n", NeedMoreWaterState);
#endif

  // We make a delay cause the humidity value, might not be consisten, and might
  // jump
  delay(100);
}
