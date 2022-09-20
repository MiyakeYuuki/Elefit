import pigpio
from time import sleep
import sys
import tkinter
import tkinter.ttk as ttk
import threading
import datetime

PWM_PORT_M1_1 = 17  #DPE-100-7P-Y1 (A)
PWM_PORT_M2_1 = 27  #DPE-100-7P-Y1 (B)
PWM_PORT_M3_1 = 22  #DPE-100-7P-Y1 (C)

PWM_PORT_M4_1 = 18  #6-channel pump (R+)
PWM_PORT_M4_2 = 23  #6-channel pump (R-)

PWM_PORT_M5_1 = 24  #6-channel pump (L+)
PWM_PORT_M5_2 = 25  #6-channel pump (L-)

LIMIT_SWITCH  = 4   #Limit switch

STEP_PORT_1   = 12  #PFL20-24Q A
STEP_PORT_2   = 16  #PFL20-24Q A'
STEP_PORT_3   = 20  #PFL20-24Q B
STEP_PORT_4   = 21  #PFL20-24Q B'
DELAYTIME     = 0.004 #stepermotomer time.sleep()
LOW  = 0
HIGH = 1

PWM_RANGE     = 100 #Maximum value of generated PWM(1~100)
FREQ          = 100 #pwm frequency (Hz)
reverse = 0         #12chpump reverse func
speed   = 100       #12chpump revsepeed
# state = 0           
#first_time = 20     #
phase_all = 0       #
phase_LandC = 0
pi = pigpio.pi()

#####GPIO pin setup#####
pi.set_mode(PWM_PORT_M1_1,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M2_1,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M3_1,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M4_1,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M4_2,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M5_1,pigpio.OUTPUT)
pi.set_mode(PWM_PORT_M5_2,pigpio.OUTPUT)
pi.set_mode(STEP_PORT_1,pigpio.OUTPUT)
pi.set_mode(STEP_PORT_2,pigpio.OUTPUT)
pi.set_mode(STEP_PORT_3,pigpio.OUTPUT)
pi.set_mode(STEP_PORT_3,pigpio.OUTPUT)
pi.set_mode(LIMIT_SWITCH,pigpio.INPUT)

#####GPIO initial setup#####
pi.write(PWM_PORT_M1_1,LOW)
pi.write(PWM_PORT_M2_1,LOW)
pi.write(PWM_PORT_M3_1,LOW)
pi.write(PWM_PORT_M4_1,LOW)
pi.write(PWM_PORT_M4_2,LOW)
pi.write(PWM_PORT_M5_1,LOW)
pi.write(PWM_PORT_M5_2,LOW)
pi.write(STEP_PORT_1,LOW)
pi.write(STEP_PORT_2,LOW)
pi.write(STEP_PORT_3,LOW)
pi.write(STEP_PORT_4,LOW)

#####PWM setup#####
pi.set_PWM_frequency(PWM_PORT_M4_1, FREQ)
pi.set_PWM_range(PWM_PORT_M4_1, PWM_RANGE)
pi.set_PWM_frequency(PWM_PORT_M4_2, FREQ)
pi.set_PWM_range(PWM_PORT_M4_2, PWM_RANGE)
pi.set_PWM_frequency(PWM_PORT_M5_1, FREQ)
pi.set_PWM_range(PWM_PORT_M5_1, PWM_RANGE)
pi.set_PWM_frequency(PWM_PORT_M5_2, FREQ)
pi.set_PWM_range(PWM_PORT_M5_2, PWM_RANGE)

##### Each phase timer setup#####
def timer_1():
    timer = 768
    for i in range(timer,-1,-1):
        min = int(i / 60)
        sec = i - min*60
        timer_label.set("Phase_1:  " + str(min) + "min" + str(sec) + "s")
        tki.update()
        sleep(1)
def timer_2():
    timer = 622
    for i in range(timer,-1,-1):
        min = int(i / 60)
        sec = i - min*60
        timer_label.set("Phase_2:  " + str(min) + "min" + str(sec) + "s")
        tki.update()
        sleep(1)
def timer_3():
    timer = 421
    for i in range(timer,-1,-1):
        min = int(i / 60)
        sec = i - min*60
        timer_label.set("Phase_3:  " + str(min) + "min" + str(sec) + "s")
        tki.update()
        sleep(1)
