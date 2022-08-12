import controlP5.*;
import processing.serial.*;

int need_loading_time;
final long need_washing_time = 300;
final long need_collecting_time = 300;
long start_washing_time = 10000000;
long start_loading_time = 10000000;
long start_collecting_time = 10000000;
long remaining_time = 0;
boolean pump_12ch;
boolean reverse;
boolean pump_1;
boolean pump_2;
boolean pump_3;

 
Serial port;
 
ControlP5 cp5;
 
void setup() {
 
  //size(800, 450);  // W:H = 16:9
  size(1120, 630);  // W:H = 16:9
  //size(1600, 900);  // W:H = 16:9
  int font_size = width/56;
  cp5 = new ControlP5(this);
  PFont myFont = createFont("Arial",font_size,true);
  ControlFont cf1 = new ControlFont(myFont,font_size);
 
  cp5 = new ControlP5(this);
  // port = new Serial(this, "COM5", 9600);
  int button_width = width/6;
  int button_height = height/8;
  
  cp5.addButton("Washing")
    .setPosition(button_width/6, height-5*button_height/2)
    .setSize(button_width, button_height)      
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;  
    
 
  cp5.addButton("Loading")    
    .setPosition(4*button_width/3, height-5*button_height/2)
    .setSize(button_width, button_height)      
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
 
  cp5.addButton("Collecting")  
    .setPosition(5*button_width/2, height-5*button_height/2)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0)) 
    .setFont(cf1) ;
 
  cp5.addButton("AllPhase")  
    .setPosition(11*button_width/3, height-5*button_height/2)  
    .setSize(button_width, button_height)  
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setCaptionLabel("All Phase")
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
 
  cp5.addButton("LoadingCollecting")
    .setPosition(29*button_width/6, height-5*button_height/2)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setCaptionLabel("Loading\nCollecting")
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Front")
    .setPosition(button_width/6, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Back")
    .setPosition(4*button_width/3, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0))
    .setFont(cf1) ;
    
  cp5.addButton("Close")
    .setPosition(5*button_width/2, height-5*button_height/4)  
    .setSize(button_width, button_height)   
    .setColorActive(color(0, 40))
    .setColorBackground(color(181, 255, 20))
    .setColorForeground(color(181, 255, 20))
    .setColorCaptionLabel(color(0)) 
    .setFont(cf1);
  
  cp5.addSlider("need_loading_time")
    .setPosition(11*button_width/3, height-17*button_height/4)
    .setSize(2*button_width, button_height/2)
    .setSliderMode(Slider.FLEXIBLE)
    .setRange(0, 330)
    .setValue(180) 
    .setFont(cf1)
    .setCaptionLabel("Loading Time[sec]") ;
    
  cp5.getController("need_loading_time")
    .getCaptionLabel()
    .setVisible(true) 
    .toUpperCase(false)
    .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE) ;
  
  cp5.addToggle("pump_12ch")
    .setPosition(button_width/6, 3.5 * button_height)
    .setSize(button_height/4, button_height/4) 
    .setFont(cf1)
    .setValue(false);
  
  cp5.addToggle("reverse")
    .setPosition(4*button_width/3, 3.5 * button_height)
    .setSize(button_height/4, button_height/4) 
    .setFont(cf1) 
    .setValue(false);
  
  cp5.addToggle("pump_1")
    .setPosition(button_width/6, 4.5 * button_height)
    .setSize(button_height/4, button_height/4) 
    .setFont(cf1)
    .setValue(false) ;
  
  cp5.addToggle("pump_2")
    .setPosition(4*button_width/3, 4.5 * button_height)
    .setSize(button_height/4, button_height/4) 
    .setFont(cf1) 
    .setValue(false) ;
    
  cp5.addToggle("pump_3")
    .setPosition(5*button_width/2, 4.5 * button_height)
    .setSize(button_height/4, button_height/4) 
    .setFont(cf1) 
    .setValue(false) ;
}

