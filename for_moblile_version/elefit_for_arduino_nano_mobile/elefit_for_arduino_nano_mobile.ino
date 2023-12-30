#include <FlexiTimer2.h>

#define PWM_PORT_M1_1 2  //DPE-100-7P-Y1 (A)
#define PWM_PORT_M2_1 3  //DPE-100-7P-Y1 (B)
#define PWM_PORT_M3_1 4  //DPE-100-7P-Y1 (C)

#define PWM_PORT_M4_1 9  //6-channel pump (R+)
#define PWM_PORT_M4_2 10  //6-channel pump (R-)

#define PWM_PORT_M5_1 11  //6-channel pump (L+)
#define PWM_PORT_M5_2 12  //6-channel pump (L-)

#define LIMIT_SWITCH  A0   //Limit switch

#define STEP_PORT_1   5  //PFL20-24Q A
#define STEP_PORT_2   6  //PFL20-24Q A'
#define STEP_PORT_3   7  //PFL20-24Q B
#define STEP_PORT_4   8  //PFL20-24Q B'

#define DELAYTIME     4 //stepermotomer sleeptime

#define ELEMENTS_NUM 3 /**< カンマ区切りデータの項目数 */

/* 12ch pump の設定 */
int PWM_RANGE     = 100; //Maximum value of generated PWM(1~100)
int FREQ          = 100; //pwm frequency (Hz)
int reverse = 0;         //12chpump reverse func
int speed1 = 100;       //12chpump(R) revsepeed
int speed2 = 100;       //12chpump(L) revsepeed

/* コマンド受信関連の変数 */
static String elements[ELEMENTS_NUM]; /*受信したコマンドをカンマで区切って格納するための配列*/
static int received_elements_num = 0; /**< 受信済み文字列の数 */
int rx_sig_count_prev = 0 ; /*信号を受信するとカウントアップ*/
int rx_sig_count = 0 ; /*信号を受信するとカウントアップ*/

/* 処理実行タイミングの制御関連の変数 */
unsigned long start_time;  // pwm_pump処理の実行開始時刻
boolean running_flag = false;   // 処理の実行管理用フラグ

/* Phase1(Washing)、各処理の実行時間（t_11~t_14）[sec] */
unsigned long t_11 = 18;
unsigned long t_12 = 45;
unsigned long t_13 = 60;  // Wait for 600 sec (test = 60 sec)
unsigned long t_14 = 30;
unsigned long t_1_error = 3; // ステッピングモータの動作などで発生する遅延
/* Phase2(Loading)、各処理の実行時間（t_21~t_26）[sec] */
unsigned long t_21 = 19;
unsigned long t_22 = 45;
unsigned long t_23 = 30;  // Wait for 300 sec (test = 30 sec)
unsigned long t_24 = 25;  // Wait for 250 sec (test = 25 sec)
unsigned long t_25 = 4;
unsigned long t_26 = 60;
unsigned long t_2_error = 0; // ステッピングモータの動作などで発生する遅延
/* Phase3(Collecting)、各処理の実行時間（t_31~t_36） [sec]*/
unsigned long t_31 = 15;
unsigned long t_32 = 45;
unsigned long t_33 = 5;
unsigned long t_34 = 60;
unsigned long t_35 = 5;
unsigned long t_36 = 100;
unsigned long t_3_error = 5; // ステッピングモータの動作などで発生する遅延
/* Phase4(Discharge)、各処理の実行時間（t_41~t_46） [sec]*/
unsigned long t_41 = 7;
unsigned long t_42 = 280;
unsigned long t_4_error = 3; // ステッピングモータの動作などで発生する遅延

