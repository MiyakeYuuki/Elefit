/*ハードウェアの接続ピンの設定*/
//#define LED_PIN 2 //走行には無関係。2番ピンにLEDのアノード(+)を接続すると割り込み処理の間隔(100ms)でLEDが点滅

String input=""; // スマホアプリの信号を保存しておく変数

void setup(){
  Serial.begin(115200); //シリアル通信の伝送速度を1115200[bps]に設定
  pinMode(LED_BUILTIN, OUTPUT); //LEDの点灯ピンを出力用に設定
}

void loop(){

  if(Serial.available()>0){
    input = Serial.readStringUntil(';');  //文字をセミコロン(;)まで読んで、文字列として変数inputに保存。
  }
  /*受信した信号を表示*/
  Serial.print("input=");
  Serial.print(input);
  Serial.println();

  /*入力した文字列に応じて動作を設定*/
  if(input=="b"){
    digitalWrite(LED_BUILTIN, HIGH);  //内臓LEDを点灯
  }else{
    digitalWrite(LED_BUILTIN, LOW);  //内臓LEDを消灯
  }
  delay(10);  //信号を確実に受信できるようにするための待ち

}
