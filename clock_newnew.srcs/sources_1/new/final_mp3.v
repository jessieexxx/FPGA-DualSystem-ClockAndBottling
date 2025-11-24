`timescale 1ns / 1ps


module final_mp3(
    input clk,//系统时钟输入
    input wire beep_r,//蜂鸣器使能信号（1=播放，0=静音）
    output beep_out,//输出PWM波
    output sd//启用管脚
    );
    reg beep = 0;//01状态翻转形成PWM波
     reg [6:0]tone = 0;//当前音调索引（0-113）
     reg [17:0]count1 = 0;//当前音调对应的计数值
     reg [17:0]count = 0;//PWM计数器
     reg[24:0]time_count = 0;//音调持续时间
     
    // 节拍控制参数（新增）
    parameter BPM = 120;                    // 默认120拍/分钟
    parameter CLK_FREQ = 50_000_000;        // 50MHz时钟
    parameter QUARTER_TIME = (60 * CLK_FREQ) / BPM; // 四分音符时长
    
    // 音符时值倍数定义（新增）
    parameter 
        DUR_WHOLE     = 4,  // 全音符4拍
        DUR_HALF      = 2,  // 二分音符2拍
        DUR_QUARTER   = 1,  // 四分音符1拍
        DUR_EIGHTH    = 0;  // 八分音符0.5拍
    
    // 当前音符持续时间（新增）
    reg [24:0] current_note_duration;

    
     assign beep_out = beep;
     assign sd = 1'b1;	
parameter  //(C大调乐谱参数)
				C3  = 18'd95419,  
                Cs3 = 18'd90193,   
                D3  = 18'd85033,   
                Ds3 = 18'd80354,   
                E3  = 18'd75756,   
                F3  = 18'd71632,    
                Fs3 = 18'd67566,    
                G3  = 18'd63774,    
                Gs3 = 18'd60239,    
                A3  = 18'd56817,    
                As3 = 18'd53647,    
                B3  = 18'd50606,    
                

                C4  = 18'd47800,    
                Cs4 = 18'd45125,    
                D4  = 18'd42588,   
                Ds4 = 18'd40192,    
                E4  = 18'd37935,    
                F4  = 18'd35815,   
                Fs4 = 18'd37783,    
                G4  = 18'd31887,  
                Gs4 = 18'd30083,    
                A4  = 18'd28408,  
                As4 = 18'd26823,    
                B4  = 18'd25303,    
                
			    C5  = 18'd23899,    // 523.25 Hz
                Cs5 = 18'd22542,    // 554.37 Hz
                D5  = 18'd21276,     // 587.33 Hz
                Ds5 = 18'd20079,     // 622.25 Hz
                E5  = 18'd18967,     // 659.26 Hz
                F5  = 18'd17894,     // 698.46 Hz
                Fs5 = 18'd16891,     // 739.99 Hz
                G5  = 18'd15943,     // 783.99 Hz
                Gs5 = 18'd15051,     // 830.61 Hz
                A5  = 18'd14204,     // 880.00 Hz
                As5 = 18'd13404,     // 932.33 Hz
                B5  = 18'd12651;     // 987.77 Hz

always@(posedge clk)//生成不同频率的波
begin
    count <= count + 1'b1;//由于初始time前count1没有设定先执行count+1
    if(count == count1)//当计数器达到当前音调设定值的时候
     begin
        count <= 17'd0;//重置计数器
        if(beep_r) beep <= !beep;//翻转beep状态产生方波
        else beep = 0;//如果beep_r为0则静音
     end
end
always@(posedge clk)
begin
    if(time_count < current_note_duration)//检查当前音调播放是否已经达到足够时间
    time_count <= time_count + 1'b1;//未到时间则继续计数
    else
        begin
        time_count = 25'd0;//重置时间计数器
            if(tone > 7'd86)//如果所有音调已经播放完
            tone = 7'd0;//回到第一个音调
            else
            begin 
                case(tone)
             /*   7'D0: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D1: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D2: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D3: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D4: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D5: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D6: begin count1=Cs5; current_note_duration=QUARTER_TIME/2*3; end
                7'D7: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D8: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D9: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D10: begin count1=As4; current_note_duration=QUARTER_TIME*4; end
                7'D11: begin count1=F4; current_note_duration=QUARTER_TIME*4; end
                
                7'D12: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D13: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D14: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D15: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D16: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D17: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D18: begin count1=Cs5; current_note_duration=QUARTER_TIME/2*3; end
                7'D19: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D20: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D21: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D22: begin count1=As4; current_note_duration=QUARTER_TIME*4; end
                7'D23: begin count1=F4; current_note_duration=QUARTER_TIME*4; end
                
                7'D24: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D25: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D26: begin count1=Gs5; current_note_duration=QUARTER_TIME; end
                7'D27: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D28: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D29: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D30: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end
                7'D31: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D32: begin count1=F5; current_note_duration=QUARTER_TIME/2*3; end
                
                7'D33: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D34: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D35: begin count1=Gs5; current_note_duration=QUARTER_TIME; end
                7'D36: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D37: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D38: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D39: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end
                7'D40: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D41: begin count1=F5; current_note_duration=QUARTER_TIME/2*3; end
                
                7'D42: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D43: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D44: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D45: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D46: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D47: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D48: begin count1=Cs5; current_note_duration=QUARTER_TIME/2*3; end
                7'D49: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D50: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D51: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D52: begin count1=As4; current_note_duration=QUARTER_TIME*4; end
                
                //副歌
                7'D53: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D54: begin count1=Cs5; current_note_duration=QUARTER_TIME/2; end
                7'D55: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end    
                7'D56: begin count1=F5; current_note_duration=QUARTER_TIME/2*11; end
                7'D57: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end  
                7'D58: begin count1=Cs5; current_note_duration=QUARTER_TIME/2; end
                7'D59: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D60: begin count1=Cs5; current_note_duration=QUARTER_TIME/2; end
                7'D61: begin count1=C5; current_note_duration=QUARTER_TIME*6; end
                
                7'D62: begin count1=Cs5; current_note_duration=QUARTER_TIME/2; end
                7'D63: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D64: begin count1=As4; current_note_duration=QUARTER_TIME/2; end
                7'D65: begin count1=Cs5; current_note_duration=QUARTER_TIME/2; end
                7'D66: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end    
                7'D67: begin count1=F5; current_note_duration=QUARTER_TIME/2*11; end
                7'D68: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end
                7'D69: begin count1=F5; current_note_duration=QUARTER_TIME/2; end
                7'D70: begin count1=As5; current_note_duration=QUARTER_TIME/2; end
                7'D71: begin count1=F5; current_note_duration=QUARTER_TIME/2; end
                7'D72: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end
                7'D73: begin count1=F5; current_note_duration=QUARTER_TIME/2; end
                7'D74: begin count1=Gs5; current_note_duration=QUARTER_TIME/2; end
                7'D75: begin count1=As5; current_note_duration=QUARTER_TIME/2; end
                
                
                7'D76: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D77: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D78: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D79: begin count1=C5; current_note_duration=QUARTER_TIME/2; end
                7'D80: begin count1=Cs5; current_note_duration=QUARTER_TIME/2*3; end
                7'D81: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D82: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D83: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D84: begin count1=As4; current_note_duration=QUARTER_TIME*4; end
                */
/*7'D0: begin count1=C3; current_note_duration=QUARTER_TIME; end
                7'D1: begin count1=Cs3; current_note_duration=QUARTER_TIME; end
                7'D2: begin count1=D3; current_note_duration=QUARTER_TIME; end    
                7'D3: begin count1=Ds3; current_note_duration=QUARTER_TIME; end
                7'D4: begin count1=E3; current_note_duration=QUARTER_TIME; end  
                7'D5: begin count1=F3; current_note_duration=QUARTER_TIME; end
                7'D6: begin count1=Fs3; current_note_duration=QUARTER_TIME*2; end
                7'D7: begin count1=G3; current_note_duration=QUARTER_TIME*2; end
                7'D8: begin count1=Gs3; current_note_duration=QUARTER_TIME*2; end
                7'D9: begin count1=A3; current_note_duration=QUARTER_TIME*2; end
                7'D10: begin count1=As3; current_note_duration=QUARTER_TIME; end
                7'D11: begin count1=B3; current_note_duration=QUARTER_TIME; end
                
                7'D12: begin count1=C3; current_note_duration=QUARTER_TIME; end
                7'D13: begin count1=Cs3; current_note_duration=QUARTER_TIME; end
                7'D14: begin count1=D3; current_note_duration=QUARTER_TIME; end    
                7'D15: begin count1=Ds3; current_note_duration=QUARTER_TIME/2; end
                7'D16: begin count1=E3; current_note_duration=QUARTER_TIME/2; end  
                7'D17: begin count1=F3; current_note_duration=QUARTER_TIME/2; end
                7'D18: begin count1=Fs3; current_note_duration=QUARTER_TIME/2; end
                7'D19: begin count1=G3; current_note_duration=QUARTER_TIME/2; end
                7'D20: begin count1=Gs3; current_note_duration=QUARTER_TIME*3; end
                7'D21: begin count1=A3; current_note_duration=QUARTER_TIME*3; end
                7'D22: begin count1=As3; current_note_duration=QUARTER_TIME*3; end
                7'D23: begin count1=B3; current_note_duration=QUARTER_TIME; end*/
                7'D0: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D1: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D2: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D3: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D4: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D5: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D6: begin count1=Cs5; current_note_duration=QUARTER_TIME*2/3; end
                7'D7: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D8: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D9: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D10: begin count1=As4; current_note_duration=QUARTER_TIME/4; end
                7'D11: begin count1=F4; current_note_duration=QUARTER_TIME/4; end
                
                7'D12: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D13: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D14: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D15: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D16: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D17: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D18: begin count1=Cs5; current_note_duration=QUARTER_TIME*2/3; end
                7'D19: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D20: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D21: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D22: begin count1=As4; current_note_duration=QUARTER_TIME/4; end
                7'D23: begin count1=F4; current_note_duration=QUARTER_TIME/4; end
                
                7'D24: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D25: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D26: begin count1=Gs5; current_note_duration=QUARTER_TIME; end
                7'D27: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D28: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D29: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D30: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end
                7'D31: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D32: begin count1=F5; current_note_duration=QUARTER_TIME*2/3; end
                
                7'D33: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D34: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D35: begin count1=Gs5; current_note_duration=QUARTER_TIME; end
                7'D36: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D37: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D38: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D39: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end
                7'D40: begin count1=F5; current_note_duration=QUARTER_TIME; end
                7'D41: begin count1=F5; current_note_duration=QUARTER_TIME*2/3; end
                
                7'D42: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D43: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D44: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D45: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D46: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D47: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D48: begin count1=Cs5; current_note_duration=QUARTER_TIME*2/3; end
                7'D49: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D50: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D51: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D52: begin count1=As4; current_note_duration=QUARTER_TIME/4; end
                7'D53: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                //副歌
                7'D54: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D55: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                7'D56: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end    
                7'D57: begin count1=F5; current_note_duration=QUARTER_TIME/5; end
                7'D58: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end  
                7'D59: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                7'D60: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D61: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                7'D62: begin count1=C5; current_note_duration=QUARTER_TIME/6; end
                
                7'D63: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                7'D64: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D65: begin count1=As4; current_note_duration=QUARTER_TIME*2; end
                7'D66: begin count1=Cs5; current_note_duration=QUARTER_TIME*2; end
                7'D67: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end    
                7'D68: begin count1=F5; current_note_duration=QUARTER_TIME*2/11; end
                7'D69: begin count1=Ds5; current_note_duration=QUARTER_TIME*2; end
                7'D70: begin count1=F5; current_note_duration=QUARTER_TIME*2; end
                7'D71: begin count1=As5; current_note_duration=QUARTER_TIME/2; end
                7'D72: begin count1=F5; current_note_duration=QUARTER_TIME/2; end
                7'D73: begin count1=Ds5; current_note_duration=QUARTER_TIME/2; end
                7'D74: begin count1=F5; current_note_duration=QUARTER_TIME*2; end
                7'D75: begin count1=Gs5; current_note_duration=QUARTER_TIME*2; end
                7'D76: begin count1=As5; current_note_duration=QUARTER_TIME/2; end
                
                
                7'D77: begin count1=F5; current_note_duration=QUARTER_TIME; end    
                7'D78: begin count1=Ds5; current_note_duration=QUARTER_TIME; end
                7'D79: begin count1=Cs5; current_note_duration=QUARTER_TIME; end  
                7'D80: begin count1=C5; current_note_duration=QUARTER_TIME*2; end
                7'D81: begin count1=Cs5; current_note_duration=QUARTER_TIME*2/3; end
                7'D82: begin count1=C5; current_note_duration=QUARTER_TIME; end
                7'D83: begin count1=As4; current_note_duration=QUARTER_TIME; end
                7'D84: begin count1=Gs4; current_note_duration=QUARTER_TIME; end
                7'D85: begin count1=As4; current_note_duration=QUARTER_TIME/4; end
                    endcase   
                    tone = tone+1'b1;
             end        
        end
end

endmodule