/* 進捗表示のゲージ描画用 */
String excecuted_process = ""; // 実行されているプロセス名を保存
unsigned long estimated_time_total = 0; // 動作にかかる時間の合計値（命令受信後に計算）
unsigned long the_remaining_time = 0;   // 現在の残り時間（タイマー割り込みごとに更新される）
// Phase1(Washing)の所要時間合計[msec]
unsigned long washing_time_total    = (t_11 + t_12 + t_13 + t_14 + t_1_error) * 1000;
// Phase2(Loading)の所要時間合計[msec]
unsigned long loading_time_total    = (t_21 + t_22 + t_23 + t_24 + (t_25 + t_26) * 3 + t_2_error) * 1000;
// Phase3(Collecting)の所要時間合計[msec]
unsigned long collecting_time_total = (t_31 + t_32 + t_33 + t_34 + t_35 + t_36 + t_3_error) * 1000;
// Phase4(Discharge)の所要時間合計[msec]
unsigned long discharge_time_total = (t_41 + t_42 + t_4_error) * 1000;
// Phase1(Washing), Phase2(Loading), Phase3 (Collecting)が実行された時間[msec]
unsigned long washing_time = 0; // Washing の実行時間[msec]
unsigned long loading_time = 0; // Loading の実行時間[msec]
unsigned long collecting_time = 0; // Collecting の実行時間[msec]
unsigned long discharge_time = 0; // Collecting の実行時間[msec]
// Phase1(Washing), Phase2(Loading), Phase3 (Collecting)の進捗
float washing_progress = 0;
float loading_progress = 0;
float collecting_progress = 0;
float discharge_progress = 0;

/* Arduinoリセット用関数の定義 */
void(*resetFunc)(void) = 0; // Arduinoをリセットボタンでなく、プログラムからリセットするための関数

