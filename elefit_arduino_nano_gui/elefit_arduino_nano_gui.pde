import controlP5.*;  //GUI package for processing
import processing.serial.*; //Package for Serial communication between an Arduino

long temp_Correct = 0;
final long need_washing_time = 765;
int need_loading_time;
final long need_collecting_time = 434;
final long need_discharge_time = 300;
long start_washing_time = 10000000;
long start_loading_time = 10000000;
long start_collecting_time = 10000000;
long start_allphase_time = 10000000;
long start_loadingcollecting_time =  10000000;
long start_discharge_time =  10000000;
long remaining_time = 0;
int slp = 300;               //Time of Soak in Nitric
boolean pump_12ch;  //6ch*2 pump
boolean reverse;
boolean pump_1;     //Diaphragm pump*3
boolean pump_2;
boolean pump_3;
boolean process_toggle_flag;  //Flag for toggle switch on display
boolean process_button_flag;

int reverse_checkbox;

//Inductance of threads
Com_Washing Washing_exe= null;
Com_Loading Loading_exe= null;
Com_Collecting Collecting_exe = null;
Com_AllPhase AllPhase_exe = null;
Com_LoadingCollecting LoadingCollecting_exe = null;
Com_Discharge Discharge_exe = null;

Serial port;
 
ControlP5 cp5;
 