def timer_4():
    timer = 1811
    for i in range(timer,-1,-1):
        min = int(i / 60)
        sec = i - min*60
        timer_label.set("ALL:  " + str(min) + "min" + str(sec) + "s")
        tki.update()
        sleep(1)
        
def timer_5():
    timer = 1043
    for i in range(timer,-1,-1):
        min = int(i / 60)
        sec = i - min*60
        timer_label.set("L&C:  " + str(min) + "min" + str(sec) + "s")
        tki.update()
        sleep(1)
        
def step_front(step):
    pi.write(STEP_PORT_2,HIGH)
    pi.write(STEP_PORT_4,HIGH)
    
    for i in range(step):
        pi.write(STEP_PORT_1,HIGH)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_3,HIGH)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_1,LOW)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_3,LOW)
        sleep(DELAYTIME)
        
    pi.write(STEP_PORT_2,LOW)
    pi.write(STEP_PORT_4,LOW)

def step_back(step):
    pi.write(STEP_PORT_2,HIGH)
    pi.write(STEP_PORT_4,HIGH)
    
    for i in range(step):
        
        limit = pi.read(LIMIT_SWITCH)
        if limit == HIGH:
            break
        
        pi.write(STEP_PORT_3,HIGH)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_1,HIGH)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_3,LOW)
        sleep(DELAYTIME)
        pi.write(STEP_PORT_1,LOW)
        sleep(DELAYTIME)
        
    pi.write(STEP_PORT_2,LOW)
    pi.write(STEP_PORT_4,LOW)

def on_pump_12ch(speed):
    if reverse_checkbox() == 0:
        pi.set_PWM_dutycycle(PWM_PORT_M4_1, speed)
        pi.set_PWM_dutycycle(PWM_PORT_M5_2, speed*0.87)
    else:
        pi.set_PWM_dutycycle(PWM_PORT_M4_2, speed)
        pi.set_PWM_dutycycle(PWM_PORT_M5_1, speed*0.87)
def off_pump_12ch():
        pi.set_PWM_dutycycle(PWM_PORT_M4_1, 0)
        pi.set_PWM_dutycycle(PWM_PORT_M4_2, 0)
        pi.set_PWM_dutycycle(PWM_PORT_M5_1, 0)
        pi.set_PWM_dutycycle(PWM_PORT_M5_2, 0)
        
def rev_pump_12ch():
    pi.set_PWM_dutycycle(PWM_PORT_M4_2, 100)
    pi.set_PWM_dutycycle(PWM_PORT_M5_1, 87)
    
def pump_12ch_pwm():
    on_pump_12ch(80)
    sleep(0.385)
    off_pump_12ch()
    sleep(0.625)

def pump_12ch_checkbox():
    if bln[0].get():
        on_pump_12ch(100)
    else:
        off_pump_12ch()
    
def reverse_checkbox():
    if bln[1].get():
        reverse = 1
        return reverse
    else:
        reverse = 0
        return reverse
    
def step_front_button():
    step_front(10)
    
def step_back_button():
    step_back(10)
    
def close_button():
    pi.write(PWM_PORT_M1_1,LOW)
    pi.write(PWM_PORT_M2_1,LOW)
    pi.write(PWM_PORT_M3_1,LOW)
    pi.set_PWM_dutycycle(PWM_PORT_M4_1, 0)
    pi.set_PWM_dutycycle(PWM_PORT_M4_2, 0)
    pi.set_PWM_dutycycle(PWM_PORT_M5_1, 0)
    pi.set_PWM_dutycycle(PWM_PORT_M5_2, 0)
    pi.stop()
    tki.destroy()
    
def pump_1_checkbox():
    if bln[2].get():
        pi.write(PWM_PORT_M1_1,HIGH)
    else:
        pi.write(PWM_PORT_M1_1,LOW)
        
def pump_2_checkbox():
    if bln[3].get():
        pi.write(PWM_PORT_M2_1,HIGH)
    else:
        pi.write(PWM_PORT_M2_1,LOW)
        
def pump_3_checkbox():
    if bln[4].get():
        pi.write(PWM_PORT_M3_1,HIGH)
    else:
        pi.write(PWM_PORT_M3_1,LOW)