// シリアル通信でスマホからの命令を読み込む関数
void read_data() {
  /* 残り時間を計算 */
  if(excecuted_process == "washing" && elements[0] != "all_phase" && elements[0] != "lc"){
    the_remaining_time = estimated_time_total - washing_time;
    }
  else if(excecuted_process == "loading" && elements[0] != "all_phase" && elements[0] != "lc"){
    the_remaining_time = estimated_time_total - loading_time;
  }else if(excecuted_process == "collecting" && elements[0] != "all_phase" && elements[0] != "lc"){
    the_remaining_time = estimated_time_total - collecting_time;
  }else if(excecuted_process == "discharge" && elements[0] != "all_phase" && elements[0] != "lc"){
    the_remaining_time = estimated_time_total - discharge_time;
  }else if(elements[0] == "lc"){
    the_remaining_time = estimated_time_total - (loading_time + collecting_time);    
  }else{
    the_remaining_time = estimated_time_total - (washing_time + loading_time + collecting_time); //　残り時間を更新
    }
  
  if (excecuted_process == "washing" && washing_progress * 100 <= 100) { // Washingの処理を実行
    washing_time += 500; // 実行時間を加算（500[msec]はタイマー割り込みの周期）
  }
  else if (excecuted_process == "loading" && loading_progress * 100 <= 100) { // Loadingの処理を実行
    loading_time += 500; // 実行時間を加算（500[msec]はタイマー割り込みの周期）
  }
  else if (excecuted_process == "collecting" && collecting_progress * 100 <= 100) { // Collectingの処理を実行
    collecting_time += 500; // 実行時間を加算（500[msec]はタイマー割り込みの周期）
  }
  else if (excecuted_process == "discharge" && discharge_progress * 100 <= 100) { // Collectingの処理を実行
    discharge_time += 500; // 実行時間を加算（500[msec]はタイマー割り込みの周期）
  }  
  else if (excecuted_process == "close") {
    washing_time = 0; // 実行時間をリセット
    loading_time = 0; // 実行時間をリセット
    collecting_time = 0; // 実行時間をリセット
    discharge_time = 0; // 実行時間をリセット
  } else {
    the_remaining_time = 0;
  }

  /* 残り時間を表示（Arduinoシリアルモニタ用） */
//  Serial.print("The remaining time[sec]:");
//  Serial.print((int)(the_remaining_time/1000));
//  Serial.println();

  /* 進捗を計算 */
  washing_progress = (float)(washing_time) / washing_time_total;
  loading_progress = (float)(loading_time) / loading_time_total;
  collecting_progress = (float)(collecting_time) / collecting_time_total;
  discharge_progress = (float)(discharge_time) / discharge_time_total;

  /* 進捗を表示（Arduinoシリアルモニタ用）  */
//  Serial.print("Progress[%]:");
//  Serial.print("Washing,");
//  Serial.print((int)(washing_progress * 100));
//  Serial.print(",Loading,");
//  Serial.print((int)(loading_progress * 100));
//  Serial.print(",Collecting,");
//  Serial.print((int)(collecting_progress * 100));
//  Serial.println();
//  Serial.println();

  /* スマホ or PC に[動作残り時間(sec), Washingの進捗(%), Loadingの進捗(%), Collectingの進捗(%)]を送信 */
  Serial.print((int)(the_remaining_time/1000));
  Serial.print(",");
  Serial.print((int)(washing_progress * 100));
  Serial.print(",");
  Serial.print((int)(loading_progress * 100));
  Serial.print(",");  
  Serial.print((int)(collecting_progress * 100));
  Serial.print(",");  
  Serial.print((int)(discharge_progress * 100));  
//  Serial.print("");
  
  if (Serial.available()) {
    rx_sig_count++;
    String line;              // 受信文字列
    unsigned int beginIndex;  // 要素の開始位置
    //    Serial.print("rx_sig_count = ");
    //    Serial.print(rx_sig_count);
    //    Serial.print(", rx_sig_count_prev = ");
    //    Serial.print(rx_sig_count_prev);
    //    Serial.println();

    if (rx_sig_count >= rx_sig_count_prev + 2) {
      //      Serial.print("*** Please wait. Excecuting the received command ... ***\n");
      //      Serial.print("*** If you want to stop this process, Press the「CLOSE」button on your app. ***\n");
    }

    // シリアルモニタやProcessingから"AB,C,DEF,12,3,45,A1,2B,-1,+127"のように
    // ELEMENTS_NUM個の文字列の間にカンマを付けて送る
    // 送信側の改行設定は「LFのみ」にすること
    // シリアル通信で1行（改行コードまで）読み込む
    line = Serial.readStringUntil('\n');

    beginIndex = 0;
    for (received_elements_num = 0; received_elements_num < ELEMENTS_NUM; received_elements_num++) {
      // 最後の要素ではない場合
      if (received_elements_num != (ELEMENTS_NUM - 1)) {
        // 要素の開始位置から，カンマの位置を検索する
        unsigned int endIndex;
        endIndex = line.indexOf(',', beginIndex);
        // カンマが見つかった場合
        if (endIndex != -1) {
          // 文字列を切り出して配列に格納する
          elements[received_elements_num] = line.substring(beginIndex, endIndex);
          // 要素の開始位置を更新する
          beginIndex = endIndex + 1;
        }
        // カンマが見つからなかった場合はfor文を中断する
        else {
          break;
        }
      }
      // 最後の要素の場合
      else {
        elements[received_elements_num] = line.substring(beginIndex);
      }
    }

    if (elements[0] == "reset_arduino") {
      resetFunc();
    }

    Serial.end();
    Serial.begin(115200);
  }

}