void setup() {
 
  //size(800, 450);  // W:H = 16:9
  //size(1120, 630);  // W:H = 16:9
  /*Display settings*/
  size(1600, 900);  // W:H = 16:9
  int font_size = width/56;
  cp5 = new ControlP5(this);
  PFont myFont = createFont("Arial",font_size,true);
  ControlFont cf1 = new ControlFont(myFont,font_size);
  
  /* Serial port settings */
  String[] comPort = port.list();
  int num = comPort.length;
  println("Test serial port.");
  for (int i=0; i<num; i++) {
    print(comPort[i]+"     ");
    try {
      port = new Serial(this, comPort[i], 9600);
      println("O.K");
    }
    catch(Exception e) {
      println("failed");
      continue;
    }
  }
  
  /* Button settings */
  cp5 = new ControlP5(this);
  //port = new Serial(this, "COM7", 9600);
  int button_width = width/6;
  int button_height = height/10;
  
  cp5.addButton("Washing")
    .setPosition(button_width/6, height-5*button_height/2)
    .setSize(button_width, button_height)      
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;  
    
  cp5.addButton("Loading")    
    .setPosition(4*button_width/3, height-5*button_height/2)
    .setSize(button_width, button_height)      
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
 
  cp5.addButton("Collecting")  
    .setPosition(5*button_width/2, height-5*button_height/2)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0)) 
    .setFont(cf1) ;
 
  cp5.addButton("AllPhase")  
    .setPosition(11*button_width/3, height-5*button_height/2)  
    .setSize(button_width, button_height)  
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setCaptionLabel("All Phase")
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
 
  cp5.addButton("LoadingCollecting")
    .setPosition(29*button_width/6, height-5*button_height/2)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setCaptionLabel("Loading\nCollecting")
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Front")
    .setPosition(button_width/6, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Back")
    .setPosition(4*button_width/3, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Discharge")
    .setPosition(5*button_width/2, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Close")
    .setPosition(11*button_width/3, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(0)) 
    .setFont(cf1);
  
  cp5.addSlider("need_loading_time")
    .setPosition(11*button_width/3, height-20*button_height/4)
    .setSize(2*button_width, button_height/2)
    .setSliderMode(Slider.FLEXIBLE)
    .setRange(1, 330)
    .setValue(180) 
    .setFont(cf1)
    .setCaptionLabel("Loading Time[sec]") ;
    
  cp5.getController("need_loading_time")
    .getCaptionLabel()
    .setVisible(true) 
    .toUpperCase(false)
    .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE) ;
  
  cp5.addToggle("pump_12ch")
    .setPosition(button_width/6, 5 * button_height)
    .setSize(button_height/3, button_height/3) 
    .setFont(cf1)
    .setValue(false);
  
  cp5.addToggle("reverse")
    .setPosition(4*button_width/3, 5 * button_height)
    .setSize(button_height*4/3, button_height/3) 
    .setFont(cf1)
    .setMode(ControlP5.SWITCH)
    .setValue(false);
  
  cp5.addToggle("pump_1")
    .setPosition(button_width/6, 6 * button_height)
    .setSize(button_height/3, button_height/3) 
    .setFont(cf1)
    .setValue(false) ;
  
  cp5.addToggle("pump_2")
    .setPosition(4*button_width/3, 6 * button_height)
    .setSize(button_height/3, button_height/3) 
    .setFont(cf1) 
    .setValue(false) ;
    
  cp5.addToggle("pump_3")
    .setPosition(5*button_width/2, 6 * button_height)
    .setSize(button_height/3, button_height/3) 
    .setFont(cf1) 
    .setValue(false) ;
}

/* Function for drawing gauge */
void draw_gauge(int percentage, float y, String name) {
  int x = width/5;
  int font_size = width/56;
  
  int gauge_width = 3*width/5;
  int gauge_height = height/16;
  
  //ゲージの下地描画
  fill(255);              //色指定
  rect(x, y, gauge_width, gauge_height);        //ゲージの下地描画
  
  fill(0);            //色指定
  //横軸表示
  textSize(1.5*font_size);              //テキストサイズ
  text(name, x/4, y+gauge_height-10);  // name
  textSize(font_size);
  textAlign(CENTER);          //中央揃え
  text(  0, x, y+3*gauge_height/2);   //0
  text(50, x+gauge_width/2, y+3*gauge_height/2);   //50
  text(100, x+gauge_width, y+3*gauge_height/2);   //100
  //ゲージ表示
  fill(0,128,0);              //色指定 
  rect(x, y, percentage*gauge_width/100, gauge_height); //横棒描画
  fill(color(0, 128, 0));        //色指定         
  //パーセンテージ表示  
  textSize(1.5*font_size);                  //テキストサイズ
  textAlign(RIGHT);              //右揃え
  text(percentage, 3*x/2+gauge_width, y+gauge_height);  
  //%表示
  textSize(font_size);                  //テキストサイズ
  textAlign(LEFT);               //左揃え
  text("%", 3*x/2+gauge_width, y+gauge_height);         
}

// Function to draw all gauge, control pump
void draw() {    
  int font_size = width/56;
  background(200);
  long temp;
  long washing_time = (long)max(0, (millis()/1000)-start_washing_time);
  long loading_time = (long)max(0, (millis()/1000)-start_loading_time);
  long collecting_time = (long)max(0, (millis()/1000)-start_collecting_time);
  long discharge_time = (long)max(0, (millis()/1000)-start_discharge_time);
  draw_gauge((int)(min(100, 100*washing_time/need_washing_time)), height/36, "Washing");
  draw_gauge((int)(min(100, 100*loading_time/(need_loading_time+322))), 5*height/36, "Loading");
  draw_gauge((int)(min(100, 100*collecting_time/need_collecting_time)), 9*height/36, "Collecting");
  draw_gauge((int)(min(100, 100*discharge_time/need_discharge_time)), 13*height/36, "Discharge");
  // 残り時間表示
  fill(color(0));
  textSize(1.5*font_size);                  //テキストサイズ
  text("The Remaining Time", 2*width/3, 9*height/14);
  
  temp = remaining_time;
  temp -= (long)(min(need_washing_time, washing_time));
  temp -= (long)(min(need_loading_time + 322, loading_time));
  temp -= (long)(min(need_collecting_time, collecting_time));
  temp -= (long)(min(need_discharge_time, discharge_time));
  if(process_button_flag == true){
    temp += temp_Correct;
  }else{
    temp = 0;
  }
  
  int minutes = (int)(temp/60);
  int seconds = (int)(temp%60);
  text(minutes, 11*width/16, 14*height/20);
  text("min", 11*width/16 + width/40, 14*height/20);
  text(seconds, 11*width/16 + width/10, 14*height/20);
  text("sec", 11*width/16 + width/7.5, 14*height/20);


  
  if(process_toggle_flag == false){
    process_toggle_flag = true;
    if(pump_1 == true) {
      port.write("on_pump_dba,1,0\n");
    }else if(pump_2 == true){
      port.write("on_pump_dba,2,0\n");
    }else if(pump_3 == true){
      port.write("on_pump_dba,3,0\n");
    }else if(pump_12ch == true && reverse == false){
      port.write("on_pump_12ch,100,0\n");
    }else if(pump_12ch == true && reverse == true){
      port.write("on_pump_12ch,100,1\n");
    }else{
      port.write("off_pump_dba,0,0\n");
      port.write("off_pump_12ch,0,0\n");
    }
  }
  
  if(pump_12ch == false && pump_1 == false && pump_2 == false && pump_3 == false && process_button_flag == false && process_button_flag == false){
    process_toggle_flag = false;
    process_button_flag = false;
  }

}

/*「WASHING」ボタンが押されたときに実行される関数 */
void Washing() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_washing_time;
    //Generating Threads
    Washing_exe = new Com_Washing();
    //Execution start
    Washing_exe.start();
  }
}
/*「LOADING」ボタンが押されたときに実行される関数 */
void Loading() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_loading_time + 322;
    //Generating Threads
    Loading_exe = new Com_Loading();
    //Execution start
    Loading_exe.start();
  }
}