#####Washing#####
def phase_1_button():
    phase1_time = 768
    global phase_all
    
    if phase_all == 0 | phase_LandC == 0:
        thread_1.start()
    
    #set up initial column position
    var_start_1(0)
    step_front(50)
    sleep(1)
    step_back(200)
    sleep(1)#sum(wait) = 2
    
    #DPE-100 On-time (SolutionTank - IntermediateTank)
    for i in range(20):
        pi.write(PWM_PORT_M1_1,HIGH)
        sleep(1)
        var_start_1(int((2+i)/phase1_time*100))
    pi.write(PWM_PORT_M1_1,LOW)
    sleep(1)#sum(wait) = 25
    
    #Time to fill up Acetic in column (IntermediateTank - column)
    for i in range(42):
        on_pump_12ch(100)
        sleep(1)
        var_start_1(int((25+i)/phase1_time*100))
    off_pump_12ch()
    sleep(1)#sum(wait) = 68
    var_start_1(int(68/phase1_time*100))
    
    #Shed Acetic to column
    for i in range(600):
        pump_12ch_pwm()
        var_start_1(int(68+i)/phase1_time*100)
    #sum(wait) = 668
    
    #Run out of Acetic(IntermediateTank - WasteTank)
    for i in range(100):
        on_pump_12ch(100)
        sleep(1)
        var_start_1(int((668+i)/phase1_time*100))
    off_pump_12ch()#sum(wait) = 768
    var_start_1(100)
    
#####Loading#####
def phase_2_button():
    slp = 300#Time of Soak in Nitric
    phase2_time = 622
    global phase_all
    if phase_all == 0 | phase_LandC== 0:
        thread_2.start()
    var_start_2(0)
    
    #DPE-100 On-time (SolutionTank - IntermediateTank)
    for i in range(18):
        pi.write(PWM_PORT_M2_1,HIGH)
        sleep(1)
        var_start_2(int(i/phase2_time*100))
    pi.write(PWM_PORT_M2_1,LOW)#sum(wait) = 19
    
    #Time to fill up Nitric in column (IntermediateTank - column)
    for i in range(53):
        on_pump_12ch(100)
        sleep(1)
        var_start_2(int((19+i)/phase2_time*100))
    off_pump_12ch()#sum(wait) = 72
    
    #Soak in Nitric (Wait 300s)
    for i in range(slp):
        sleep(1)
        var_start_2(int((72+i)/phase2_time*100))
    #sum(wait) = 372
        
    #Run out of Nitric(IntermediateTank - WasteTank)    
    for i in range(250):
        on_pump_12ch(100)
        sleep(1)
        var_start_2(int((72+i+slp)/phase2_time*100))
    off_pump_12ch()#sum(wait) = 622
    var_start_2(100)

#####Collecting#####
def phase_3_button():
    phase3_time = 422
    global phase_all
    if phase_all == 0 | phase_LandC == 0:
        thread_3.start()
    var_start_3(0)
    
    #DPE-100 On-time (SolutionTank - IntermediateTank)
    for i in range(18):
        pi.write(PWM_PORT_M3_1,HIGH)
        sleep(1)
        var_start_3(int(i/phase3_time*100))
    pi.write(PWM_PORT_M3_1,LOW)
    sleep(1)#sum(wait) = 20
    #Time to fill up Water in column (IntermediateTank - column)
    for i in range(55):
        on_pump_12ch(100)
        sleep(1)
        var_start_3(int((20+i)/phase3_time*100))
    off_pump_12ch()#sum(wait) = 75
    #12ch reversal
    for i in range(5):
        rev_pump_12ch()
        sleep(1)
        var_start_3(int((75+i)/phase3_time*100))
    off_pump_12ch()#sum(wait) = 80
    #Move column on collector
    step_front(160)
    
    #Collect
    for i in range(86):
        on_pump_12ch(80)
        sleep(1)
        var_start_3(int((80+i)/phase3_time*100))
    off_pump_12ch()#sum(wait) = 166
    #12ch reversal
    for i in range(5):
        rev_pump_12ch()
        sleep(1)
        var_start_3(int((166+i)/phase3_time*100))
    off_pump_12ch()#sum(wait) = 171
    #Move column to initial position
    step_back(180)
    for i in range(250):
        on_pump_12ch(100)
        sleep(1)
        var_start_3(int((171+i)/phase3_time*100))
    off_pump_12ch()#sum(wait) = 421
    var_start_3(100)
    
def phase_all_button():
    global phase_all
    phase_all = 1
    thread_4.start()
    phase_1_button()
    phase_2_button()
    phase_3_button()

def phase_LandC_buttun():
    global phase_LandC
    phase_LandC = 1
    thread_5.start()
    phase_2_button()
    phase_3_button()
    
