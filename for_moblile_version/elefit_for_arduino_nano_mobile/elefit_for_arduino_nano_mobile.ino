///* Bluetooth通信に必要 */
//#include "BluetoothSerial.h"  //ArduinoのBluetooth通信に使用
//BluetoothSerial BTS;  //BTSという名前でオブジェクトを定義
//
///* 制御命令保存用の変数 */
//String input = "1000;";
//
//// the setup function runs once when you press reset or power the board
//void setup() {
//  // initialize digital pin LED_BUILTIN as an output.
//  pinMode(LED_BUILTIN, OUTPUT);
//  Serial.begin(115200);               //シリアルモニタで確認用。伝送速度を115200[bps]に設定
//  BTS.begin("Elefit");  //接続画面で表示される名前を設定 ★好きな名前にしてよい
//
//}
//
//// the loop function runs over and over again forever
//void loop() {
//  if (BTS.available()) {               //available()で受信した文字があるか確認。あればif文内の処理を実行。
//    t1 = millis();                        //データを取得した時間を記録
//    input = BTS.readStringUntil(';');  //文字をセミコロン(;)まで読んで、文字列として変数inputに保存。
//    delay_time = input.toInt();  //入力値を整数に変換
//  }
//  digitalWrite(LED_BUILTIN, HIGH);   // turn the LED on (HIGH is the voltage level)
//  delay(delay_time);                       // wait for a second
//  digitalWrite(LED_BUILTIN, LOW);    // turn the LED off by making the voltage LOW
//  delay(delay_time);                       // wait for a second
//}