void setup() {
  Serial.begin(115200);             // シリアル伝送速度を115200[bps]に設定（Bluno Nano標準）
  FlexiTimer2::set(500, read_data); // 500[ms]間隔で命令を読むようにタイマーを設定
  FlexiTimer2::start();             // タイマー開始

  /***** GPIO pin setup *****/
  pinMode(PWM_PORT_M1_1, OUTPUT);     //DPE-100-7P-Y1 (A)
  pinMode(PWM_PORT_M2_1, OUTPUT);     //DPE-100-7P-Y1 (B)
  pinMode(PWM_PORT_M3_1, OUTPUT);     //DPE-100-7P-Y1 (C)
  pinMode(PWM_PORT_M4_1, OUTPUT);     //6-channel pump (R+)
  pinMode(PWM_PORT_M4_2, OUTPUT);     //6-channel pump (R-)
  pinMode(PWM_PORT_M5_1, OUTPUT);     //6-channel pump (L+)
  pinMode(PWM_PORT_M5_2, OUTPUT);     //6-channel pump (L-)

  pinMode(STEP_PORT_1, OUTPUT);       //PFL20-24Q A
  pinMode(STEP_PORT_2, OUTPUT);       //PFL20-24Q A'
  pinMode(STEP_PORT_3, OUTPUT);       //PFL20-24Q B
  pinMode(STEP_PORT_4, OUTPUT);       //PFL20-24Q B'

  pinMode(LIMIT_SWITCH, INPUT_PULLUP); //Limit switch

  /***** GPIO initial setup *****/
  digitalWrite(PWM_PORT_M1_1, LOW);
  digitalWrite(PWM_PORT_M2_1, LOW);
  digitalWrite(PWM_PORT_M3_1, LOW);
  digitalWrite(PWM_PORT_M4_1, LOW);
  digitalWrite(PWM_PORT_M4_2, LOW);
  digitalWrite(PWM_PORT_M5_1, LOW);
  digitalWrite(PWM_PORT_M5_2, LOW);
  digitalWrite(STEP_PORT_1, LOW);
  digitalWrite(STEP_PORT_2, LOW);
  digitalWrite(STEP_PORT_3, LOW);
  digitalWrite(STEP_PORT_4, LOW);
}




void loop() {

  delay(50);

  if (rx_sig_count != rx_sig_count_prev) {
    //    Serial.print(">> Received command = ");
    //    Serial.print(elements[0]);
    //    Serial.print(",");
    //    Serial.print(elements[1]);
    //    Serial.print(",");
    //    Serial.print(elements[2]);
    //    Serial.println();
    if (elements[0] == "step_front") { // ステッピングモータを駆動してカラムを前方に動かす
      step_front(elements[1].toInt());
    }
    else if (elements[0] == "step_back") { // ステッピングモータを駆動してカラムを後方に動かす
      step_back(elements[1].toInt());
    }
    else if (elements[0] == "on_pump_12ch") { // 6chポンプ×2を駆動
      on_pump_12ch(elements[1].toInt(), elements[2].toInt());
    }
    //    else if (elements[0] == "pwm_pump_12ch") { // 6ch×2のポンプをわずかに正転させ、停止する
    //      pwm_pump_12ch();
    //    }
    else if (elements[0] == "off_pump_12ch") { // 6chポンプ×2を停止
      off_pump_12ch();
    }
    else if (elements[0] == "on_pump_dba") { // ダイヤフラムポンプを駆動
      on_pump_dba(elements[1].toInt());
    }
    else if (elements[0] == "off_pump_dba") { // ダイヤフラムポンプを停止
      off_pump_dba();
    }
    else if (elements[0] == "washing") { // Washingの処理を実行
      estimated_time_total = washing_time_total; // 合計の所要時間を計算
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      washing();
    }
    else if (elements[0] == "loading") { // Loadingの処理を実行
      estimated_time_total = loading_time_total;
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      loading();
    }
    else if (elements[0] == "collecting") { // Collectingの処理を実行
      estimated_time_total = collecting_time_total;
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      collecting();
    }
    else if (elements[0] == "discharge") { // dischargeの処理を実行
      estimated_time_total = discharge_time_total;
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      discharge();      
    }
    else if (elements[0] == "all_phase") { // All phase（Washing→Loading→Collecting）の処理を実行
      estimated_time_total = washing_time_total + loading_time_total + collecting_time_total;
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      all_phase();
    }
    else if (elements[0] == "lc") { // Loading→Collectingの処理を実行
      estimated_time_total = loading_time_total + collecting_time_total;
      the_remaining_time = estimated_time_total; // 合計の所要時間を保存（進捗表示のため）
      loading_collecting();
    }    
    
    rx_sig_count_prev = rx_sig_count; // 信号を1回受信したら更新（これで次の命令を受信するまで動作を実行しない）
    //    Serial.print("rx_sig_count = ");
    //    Serial.print(rx_sig_count);
    //    Serial.print(", rx_sig_count_prev = ");
    //    Serial.print(rx_sig_count_prev);
    //    Serial.print("\n--> Excecuted the received command\n");
    //    Serial.println();
  }
}