def var_start_1(value_bar):
    #global text_label[0]
    progressbar[0].configure(value=value_bar)
    progressbar[0].update()
    text_label[0].set(str(value_bar) + "%")
    tki.update()
def var_start_2(value_bar):
    #global text_label[0]
    progressbar[1].configure(value=value_bar)
    progressbar[1].update()
    text_label[1].set(str(value_bar) + "%")
    tki.update()
def var_start_3(value_bar):
    #global text_label[0]
    progressbar[2].configure(value=value_bar)
    progressbar[2].update()
    text_label[2].set(str(value_bar) + "%")
    tki.update()
    
thread_1 = threading.Thread(target = timer_1)
thread_2 = threading.Thread(target = timer_2)
thread_3 = threading.Thread(target = timer_3)
thread_4 = threading.Thread(target = timer_4)
thread_5 = threading.Thread(target = timer_5)
maximum_bar=100
#value_bar=0
div_bar=1
value_bar = {}
text_label = {}
# Tkクラス生成
tki = tkinter.Tk()
# 画面サイズ
tki.geometry('640x390')
# 画面タイトル
tki.title('Elefit')
timer_label = tkinter.StringVar()
timer_label.set("Num s")
# チェックボタンのラベルをリスト化する
prog_txt = ['Washing','Loading','Collecting']
chk_txt  = ['pump_12ch','reverse','Pump_1','Pump_2','Pump_3']
btn_phase_txt = ['Washing','Loading','Collecting','ALL','Loading \n Collecting']
btn_txt = ['Front','Back','Close']
# チェックボックスON/OFFの状態
prog_bln = {}
bln = {}
chk = {}
btn_phase = {}
btn = {}
progressbar = {}
label = {}
# チェックボタンを動的に作成して配置
for i in range(len(prog_txt)):
    text_label[i] = tkinter.StringVar()
    text_label[i].set("0%")
    label[i] = tkinter.Label(textvariable=text_label[i],font=("","15",""))
    label[i].place(x=580,y=10+50*i)
    value_bar[i] = 0
    label_phase = tkinter.Label(text=prog_txt[i],font=("","15",""))
    label_phase.place(x=10 , y=10+50*i)
    progressbar[i]=ttk.Progressbar(tki,orient="horizontal",length=400,mode="determinate")
    progressbar[i].place(x=140,y=20+50*i)
    progressbar[i].configure(maximum=maximum_bar,value=value_bar[i])

for i in range(len(chk_txt)):
    if i < 2:
        bln[i] = tkinter.BooleanVar()
        chk[i] = tkinter.Checkbutton(tki, variable=bln[i], text=chk_txt[i],font=("","15",""))
        chk[i].place(x=10 + 200*i, y=160)
        
    else:
        bln[i] = tkinter.BooleanVar()
        chk[i] = tkinter.Checkbutton(tki, variable=bln[i], text=chk_txt[i],font=("","15",""))
        chk[i].place(x=10 + 200*(i-2), y=200)
        
for i in range(len(btn_phase_txt)):
    btn_phase[i] = tkinter.Button(tki, text=btn_phase_txt[i],height = 2,width = 6,font=("","15",""))
    btn_phase[i].place(x=10 + 125*i, y=240)

for i in range(len(btn_txt)):
    btn[i] = tkinter.Button(tki, text=btn_txt[i],height = 2,width = 8,font=("","15",""))
    btn[i].place(x=10 + 150*i, y=320)

label_timer = tkinter.Label(textvariable=timer_label,font=("","12",""))
label_timer.place(x=460,y=340)

btn[0]["command"] = lambda: step_front(10)
btn[1]["command"] = lambda: step_back(10)
btn[2]["command"] = lambda: close_button()
btn_phase[0]["command"] = lambda: phase_1_button()
btn_phase[1]["command"] = lambda: phase_2_button()
btn_phase[2]["command"] = lambda: phase_3_button()
btn_phase[3]["command"] = lambda: phase_all_button()
btn_phase[4]["command"] = lambda: phase_LandC_buttun()
chk[0]["command"] = lambda: pump_12ch_checkbox()
chk[1]["command"] = lambda: reverse_checkbox()
chk[2]["command"] = lambda: pump_1_checkbox()
chk[3]["command"] = lambda: pump_2_checkbox()
chk[4]["command"] = lambda: pump_3_checkbox()

tki.mainloop()    