void draw_gauge(int percentage, float y, String name) {
  // int percentage = 0;
  int x = width/5;
  int font_size = width/56;
  // y = height/20;
  
  int gauge_width = 3*width/5;
  int gauge_height = height/16;
  
   //ゲージの下地描画
  fill(255);              //色指定
  rect(x, y, gauge_width, gauge_height);        //ゲージの下地描画
  
  fill(0);            //色指定
  //横軸表示
  textSize(1.5*font_size);               //テキストサイズ
  text(name, x/8, y+gauge_height);  // name
  textSize(font_size);
  textAlign(CENTER);          //中央揃え
  text(  0, x, y+3*gauge_height/2);   //0
  text(50, x+gauge_width/2, y+3*gauge_height/2);   //50
  text(100, x+gauge_width, y+3*gauge_height/2);   //100
  
  
  //ゲージ表示
  fill(0,128,0);               //色指定
  rect(x, y, percentage*(gauge_width/100), gauge_height); //横棒描画
  fill(color(0, 128, 0));                 //色指定
  
  //パーセンテージ表示
  textSize(1.5*font_size);                  //テキストサイズ
  textAlign(RIGHT);              //右揃え
  text(percentage, 3*x/2+gauge_width, y+gauge_height);  
  
  //%表示
  textSize(font_size);                  //テキストサイズ
  textAlign(LEFT);               //左揃え
  text("%", 3*x/2+gauge_width, y+gauge_height);         
}

 
void draw() {    
  int font_size = width/56;
  background(200);
  long temp;
  long washing_time = (long)max(0, (millis()/1000)-start_washing_time);
  long loading_time = (long)max(0, (millis()/1000)-start_loading_time);
  long collecting_time = (long)max(0, (millis()/1000)-start_collecting_time);
  draw_gauge((int)(min(100, 100*washing_time/need_washing_time)), height/20, "Washing");
  draw_gauge((int)(min(100, 100*loading_time/need_loading_time)), height/6, "Loading");
  draw_gauge((int)(min(100, 100*collecting_time/need_collecting_time)), 9*height/32, "Collecting");
  
  // 残り時間表示
  fill(color(0));
  textSize(1.5*font_size);                  //テキストサイズ
  text("The Remaining Time", 2*width/3, 7*height/8);  
  temp = remaining_time-(long)(min(need_washing_time, washing_time));
  temp -= (long)(min(need_loading_time, loading_time));
  temp -= (long)(min(need_washing_time, collecting_time));
  int minutes = (int)(temp/60);
  int seconds = (int)(temp%60);
  text(minutes, 11*width/16, 19*height/20);
  text("min", 11*width/16 + width/40, 19*height/20);
  text(seconds, 11*width/16 + width/10, 19*height/20);
  text("sec", 11*width/16 + width/7.5, 19*height/20);

  
  
  
  if(pump_12ch) {
  }
  if(reverse) {
  }
  if(pump_1) {
  }
  if(pump_2) {
  }
  if(pump_3) {
  }
}
 
 
void Washing() {
  // port.write('w');  // 何らかの文字や数値を送る
  start_washing_time = (long)millis()/1000;
  remaining_time = need_washing_time;
}
 
void Loading() {
  // port.write('l');
  // port.write(LoadingTime);  // スライダーで指定された数値を送る
  start_loading_time = (long)millis()/1000;
  remaining_time = need_loading_time;
}
 
void Collecting() {
  // port.write('c');
  start_collecting_time = (long)millis()/1000;
  remaining_time = need_collecting_time;
}
 
void AllPhase() {
  // port.write('a');
  start_washing_time = (long)millis()/1000;
  start_loading_time = (long)millis()/1000 + need_washing_time;
  start_collecting_time = (long)millis()/1000 + need_washing_time + need_loading_time;
  remaining_time = need_washing_time + need_loading_time + need_collecting_time;
}
 
void LoadingCollecting() {
  // port.write('lc');
  // port.write(LoadingTime);
  start_loading_time = (long)millis()/1000;
  start_collecting_time = (long)millis()/1000+ need_loading_time;
  remaining_time = need_loading_time + need_collecting_time;
}

void Front() {
  // port.write('f');
}

void Back() {
  // port.write('b');
}

void Close() {
  // port.write('cl');
  start_washing_time = 10000000;
  start_loading_time = 10000000;
  start_collecting_time = 10000000;
  remaining_time = 0;
}