/*「COLLECTING」ボタンが押されたときに実行される関数 */
void Collecting() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_collecting_time;
    //Generating Threads
    Collecting_exe = new Com_Collecting();
    //Execution start
    Collecting_exe.start();
  }
}
 
/*「ALL PHASE」ボタンが押されたときに実行される関数 */
void AllPhase() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_washing_time + (need_loading_time+322) + need_collecting_time;
    start_washing_time = (long)millis()/1000;
    start_loading_time = (long)millis()/1000 + need_washing_time;
    start_collecting_time = (long)millis()/1000 + need_washing_time + (need_loading_time+322);
    //Generating Threads
    AllPhase_exe = new Com_AllPhase();
    //Execution start
    AllPhase_exe.start();
  }
}
/*「LOADING COLLECTING」ボタンが押されたときに実行される関数 */
void LoadingCollecting() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_loading_time + 322 + need_collecting_time;
    start_loading_time = (long)millis()/1000;
    start_collecting_time = (long)millis()/1000 + (need_loading_time+322);
    //Generating Threads
    LoadingCollecting_exe = new Com_LoadingCollecting();
    //Execution start
    LoadingCollecting_exe.start();
  }
}


/*「FRONT」ボタンが押されたときに実行される関数 */
void Front() {
  if(process_toggle_flag == false && process_button_flag == false){
    port.write("step_front,10,0\n");
  }
}
/*「BACK」ボタンが押されたときに実行される関数 */
void Back() {
  if(process_toggle_flag == false && process_button_flag == false){
    port.write("step_back,10,0\n");
  }
}
/*「DISCHARGE」ボタンが押されたときに実行される関数 */
void Discharge() {
  if(process_toggle_flag == false && process_button_flag == false){
    remaining_time = need_discharge_time;
    
    //Generating Threads
    Discharge_exe = new Com_Discharge();
    //Execution start
    Discharge_exe.start();
  }
}
/*「CLOSE」ボタンが押されたときに実行される関数 */
void Close() {
  start_washing_time = 10000000;
  start_loading_time = 10000000;
  start_collecting_time = 10000000;
  start_discharge_time = 10000000;
  remaining_time = 0;
  temp_Correct = 0;
  port.write("off_pump_12ch,0,0\n");
  port.write("off_pump_dba,0,0\n");
  port.write("reset_arduino,0,0\n");
  
  Washing_exe.stopRunning();
  Loading_exe.stopRunning();
  Collecting_exe.stopRunning();
  Discharge_exe.stopRunning();
  
}