/* ステッピングモータを駆動してカラムを前方に動かす関数 */
void step_front(int step) {
  digitalWrite(STEP_PORT_2, HIGH);
  digitalWrite(STEP_PORT_4, HIGH);

  for (int i = 0; i < step; i++) {
    digitalWrite(STEP_PORT_1, HIGH);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_3, HIGH);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_1, LOW);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_3, LOW);
    delay(DELAYTIME);
  }
  digitalWrite(STEP_PORT_2, LOW);
  digitalWrite(STEP_PORT_4, LOW);
}
/* ステッピングモータを駆動してカラムを後方に動かす関数 */
void step_back(int step) {
  digitalWrite(STEP_PORT_2, HIGH);
  digitalWrite(STEP_PORT_4, HIGH);

  for (int i = 0; i < step; i++) {

    if (digitalRead(LIMIT_SWITCH) == HIGH) {
      break;
    }
    digitalWrite(STEP_PORT_3, HIGH);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_1, HIGH);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_3, LOW);
    delay(DELAYTIME);
    digitalWrite(STEP_PORT_1, LOW);
    delay(DELAYTIME);
  }
  digitalWrite(STEP_PORT_2, LOW);
  digitalWrite(STEP_PORT_4, LOW);
}

void on_pump_dba(int pump_id) {
  if (pump_id == 1) {
    digitalWrite(PWM_PORT_M1_1, HIGH);
  }
  else if (pump_id == 2) {
    digitalWrite(PWM_PORT_M2_1, HIGH);
  }
  else if (pump_id == 3) {
    digitalWrite(PWM_PORT_M3_1, HIGH);
  }
}

void off_pump_dba() {
  digitalWrite(PWM_PORT_M1_1, LOW);
  digitalWrite(PWM_PORT_M2_1, LOW);
  digitalWrite(PWM_PORT_M3_1, LOW);
}

/* 6ch×2のポンプ正転・逆転する関数 */
void on_pump_12ch(int speed, bool rev) {
  if (rev == 0) {
    analogWrite(PWM_PORT_M4_1, speed1 * 2.55);
    analogWrite(PWM_PORT_M5_2, speed2 * 2.55);
  }
  else if (rev == 1) {
    analogWrite(PWM_PORT_M4_2, speed1 * 2.55);
    analogWrite(PWM_PORT_M5_1, speed2 * 2.55);

  }
}
/* 6ch×2のポンプ停止する関数 */
void off_pump_12ch() {
  digitalWrite(PWM_PORT_M4_1, LOW);
  digitalWrite(PWM_PORT_M4_2, LOW);
  digitalWrite(PWM_PORT_M5_1, LOW);
  digitalWrite(PWM_PORT_M5_2, LOW);
}
/* 6ch×2のポンプをわずかに正転させ、停止する関数 */
void pwm_pump_12ch(unsigned long running_time) {
  unsigned long curr; // 現在時刻の保存用変数
  // 指定した実行時間（running_time）の間処理を繰り返す
  do {
    curr = millis();
    on_pump_12ch(80, 0);
    delay(385);
    off_pump_12ch();
    delay(625);
  } while (curr - start_time <= running_time);
}

