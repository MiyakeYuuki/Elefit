import controlP5.*;  //GUI package for processing
import processing.serial.*; //Package for Serial communication between an Arduino
Serial port;
ControlP5 cp5;

String[] time_and_progress;   // Save signals from microcontroller
int the_remaining_time = 0;   // Save estimated time to finish the excecuted process
int washing_progress = 0;     // Save the Washing progress [%]
int loading_progress = 0;     // Save the Loading progress [%]
int collecting_progress = 0;  // Save the Collecting progress [%]
int discharge_progress = 0;   // Save the Discharge progress [%]

void setup() {
  /* ディスプレイサイズに合わせて変更 */
  //size(800, 450);  // W:H = 16:9
  //size(1120, 630);  // W:H = 16:9
  /*Display settings*/
  size(1600, 900);  // W:H = 16:9

  int font_size = width/56;
  cp5 = new ControlP5(this);
  PFont myFont = createFont("Arial", font_size, true);
  ControlFont cf1 = new ControlFont(myFont, font_size);

  /* Serial port settings */
  String[] comPort = port.list();
  int num = comPort.length;
  println("Test serial port.");
  for (int i=0; i<num; i++) {
    print(comPort[i]+"     ");
    try {
      port = new Serial(this, comPort[i], 115200);
      println("O.K");
    }
    catch(Exception e) {
      println("failed");
      continue;
    }
  }

  /* Button settings */
  cp5 = new ControlP5(this);
  int button_width = width/6;
  int button_height = height/10;

  cp5.addButton("Washing")
    .setPosition(button_width/6, height-5*button_height/2)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("Loading")
    .setPosition(4*button_width/3, height-5*button_height/2)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("Collecting")
    .setPosition(5*button_width/2, height-5*button_height/2)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("AllPhase")
    .setPosition(11*button_width/3, height-5*button_height/2)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setCaptionLabel("All Phase")
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;

  cp5.addButton("LoadingCollecting")
    .setPosition(29*button_width/6, height-5*button_height/2)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setCaptionLabel("   Loading\n          ↓   \nCollecting")
    .align(29*button_width/6, height-5*button_height/2, ControlP5.CENTER, ControlP5.UP)  //  8.5*width/10,11*height/14
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;


  cp5.addButton("Front")
    .setPosition(button_width/6, height-5*button_height/4)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("Back")
    .setPosition(4*button_width/3, height-5*button_height/4)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("Discharge")
    .setPosition(5*button_width/2, height-5*button_height/4)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1) ;

  cp5.addButton("Close")
    .setPosition(11*button_width/3, height-5*button_height/4)
    .setSize(button_width, button_height)
    .setColorActive(color(0, 40))
    .setColorBackground(color(150, 255, 200))
    .setColorForeground(color(121, 200, 20))
    .setColorCaptionLabel(color(20))
    .setFont(cf1);

  cp5.addToggle("pump_12ch")
    .setPosition(button_width/6, 5 * button_height)
    .setSize(button_height/3, button_height/3)
    .setFont(cf1)
    .setColorCaptionLabel(color(230))
    .setValue(false);

  cp5.addToggle("pump_1")
    .setPosition(button_width/6, 6 * button_height)
    .setSize(button_height/3, button_height/3)
    .setFont(cf1)
    .setColorCaptionLabel(color(230))
    .setValue(false) ;

  cp5.addToggle("pump_2")
    .setPosition(4*button_width/3, 6 * button_height)
    .setSize(button_height/3, button_height/3)
    .setFont(cf1)
    .setColorCaptionLabel(color(230))
    .setValue(false) ;

  cp5.addToggle("pump_3")
    .setPosition(5*button_width/2, 6 * button_height)
    .setSize(button_height/3, button_height/3)
    .setFont(cf1)
    .setColorCaptionLabel(color(230))
    .setValue(false) ;
}