//------------------------
// All washing process（ここからサブスレッド）
//------------------------
class Com_Washing extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    port.write("step_front,50,0\n");        //Stepping motor moves forward 50 steps
    delay(1000);                            
    port.write("step_back,200,0\n");        //Stepping motor moves backward 200 steps
    delay(1000);
    
    //PaseTime[sec]
    int wash_phase1 = 20;
    int wash_phase2 = 42;
    int wash_phase3 = 600;
    int wash_phase4 = 100;
    
    start_washing_time = (long)millis()/1000;
    while(running){
      if(0 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1){           //PumpA activation for 20 sec(0～20sec). Phase1
          port.write("on_pump_dba,1,0\n");      //PumpA activation
          delay(1000); 
      }else if(wash_phase1 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1 + 1){    //Stop PumpA(20～21sec)
          port.write("off_pump_dba,0,0\n");       //Stop PumpA
          delay(200); 
      }else if(wash_phase1 + 1 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1 + wash_phase2 + 1){    //12ch_Pump activation for 42 sec(21～63sec). Phase2
          port.write("on_pump_12ch,100,0\n");     //12ch_Pump activation
          delay(1000);
      }else if(wash_phase1 + wash_phase2 + 1 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1 + wash_phase2 + 2){    //Stop 12ch_Pump(63～64sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200);
      }else if(wash_phase1 + wash_phase2 + 2 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1 + wash_phase2 + wash_phase3 + 2){   //12ch_Pump activation for 600 sec(64～664sec), Phase3
          port.write("pwm_pump_12ch,0,0\n");     //12ch_Pump activation
          delay(1000);
      }else if(wash_phase1 + wash_phase2 + wash_phase3 + 2 <= ((millis()/1000)-start_washing_time) && ((millis()/1000)-start_washing_time) < wash_phase1 + wash_phase2 + wash_phase3 + wash_phase4 + 2){  //12ch_Pump activation for 100 sec(664～764sec). Phase4
          port.write("on_pump_12ch,100,0\n");     //12ch_Pump activation
          delay(1000);
      }else{
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          process_button_flag = false;
          temp_Correct += need_washing_time;
          break;
      }
    }
  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }
}

//------------------------
// All loading process
//------------------------

class Com_Loading extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    slp = need_loading_time;
    start_loading_time = (long)millis()/1000;
    
    //PaseTime[sec]
    int load_Phase1 = 18;
    int load_Phase2 = 53;
    int load_Phase3 = slp;
    int load_Phase4 = 250;
    
    while(running){
      if(0 <= ((millis()/1000)-start_loading_time) && ((millis()/1000)-start_loading_time) < load_Phase1){                  //PumpB activation for 18 sec(0～18sec). Phase1
          port.write("on_pump_dba,2,0\n");       //PumpB activation
          delay(1000); 
      }else if(load_Phase1 <= ((millis()/1000)-start_loading_time) && ((millis()/1000)-start_loading_time) < load_Phase1 + 1){           //Stop PumpB(18～19sec)
          port.write("off_pump_dba,0,0\n");      //Stop PumpB
          delay(200); 
      }else if(load_Phase1 + 1 <= ((millis()/1000)-start_loading_time) && ((millis()/1000)-start_loading_time) < load_Phase1 + load_Phase2 + 1){           //12ch_Pump activation for 53 sec(19～72sec). Phase2
          port.write("on_pump_12ch,100,0\n");    //12ch_Pump activation
          delay(1000); 
      }else if(load_Phase1 + load_Phase2 + 1 <= ((millis()/1000)-start_loading_time) && ((millis()/1000)-start_loading_time) < load_Phase1 + load_Phase2 + load_Phase3 + 1){       //Stop 12ch_Pump. Standby for slp [sec](72～ 72+slp [sec]). Phase3
          port.write("off_pump_12ch,0,0\n");     //Stop 12ch_Pump
          delay(1000); 
      }else if(load_Phase1 + load_Phase2 + load_Phase3 + 1 <= ((millis()/1000)-start_loading_time) && ((millis()/1000)-start_loading_time) < load_Phase1 + load_Phase2 + load_Phase3 + load_Phase4 + 1){  //12ch_Pump activation for 250 sec(72+slp ～ 322+slp [sec]). Phase4
          port.write("on_pump_12ch,100,0\n");    //12ch_Pump activation
          delay(1000); 
      }else{
          port.write("off_pump_12ch,0,0\n");     //Stop 12ch_Pump
          process_button_flag = false;
          temp_Correct += need_loading_time + 322;
          break;
      }
      
    }
  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }  
}


