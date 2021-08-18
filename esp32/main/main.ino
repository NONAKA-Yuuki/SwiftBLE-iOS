#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

// UUIDジェネレータ↓
// https://www.uuidgenerator.net/

#define SERVICE_UUID        "63d6672b-986b-406f-9f6f-6a712d015e04"
#define CHARACTERISTIC_UUID "2ec43578-5fcd-4c0e-8758-ffeb77537a83"
static int LED_PIN = 13;



class MyCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic* pCharacteristic)
  {
    std::string value = pCharacteristic->getValue();
    
    if(value.length() > 0)
    {
      String ledState = value.c_str();
      Serial.println(ledState);
      if (ledState == "0")
      {
        digitalWrite(LED_PIN, LOW);
      }
      else if(ledState == "1")
      {
        digitalWrite(LED_PIN, HIGH);
      }
    }
  }
};


void setup()
{
  Serial.begin(115200);

  pinMode(LED_PIN, OUTPUT);

  BLEDevice::init("ESP32_BLE_SERVER"); // この名前がスマホなどに表示される
  BLEServer* pServer = BLEDevice::createServer();
  BLEService* pService = pServer->createService(SERVICE_UUID);
  BLECharacteristic* pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ |
    BLECharacteristic::PROPERTY_WRITE
  ); // キャラクタリスティックの作成　→　「僕はこんなデータをやり取りするよできるよ」的な宣言

  pCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // iPhone接続の問題に役立つ
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Characteristic defined! Now you can read it in your phone!");
}

void loop()
{
  delay(2000);
}