/* Phase1（Washing） */
void washing() {
  excecuted_process = "washing" ;
  step_front(50);
  step_back(200);
  /* 1-1 */
  on_pump_dba(1);
  delay(t_11 * 1000); // Wait for 18 sec
  off_pump_dba();
  /* 1-2 */
  on_pump_12ch(100, 0);
  delay(t_12 * 1000); // Wait for 45 sec
  off_pump_12ch();
  /* 1-3 */
  start_time = millis(); // pwm_pump_12chの実行開始時刻を保存
  pwm_pump_12ch(t_13 * 1000); // Wait for 600 sec (test = 60 sec)
  /* 1-4 */
  on_pump_12ch(100, 0);
  delay(t_14 * 1000); // Wait for 30 sec
  off_pump_12ch();
}

/* Phase2（Loading） */
void loading() {
  excecuted_process = "loading" ;
  /* 2-1 */
  on_pump_dba(2);
  delay(t_21 * 1000); // Wait for 19 sec
  off_pump_dba();
  /* 2-2 */
  on_pump_12ch(100, 0);
  delay(t_22 * 1000); // Wait for 45 sec
  off_pump_12ch();
  /* 2-3 */
  delay(t_23 * 1000); // Wait for 300 sec (test = 30 sec)
  /* 2-4 */
  on_pump_12ch(100, 0);
  delay(t_24 * 1000); // Wait for 250 sec (test = 25 sec)
  off_pump_12ch();
  /* 2-5-1 */
  on_pump_dba(3);
  delay(t_25 * 1000); // Wait for 4 sec
  off_pump_dba();
  /* 2-6-1 */
  on_pump_12ch(100, 0);
  delay(t_26 * 1000); // Wait for 60 sec
  off_pump_12ch();
  /* 2-5-2 */
  on_pump_dba(3);
  delay(t_25 * 1000); // Wait for 4 sec
  off_pump_dba();
  /* 2-6-2 */
  on_pump_12ch(100, 0);
  delay(t_26 * 1000); // Wait for 60 sec
  off_pump_12ch();
  /* 2-5-3 */
  on_pump_dba(3);
  delay(t_25 * 1000); // Wait for 4 sec
  off_pump_dba();
  /* 2-6-3 */
  on_pump_12ch(100, 0);
  delay(t_26 * 1000); // Wait for 60 sec
  off_pump_12ch();
}

/* Phase3（Collecting） */
void collecting() {
  excecuted_process = "collecting" ;
  /* 3-1 */
  on_pump_dba(3);
  delay(t_31 * 1000); // Wait for 15 sec
  off_pump_dba();
  /* 3-2 */
  on_pump_12ch(100, 0);
  delay(t_32 * 1000); // Wait for 45 sec
  off_pump_12ch();
  /* 3-3 */
  on_pump_12ch(100, 1);
  delay(t_33 * 1000); // Wait for 5 sec
  off_pump_12ch();
  /* 3-4 */
  step_front(160);
  on_pump_12ch(100, 0);
  delay(t_34 * 1000); // Wait for 60 sec
  off_pump_12ch();
  /* 3-5 */
  on_pump_12ch(100, 1);
  delay(t_35 * 1000); // Wait for 5 sec
  off_pump_12ch();
  /* 3-6 */
  step_back(180);
  on_pump_12ch(100, 0);
  delay(t_36 * 1000); // Wait for 100 sec
  off_pump_12ch();
}

/* Phase4（Discharge） */
void discharge() {
  excecuted_process = "discharge" ;
  step_front(50);
  step_back(200);
  /* 4-1 */
  on_pump_dba(1);
  on_pump_dba(2);
  on_pump_dba(3);
  delay(t_41 * 1000); // Wait for 7 sec
  off_pump_dba();
  /* 4-2 */
  on_pump_12ch(100, 0);
  delay(t_42 * 1000); // Wait for 280 sec
  off_pump_12ch();
}

void all_phase() {
  washing();
  loading();
  collecting();
}

void loading_collecting() {
  loading();
  collecting();
}