//------------------------
// All collecting process
//------------------------
class Com_Collecting extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    start_collecting_time = (long)millis()/1000;
    //PaseTime[sec]
    int coll_Pase1 = 18;
    int coll_Pase2 = 55;
    int coll_Pase3 = 5;
    int coll_Pase4 = 86;
    int coll_Pase5 = 5;
    int coll_Pase6 = 250;
    
    while(running){
      if(0 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1){                  //PumpC activation for 18 sec(0～18sec). Phase1
          port.write("on_pump_dba,3,0\n");       //PumpC activation
          delay(1000); 
      }else if(coll_Pase1 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + 1){            //Stop PumpC(18～19sec)
          port.write("off_pump_dba,0,0\n");       //Stop PumpC
          delay(200); 
      }else if(coll_Pase1 + 1 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + coll_Pase2 + 1){            //12ch_Pump activation for 55 sec(19～74sec). Phase2
          port.write("on_pump_12ch,100,0\n");     //12ch_Pump activation
          delay(1000); 
      }else if(coll_Pase1 + coll_Pase2 + 1 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + coll_Pase2 + 2){            //Stop 12ch_Pump(74～75sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200); 
      }else if(coll_Pase1 + coll_Pase2 + 2 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + coll_Pase2 + coll_Pase3 + 2){            //12ch_Pump reverse activation for 5 sec(75～80sec). Phase3
          port.write("on_pump_12ch,100,1\n");     //12ch_Pump reverse activation
          delay(1000); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + 2 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + coll_Pase2 + coll_Pase3 + 3){            //Stop 12ch_Pump(80～81sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + 3 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) < coll_Pase1 + coll_Pase2 + coll_Pase3 + 8){            //Stepping motor moves forward 160 steps(81～86sec)
          port.write("step_front,160,0\n");       //Stepping motor moves forward 160 steps
          delay(5100); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + 8 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + 8){            //12ch_Pump activation for 86 sec(86～172sec). Phase4
          port.write("on_pump_12ch,80,0\n");      //12ch_Pump activation
          delay(1000); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + 8 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + 9){           //Stop 12ch_Pump(172～173sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + 9 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 9){           //12ch_Pump reverse activation for 5 sec(173～178sec). Phase5
          port.write("on_pump_12ch,100,1\n");     //12ch_Pump reverse activation
          delay(1000); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 9 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 10){           //Stop 12ch_Pump(178～179sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 10 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 15){           //Stepping motor moves backward 180 steps(179～184sec)
          port.write("step_back,180,0\n");        //Stepping motor moves backward 180 steps
          delay(5100); 
      }else if(coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + 15 <= ((millis()/1000)-start_collecting_time) && ((millis()/1000)-start_collecting_time) <coll_Pase1 + coll_Pase2 + coll_Pase3 + coll_Pase4 + coll_Pase5 + coll_Pase6 + 15){           //12ch_Pump reverse activation for 250 sec(184～434sec). Phase6
          port.write("on_pump_12ch,100,1\n");     //12ch_Pump reverse activation
          delay(1000); 
      }else{
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          temp_Correct += need_collecting_time;
          process_button_flag = false;
          break;
      }
      
    }

  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }  
}

//------------------------
// All process(phase)
//------------------------
class Com_AllPhase extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    boolean washing_flag = false;
    boolean loading_flag = false;
    boolean collecting_flag = false;
    
    start_allphase_time = (long)millis()/1000;
    washing_flag = false;
    loading_flag = false;
    collecting_flag = false;
    while(running == true){
      if( ((millis()/1000)-start_allphase_time) < need_washing_time && washing_flag == false){
        washing_flag = true;
        //Generating Threads
        Washing_exe = new Com_Washing();
        //Execution start
        Washing_exe.start();
      }else if( need_washing_time <= ((millis()/1000)-start_allphase_time) && ((millis()/1000)-start_allphase_time) < (need_washing_time + need_loading_time + 322) && loading_flag == false){
        Washing_exe.stopRunning();
        loading_flag = true;
        //Generating Threads
        Loading_exe = new Com_Loading();
        //Execution start
        Loading_exe.start();
      }else if( (need_washing_time + need_loading_time + 322) <= ((millis()/1000)-start_allphase_time) 
                && ((millis()/1000)-start_allphase_time) < (need_washing_time + need_loading_time + 322 + need_collecting_time) 
                && collecting_flag == false){
        Loading_exe.stopRunning();
        collecting_flag = true;
        //Generating Threads
        Collecting_exe = new Com_Collecting();
        //Execution start
        Collecting_exe.start();
      }else if(((millis()/1000)-start_allphase_time) >= (need_washing_time + need_loading_time + 322 + need_collecting_time)){
        Collecting_exe.stopRunning();
        process_button_flag = false;
        break;
      }

    }
  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }  
}

