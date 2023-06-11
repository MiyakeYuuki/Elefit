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

int PWM_RANGE     = 100; //Maximum value of generated PWM(1~100)
int FREQ          = 100; //pwm frequency (Hz)
int reverse = 0;         //12chpump reverse func
int speed   = 100;       //12chpump revsepeed

static String elements[ELEMENTS_NUM];
static int received_elements_num = 0; /**< 受信済み文字列の数 */

void setup() {
  Serial.begin(9600);
  /***** GPIO pin setup *****/
  pinMode(PWM_PORT_M1_1, OUTPUT);     //DPE-100-7P-Y1 (A)
  pinMode(PWM_PORT_M2_1, OUTPUT);     //DPE-100-7P-Y1 (B)
  pinMode(PWM_PORT_M3_1, OUTPUT);     //DPE-100-7P-Y1 (C)
  pinMode(PWM_PORT_M4_1, OUTPUT);     //6-channel pump (R+)
  pinMode(PWM_PORT_M4_2, OUTPUT);     //6-channel pump (R-)
  pinMode(PWM_PORT_M5_1, OUTPUT);     //6-channel pump (L+)
  pinMode(PWM_PORT_M5_2, OUTPUT);     //6-channel pump (L-)

  pinMode(STEP_PORT_1,OUTPUT);        //PFL20-24Q A
  pinMode(STEP_PORT_2,OUTPUT);        //PFL20-24Q A'
  pinMode(STEP_PORT_3,OUTPUT);        //PFL20-24Q B
  pinMode(STEP_PORT_4,OUTPUT);        //PFL20-24Q B'

  pinMode(LIMIT_SWITCH,INPUT_PULLUP); //Limit switch

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


void(*resetFunc)(void) = 0;

void loop() {
  if (Serial.available()) {
    String line;              // 受信文字列
    unsigned int beginIndex;  // 要素の開始位置

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
    if(elements[0] == "step_front"){
      Serial.println(elements[0]);
      step_front(elements[1].toInt());
    }
    else if(elements[0] == "step_back"){
      Serial.println(elements[0]);
      step_back(elements[1].toInt());   
    }
    else if(elements[0] == "on_pump_12ch"){
      Serial.println(elements[0]);
      Serial.println(elements[1]);
      Serial.println(elements[2]);
      on_pump_12ch(elements[1].toInt(),elements[2].toInt()); 
    }
    else if(elements[0] == "pwm_pump_12ch"){
      Serial.println(elements[0]);
      pwm_pump_12ch(); 
    }
    else if(elements[0] == "off_pump_12ch"){
      Serial.println(elements[0]);
      off_pump_12ch(); 
    }
    else if(elements[0] == "on_pump_dba"){
      Serial.println(elements[0]);
      if(elements[1].toInt() == 1){
        digitalWrite(PWM_PORT_M1_1, HIGH);
      }
      else if(elements[1].toInt() == 2){
        digitalWrite(PWM_PORT_M2_1, HIGH);
      }
      else if(elements[1].toInt() == 3){
        digitalWrite(PWM_PORT_M3_1, HIGH);
      }
    }
    else if(elements[0] == "off_pump_dba"){
      Serial.println(elements[0]);
      digitalWrite(PWM_PORT_M1_1, LOW);
      digitalWrite(PWM_PORT_M2_1, LOW);
      digitalWrite(PWM_PORT_M3_1, LOW);
    }else if(elements[0] == "reset_arduino"){
      Serial.println(elements[0]);
      delay(100);
      resetFunc();
    }
    elements[0] == "\0";    // 文字列の初期化
  }
}

int step_front(int step){
  digitalWrite(STEP_PORT_2, HIGH);
  digitalWrite(STEP_PORT_4, HIGH);

  for(int i=0; i < step; i++){
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

int step_back(int step){
  digitalWrite(STEP_PORT_2, HIGH);
  digitalWrite(STEP_PORT_4, HIGH);

  for(int i=0; i < step; i++){

    if(digitalRead(LIMIT_SWITCH) == HIGH){
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

int on_pump_12ch(int speed,bool rev){
  if(rev == 0){
    analogWrite(PWM_PORT_M4_1, speed * 2.55);
    analogWrite(PWM_PORT_M5_2, speed * 2.55);
  }
  else if(rev == 1){
    analogWrite(PWM_PORT_M4_2, speed * 2.55);
    analogWrite(PWM_PORT_M5_1, speed * 2.55);
    
  }
}

void off_pump_12ch(){
  digitalWrite(PWM_PORT_M4_1, LOW);
  digitalWrite(PWM_PORT_M4_2, LOW);
  digitalWrite(PWM_PORT_M5_1, LOW);
  digitalWrite(PWM_PORT_M5_2, LOW);
}

void pwm_pump_12ch(){
  on_pump_12ch(80,0);
  delay(385);
  off_pump_12ch();
  delay(625);
}