/* Function for drawing gauge */
void draw_gauge(int percentage, float y, String name) {

  int x = width/5;
  int font_size = width/56;
  int gauge_width = 3*width/5;
  int gauge_height = height/16;

  //ゲージの下地描画
  fill(150);              //色指定
  rect(x, y, gauge_width, gauge_height, 20);        //ゲージの下地描画

  fill(255);            //色指定
  //横軸表示
  textSize(1.5*font_size);              //テキストサイズ
  text(name, x/4, y+gauge_height-10);  // name
  textSize(font_size);
  textAlign(CENTER);          //中央揃え
  text(0, x, y+3*gauge_height/2);   //0
  text(50, x+gauge_width/2, y+3*gauge_height/2);   //50
  text(100, x+gauge_width, y+3*gauge_height/2);   //100
  //ゲージ表示
  fill(255, 200, 0);              //ゲージ色指定
  noStroke(); //枠線なし

  //横棒描画
  rect(x, y, percentage*gauge_width/100, gauge_height, 20); 
  fill(color(0, 128, 0));        //色指定
  //パーセンテージ表示
  textSize(1.5*font_size);                  //テキストサイズ
  textAlign(RIGHT);              //右揃え
  text(percentage, 3*x/2+gauge_width, y+gauge_height);
  //%表示
  textSize(font_size);                  //テキストサイズ
  textAlign(LEFT);               //左揃え
  text(" %", 3*x/2+gauge_width, y+gauge_height);

  // バージョン表示
  fill(color(230));
  textSize(0.6*font_size);
  text("Elefit Controlller (ver.4a) ", 8.5*width/10, 13.5*height/14);
}

// Function to draw all gauge, control pump
void draw() {
  while (port.available()>0) {
    String progress = port.readString();
    if (progress != null) {
      String time_and_progress_lf = progress.replace("\n", "");
      time_and_progress = time_and_progress_lf.split(",");
      if (time_and_progress.length==5) {
        try {
          the_remaining_time = Integer.parseInt(time_and_progress[0]);
          washing_progress = Integer.parseInt(time_and_progress[1]);
          loading_progress = Integer.parseInt(time_and_progress[2]);
          collecting_progress = Integer.parseInt(time_and_progress[3]);
          discharge_progress = Integer.parseInt(time_and_progress[4]);
        }
        catch(NumberFormatException e) {
          // エラーが発生したら、残り時間と進捗の更新をスキップ
        }
      }
    } else {
      // 信号を受信しなければ何も処理を実行しない
    }
  }

  int font_size = width/56;

  background(30); // 背景色の設定
  // 画面背景のグラデーション作成
  int j;
  for (j=0; j<width; j++) {
    stroke(150, 200, j*255/width, 50);  //引数は(R,G,B,不透明度)の順番
    line(j*1.5, j, j, height/2.1);
  }
  draw_gauge(washing_progress, height/36, "Washing");
  draw_gauge(loading_progress, 5*height/36, "Loading");
  draw_gauge(collecting_progress, 9*height/36, "Collecting");
  draw_gauge(discharge_progress, 13*height/36, "Discharge");

  // 残り時間表示
  fill(color(230));
  textSize(1.5*font_size);                  //テキストサイズ
  text("The Remaining Time", 2*width/3, 9*height/14);

  int minutes = (int)(the_remaining_time/60);
  int seconds = (int)(the_remaining_time%60);
  text(minutes, 11*width/16, 14*height/20);
  text("min", 11*width/16 + width/31, 14*height/20);
  text(seconds, 11*width/16 + width/10, 14*height/20);
  text("sec", 11*width/16 + width/7.5, 14*height/20);

}

/* 各ボタンが押されたときにマイコンに命令を送信 */
void Washing() {
  port.write("washing,0,0\n");
}
void Loading() {
  port.write("loading,0,0\n");
}
void Collecting() {
  port.write("collecting,0,0\n");
}
void pump_1(boolean theFlag) {
  if (theFlag==true) {
    port.write("on_pump_dba,1,0\n");
  } else {
    port.write("off_pump_dba,0,0\n");
  }
}
void pump_2(boolean theFlag) {
  if (theFlag==true) {
    port.write("on_pump_dba,2,0\n");
  } else {
    port.write("off_pump_dba,0,0\n");
  }
}
void pump_3(boolean theFlag) {
  if (theFlag==true) {
    port.write("on_pump_dba,3,0\n");
  } else {
    port.write("off_pump_dba,0,0\n");
  }
}
void pump_12ch(boolean theFlag) {
  if (theFlag==true) {
    port.write("on_pump_12ch,100,0\n");
  } else {
    port.write("off_pump_12ch,0,0\n");
  }
}
void AllPhase() {
  port.write("all_phase,0,0\n");
}
void LoadingCollecting() {
  port.write("lc,0,0\n");
}
void Front() {
    port.write("step_front,10,0\n");
}
void Back() {
    port.write("step_back,10,0\n");
}
void Discharge() {
  port.write("discharge,0,0\n");
}
void Close() {
  port.write("reset_arduino,0,0\n");
}