class Com_LoadingCollecting extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    boolean loading_flag = false;
    boolean collecting_flag = false;
    
    start_loadingcollecting_time = (long)millis()/1000;
    while(running == true){
      if(((millis()/1000)-start_loadingcollecting_time) < (need_loading_time + 322) && loading_flag == false){
        loading_flag = true;
        //Generating Threads
        Loading_exe = new Com_Loading();
        //Execution start
        Loading_exe.start();
      }else if( (need_loading_time + 322) <= ((millis()/1000)-start_loadingcollecting_time) 
                && ((millis()/1000)-start_loadingcollecting_time) < (need_loading_time + 322 + need_collecting_time) 
                && collecting_flag == false){
        Loading_exe.stopRunning();
        collecting_flag = true;
        //Generating Threads
        Collecting_exe = new Com_Collecting();
        //Execution start
        Collecting_exe.start();
      }else if(((millis()/1000)-start_loadingcollecting_time) > (need_loading_time + 322 + need_collecting_time)){
        Collecting_exe.stopRunning();
        process_button_flag = false;
        break; 
      }

    }
  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }  
}

class Com_Discharge extends Thread {
  // 実行許可FLG
  private boolean running = true;
  
  @Override
  public void run(){
    process_button_flag = true;
    
    //PaseTime[sec]
    int dis_Pase1 = 100;
    int dis_Pase2 = 100;
    int dis_Pase3 = 100;
    
    //process_button_flag = true;
    start_discharge_time = (long)millis()/1000;
    while(running == true){
      if(0 <= ((millis()/1000)-start_discharge_time) && ((millis()/1000)-start_discharge_time) < dis_Pase1){                  //PumpA,B,C activation for  sec(0～sec). Phase1
          port.write("on_pump_dba,1,0\n");      //PumpA activation
          port.write("on_pump_dba,2,0\n");      //PumpB activation
          port.write("on_pump_dba,3,0\n");      //PumpC activation
          delay(1000); 
      }else if(dis_Pase1 <= ((millis()/1000)-start_discharge_time) && ((millis()/1000)-start_discharge_time) < dis_Pase1 + 1){            //Stop PumpA,B,C(～sec)
          port.write("off_pump_dba,0,0\n");       //Stop PumpA,B,C
          delay(200); 
      }else if(dis_Pase1 + 1 <= ((millis()/1000)-start_discharge_time) && ((millis()/1000)-start_discharge_time) < dis_Pase1 + dis_Pase2 + 1){            //12ch_Pump activation for  sec(～sec). Phase2
          port.write("on_pump_12ch,100,0\n");     //12ch_Pump activation
          delay(1000);
      }else if(dis_Pase1 + dis_Pase2 + 1 <= ((millis()/1000)-start_discharge_time) && ((millis()/1000)-start_discharge_time) < dis_Pase1 + dis_Pase2 + 2){            //Stop 12ch_Pump(～sec)
          port.write("off_pump_12ch,0,0\n");      //Stop 12ch_Pump
          delay(200);
      }else if(dis_Pase1 + dis_Pase2 + 2 <= ((millis()/1000)-start_discharge_time) && ((millis()/1000)-start_discharge_time) < dis_Pase1 + dis_Pase2 + dis_Pase3 + 2){            //12ch_Pump activation for  sec(～sec). Phase3
          port.write("pwm_pump_12ch,0,0\n");     //12ch_Pump activation
          delay(1000);
      }else{
          process_button_flag = false;
          
          break;
      }
    }
  }
  // メイン側より停止指示を受け取るメソッド
  public void stopRunning(){
    process_button_flag = false;
    running = false;
  }  
}
