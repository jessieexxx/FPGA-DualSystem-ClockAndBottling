`timescale 1ns / 1ps

module final_clock(
    // 输入信号
    input  wire clk,          // 系统时钟
    input  wire reset,        // 复位信号
    input  wire stop,
    input  wire toxic,
    input  wire S0,           // 时钟模式减
    input  wire S1,           // 时钟模式加
    input  wire S2,           // 模式切换
    input  wire S3,           // 时间设置减
    input  wire S4,           // 时间设置加
    input  wire SW1,          // SW1为1表示正计时；SW2为0表示倒计时
    // 输出信号
    output wire [7:0] num_out0, // 数码管段选输出0
    output wire [7:0] num_out1, // 数码管段选输出1
    output wire [7:0] an_out,   // 数码管位选输出
    output wire [2:0] enlight_out,  // LED指示灯输出
    output wire beep_r,          // 蜂鸣器输出
    output wire [3:0] state_out, // 状态输出
    output wire bottle_full,
    output wire am_pm
);

    // 内部寄存器定义
    reg divclk;           // 分频时钟
    reg [2:0] key;        // 按键状态
    reg open_push_flag;    // 按键按下标志
    reg [20:0] push_count;    // 按键计时器
    reg [7:0] an;             // 数码管位选
    reg [7:0] num;            // 数码管显示数值
    reg [26:0] s_cnt;     // 秒计数器
    reg [6:0] hours_clk;  // 时钟模式小时
    reg [6:0] minute_clk; // 时钟模式分钟
    reg [6:0] second_clk; // 时钟模式秒
    reg [6:0] hours;      // 时间模式小时
    reg [6:0] minute;     // 时间模式分钟
    reg [6:0] second;     // 时间模式秒
    reg [3:0] handle_an_cnt; // 数码管位选计数器
    reg [17:0] div_cnt;   // 500Hz分频计数器
    reg [4:0] sw;             // 数码管显示数值选择
    reg [2:0] enlight; // LED状态
    reg enlight_flag;     // 标准时间1s标志 2s 周期
    reg sec_flag;//1s周期
    reg [3:0] state; // 模式状态
    // 新增寄存器定义
    reg [6:0] pills_per_bottle;    // 每瓶药片数（默认10）
    reg [6:0] total_bottles;        // 总药瓶数（默认5）
    reg [6:0] time_per_pill;        // 每片装药时间（秒）
    wire [6:0] current_pills;        // 当前瓶已装药片
    wire [6:0] completed_bottles;    // 已完成药瓶数
    reg [26:0] pill_timer;          // 装药计时器
    reg [10:0] total_pills;          //装药片总数
    reg [7:0] finaltotal_bottles;        //药瓶总数
    
    //日历相关
    reg [11:0] diary_year;
    reg [3:0] diary_month;
    reg [5:0] diary_day;       

    // 扩展状态参数定义
   
    // 状态机参数定义
    parameter IDEL         = 4'b0001, //空闲状态
              SET_TIME     = 4'b0010, //设置时间
              SET_CLOCK    = 4'b0100,   // 设置闹钟
              SET_MED      = 4'b0011,    // 设置药品数量
              SHOW_SETTINGS= 4'b0101,    // 显示设置值
              SHOW_PROGRESS= 4'b0110,    // 显示进度
              SET_NUMBER   = 4'b0000,    //默认状态
              SET_DIARY    = 4'b1000,    //设置日历
              SHOW_DIARY   = 4'b1001,    //显示日历
              SHOW_TOTAL   = 4'b0111;    //显示总量
            
    parameter MED_PILLS    = 2'b00,   // 当前编辑每瓶药片数
              MED_BOTTLES = 2'b01,   // 当前编辑总药瓶数
              MED_TIME     = 2'b10;   // 当前编辑每片时间
              
    parameter DIA_DAY      = 2'b00,
              DIA_MONTH    = 2'b01,
              DIA_YEAR     = 2'b10;

    reg [1:0] med_select; // 药品参数选择寄存器
    reg [1:0] dia_select;
    
    // 参数定义
    parameter count = 2000000;        // 20ms按键消抖时间
    parameter standard_count = 100000000; // 1s标准时间
    
    reg [6:0]temBottles;
    reg [10:0]temPills;
    reg [6:0] tempT;
    reg working;

    // 按键消抖处理
    always @(posedge clk) begin
        if ({S4,S3,S2,S1,S0} == 5'b00000)
            push_count = 0;
        else if (push_count == count)  // 防止计数器溢出
            push_count = count;
        else
            push_count = push_count + 1;
    end


    // 修改状态切换逻辑
    always @(posedge clk) begin
        if (key == 3) begin  // S2按下切换状态
            case (state)
               IDEL          : state <= SET_TIME;
                SET_TIME      : state <= SET_CLOCK;
                SET_CLOCK     : state <= SET_MED;
                SET_MED       : state <= SHOW_PROGRESS;
                SHOW_PROGRESS : state <= SHOW_SETTINGS;
                SHOW_SETTINGS : state <= SHOW_TOTAL;
                SET_NUMBER    : state <= IDEL;
                SHOW_TOTAL    : state <= SET_DIARY;
                SET_DIARY     : state <= SHOW_DIARY;
                SHOW_DIARY    : state <= IDEL;
                default       : state <= SET_NUMBER;
            endcase
        end
    end

    // 时间设置和时钟模式控制
    always @(posedge clk) begin
        if (state == SET_TIME) begin  // 时间设置模式
            case (key)
                1: begin  // 加操作
                    if (enlight[0] == 1) begin
                        if (second < 59) second <= second + 1;
                        else begin
                            second <= 0;
                            minute <= minute + 1;
                        end 
                    end
                    else if (enlight[1] == 1) begin
                        if (minute < 59) minute <= minute + 1;
                        else begin 
                            minute <= 0;
                            if (hours < 23) hours <= hours + 1;
                            else hours <= 0;
                        end 
                    end                             
                    else if (enlight[2] == 1) begin
                        if (hours < 23) hours <= hours + 1;
                        else hours <= 0;
                    end
                end
                2: begin  // 位选左移
                    enlight <= {enlight[1:0], enlight[2]};
                end
                4: begin  // 减操作
                    if (enlight[0] == 1) begin 
                        if (second > 0) second <= second - 1;
                        else second <= 59;
                    end
                    else if (enlight[1] == 1) begin 
                        if (minute > 0) minute <= minute - 1;
                        else minute <= 59;
                    end
                    else if (enlight[2] == 1) begin 
                        if (hours > 0) hours <= hours - 1;
                        else hours <= 23;
                    end
                end
                5: begin  // 位选右移
                    enlight <= {enlight[0], enlight[2:1]};
                end
            endcase
            
            if (!reset) begin  // 复位操作
                second <= 0;
                minute <= 0;
                hours  <= 0;
            end
        end
        else if (s_cnt == standard_count) begin  // 标准时间计数
            if (second < 59) second <= second + 1'd1;
            else if (minute < 59) begin 
                minute <= minute + 1'd1; 
                second <= 1'd0;
            end
            else if(hours < 5'd23) begin 
                hours <= hours + 1'd1;
                second <= 1'd0;
                minute <= 1'd0;
                end
             else if (hours == 5'd23) begin
                    hours <= 1'd0;
                    second <= 1'd0;
                    minute <= 1'd0;
                    case (diary_month) 
                        4'd1:begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd3:begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd5:begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd7:begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd8:begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd10:
                            begin
                                if(diary_day == 5'd31) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd12:
                            begin
                             if(diary_day == 5'd31) begin
                                    diary_year <=diary_year+1'd1;
                                    diary_month <= 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd4:begin
                                if(diary_day == 5'd30) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd6:begin
                                if(diary_day == 5'd30) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd9:begin
                                if(diary_day == 5'd30) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd11:
                            begin
                                if(diary_day == 5'd30) begin
                                    diary_month <= diary_month + 1'd1;
                                    diary_day <= 1'd1;
                                end
                                else begin
                                    diary_day<=diary_day +1'd1;
                                end
                            end
                        4'd2:
                            begin
                                    if(diary_day <5'd28) begin
                                    diary_day<=diary_day +1'd1;
                                end
                                    else if((diary_year % 10'd400 == 1'd0) || ((diary_year % 4'd4 == 1'd0) && (diary_year / 7'd100 != 1'd0)))begin
                                        if(diary_day <= 5'd28) begin
                                            diary_day <= diary_day + 1'd1;
                                        end else begin
                                            diary_day <= 1'd1;
                                            diary_month <= 2'd3;
                                        end
                                    end
                                    else begin
                                        diary_day <= 1'd1;
                                        diary_month <= 2'd3;
                                    end
                            end
                     endcase
                end
            end

       else if (state == SET_CLOCK) begin  // 时钟模式设置
            case (key)
                1: begin  // 加操作
                    if (enlight[0] == 1) begin
                        if (second_clk < 59) second_clk <= second_clk + 1;
                        else begin 
                            second_clk <= 0;
                            minute_clk <= minute_clk + 1;
                        end 
                    end
                    else if (enlight[1] == 1) begin
                        if (minute_clk < 59) minute_clk <= minute_clk + 1;
                        else begin 
                            minute_clk <= 0;
                            if (hours_clk < 23) hours_clk <= hours_clk + 1;
                            else hours_clk <= 0;
                        end 
                    end                             
                    else if (enlight[2] == 1) begin
                        if (hours_clk < 23) hours_clk <= hours_clk + 1;
                        else hours_clk <= 0;
                    end
                end
                2: begin  // 位选左移
                    enlight <= {enlight[1:0], enlight[2]};
                end
                4: begin  // 减操作
                    if (enlight[0] == 1) begin 
                        if (second_clk > 0) second_clk <= second_clk - 1;
                        else second_clk <= 59;
                    end
                    else if (enlight[1] == 1) begin 
                        if (minute_clk > 0) minute_clk <= minute_clk - 1;
                        else minute_clk <= 59;
                    end
                    else if (enlight[2] == 1) begin 
                        if (hours_clk > 0) hours_clk <= hours_clk - 1;
                        else hours_clk <= 23;
                    end
                end
                5: begin  // 位选右移
                    enlight <= {enlight[0], enlight[2:1]};
                end
            endcase
            
            if (!reset) begin  // 复位操作
                second_clk <= 0;
                minute_clk <= 0;
                hours_clk  <= 0;
            end
        end
       else if (state == SET_MED) begin
            // 位选控制（使用S0/S1切换编辑项）
            case(key)
                2: med_select <= (med_select == MED_TIME) ? MED_PILLS : med_select + 1; // S2右移
                5: med_select <= (med_select == MED_PILLS) ? MED_TIME : med_select - 1; // S3左移
            endcase
            
            // 数值调整（使用S3/S4加减）
            case(key)
                1: begin  // S4加操作
                    case(med_select)
                        MED_PILLS:   pills_per_bottle <= (pills_per_bottle < 99) ? pills_per_bottle + 1 : 99;
                        MED_BOTTLES: total_bottles    <= (total_bottles < 99) ? total_bottles + 1 : 99;
                        MED_TIME:    time_per_pill    <= (time_per_pill < 60) ? time_per_pill + 1 : 60;
                    endcase
                end
                4: begin  // S3减操作
                    case(med_select)
                        MED_PILLS:   pills_per_bottle <= (pills_per_bottle > 1) ? pills_per_bottle - 1 : 1;
                        MED_BOTTLES: total_bottles    <= (total_bottles > 1) ? total_bottles - 1 : 1;
                        MED_TIME:    time_per_pill    <= (time_per_pill > 1) ? time_per_pill - 1 : 1;
                    endcase
                end
            endcase
            
            // 实时LED指示（enlight对应bit闪烁）
            enlight <= (med_select == MED_PILLS)   ? 3'b100:
                       (med_select == MED_BOTTLES) ? 3'b010:3'b001;
        end
        else if (state == SET_DIARY) begin
            // 位选控制（使用S0/S1切换编辑项）
            case(key)
                2: dia_select <= (dia_select == DIA_DAY) ?  DIA_YEAR: dia_select + 1'd1; // S2右移
                5: dia_select <= (dia_select == DIA_YEAR) ? DIA_DAY : dia_select - 1'd1; // S3左移
            endcase
            
            // 数值调整（使用S3/S4加减）
            case(key)
                1: begin  // S4加操作
                    case(dia_select)
                        DIA_DAY:begin
                            diary_day <= (diary_day < 5'd31) ? diary_day + 5'd1 : 5'd31;
                        end   
                        DIA_MONTH: diary_month    <= (diary_month < 4'd12) ? diary_month + 1'd1 : 4'd12;
                        DIA_YEAR:  diary_year   <=  diary_year + 1'd1;
                    endcase
                end
                4: begin  // S3减操作
                    case(dia_select)
                        DIA_DAY:  diary_day <= (diary_day > 1'd1) ? diary_day - 1'd1 : 1'd1;
                        DIA_MONTH: diary_month  <= (diary_month > 1'd1) ? diary_month - 1'd1 : 1'd1;
                        DIA_YEAR: diary_year <= diary_year - 1'd1;
                    endcase
                end
            endcase
            
            // 实时LED指示（enlight对应bit闪烁）
            enlight <= (dia_select == DIA_YEAR)   ? 3'b100:
                       (dia_select == DIA_MONTH) ? 3'b010:3'b001;
        end
        
       else if(state == SET_NUMBER) begin
            enlight <= 3'b001; // LED状态
            pills_per_bottle <= 7'd10;    // 每瓶药片数（默认10）
            total_bottles <= 7'd5;        // 总药瓶数（默认5）
            time_per_pill <= 7'd1;        // 每片装药时间（秒）
            diary_year <= 11'd2025;
            diary_month <= 4'd6;
            diary_day <= 4'd1;
        end
     end

    // 按键状态处理
    always @(posedge clk) begin
        if (push_count == count - 1)  // 按键稳定后处理
            case ({S4,S3,S2,S1,S0})
                5'b10000: key <= 1;  // 时间设置加
                5'b01000: key <= 2;  // 时间设置减
                5'b00100: key <= 3;  // 模式切换
                5'b00010: key <= 4;  // 时钟模式加
                5'b00001: key <= 5;  // 时钟模式减
                default: key <= 0;   // 无按键
            endcase
        else 
            key <= 0;   
    end

    // 标准时间计数控制
    always @(posedge clk) begin
        if (s_cnt == standard_count) 
        begin
            s_cnt <= 1'd0;
            enlight_flag <= ~enlight_flag;  // 1s标志取反
            sec_flag<=~sec_flag;
        end
        else if(s_cnt == 32'd50000000)
        begin
            sec_flag<=~sec_flag;
             s_cnt <= s_cnt + 1'd1;
        end
        else
        begin
            s_cnt <= s_cnt + 1'd1;
        end
    end

    // 500Hz分频
    always @(posedge clk) begin
        if (div_cnt < 100000) 
            div_cnt <= div_cnt + 1;
        else begin
            divclk <= ~divclk;
            div_cnt <= 0;
        end
    end

    // 数码管位选计数
    always @(posedge divclk) begin
        handle_an_cnt <= handle_an_cnt + 1;
        if (handle_an_cnt == 8) 
            handle_an_cnt <= 0;
    end

    // 数码管位选和显示控制
    always @(posedge clk) begin
        // 新增状态显示处理
        if(state == SET_DIARY) begin
            case(handle_an_cnt)
                0: begin  
                    an <= (dia_select == DIA_DAY) ? (enlight_flag ? 8'b00000001 : 8'b00000000) : 8'b00000001;
                    sw <= diary_day % 10;
                end
                1: begin  
                    an <= (dia_select == DIA_DAY) ? (enlight_flag ? 8'b00000010 : 8'b00000000) : 8'b00000010;
                    sw <= diary_day / 10;
                end
                2: begin 
                    an <= (dia_select == DIA_MONTH) ? (enlight_flag ? 8'b00000100 : 8'b00000000) : 8'b00000100;
                    sw <= diary_month % 10;
                end
                3: begin  
                    an <= (dia_select == DIA_MONTH) ? (enlight_flag ? 8'b00001000 : 8'b00000000) : 8'b00001000;
                    sw <= diary_month / 10;
                end
                4: begin 
                    an <= (dia_select == DIA_YEAR) ? (enlight_flag ? 8'b00010000 : 8'b00000000) : 8'b00010000;
                    sw <= diary_year % 10;
                end
                5: begin 
                    an <= (dia_select == DIA_YEAR) ? (enlight_flag ? 8'b00100000 : 8'b00000000) : 8'b00100000;
                    sw <= (diary_year / 10)%10;
                end
                6: begin
                    an <= (dia_select == DIA_YEAR) ? (enlight_flag ? 8'b01000000 : 8'b00000000) : 8'b01000000;
                    sw <= (diary_year / 100)%10;
                end
                7: begin 
                    an <= (dia_select == DIA_YEAR) ? (enlight_flag ? 8'b10000000 : 8'b00000000) : 8'b10000000;
                    sw <= diary_year / 1000;
                end
            endcase
           end
        else if(state == SHOW_DIARY) begin
            case (handle_an_cnt)
                0: begin sw <= diary_day % 10; an <= 8'b00000001; end
                1: begin sw <= diary_day / 10; an <= 8'b00000010; end
                2: begin sw <= diary_month%10; an <= 8'b00000100; end // 显示/
                3: begin sw <= diary_month / 10; an <= 8'b00001000; end
                4: begin sw <= diary_year % 10; an <= 8'b00010000; end
                5: begin sw <= (diary_year/10)%10; an <= 8'b00100000; end // 显示B
                6: begin sw <= (diary_year/100)%10; an <= 8'b01000000; end
                7: begin sw <= diary_year/1000; an <= 8'b10000000; end
            endcase
        end
        else if(state == SHOW_TOTAL) begin
             case (handle_an_cnt)
                0: begin sw <= total_pills % 10; an <= 8'b00000001; end
                1: begin sw <= (total_pills / 10)%10; an <= 8'b00000010; end
                2: begin sw <= (total_pills / 100)%10; an <= 8'b00000100; end // 显示/
                3: begin sw <= (total_pills / 1000)%10; an <= 8'b00001000; end
                4: begin sw <= 12; an <= 8'b00010000; end
                5: begin sw <= 12; an <= 8'b00100000; end // 显示B
                6: begin sw <= finaltotal_bottles % 10; an <= 8'b01000000; end
                7: begin sw <= finaltotal_bottles / 10; an <= 8'b10000000; end
            endcase
        end
        else if (state == SHOW_SETTINGS) begin
            case (handle_an_cnt)
                0: begin sw <= pills_per_bottle % 10; an <= 8'b00000001; end
                1: begin sw <= pills_per_bottle / 10; an <= 8'b00000010; end
                2: begin sw <= 10; an <= 8'b00000100; end // 显示P
                3: begin sw <= total_bottles % 10; an <= 8'b00001000; end
                4: begin sw <= total_bottles / 10; an <= 8'b00010000; end
                5: begin sw <= 10; an <= 8'b00100000; end // 显示B
                6: begin sw <= time_per_pill % 10; an <= 8'b01000000; end
                7: begin sw <= time_per_pill / 10; an <= 8'b10000000; end
            endcase
        end
        else if (state == SHOW_PROGRESS) begin
            case (handle_an_cnt)
                0: begin sw <= current_pills % 10; an <= 8'b00000001; end
                1: begin sw <= current_pills / 10; an <= 8'b00000010; end
                2: begin sw <= 11; an <= 8'b00000100; end // 显示/
                3: begin sw <= pills_per_bottle % 10; an <= 8'b00001000; end
                4: begin sw <= pills_per_bottle / 10; an <= 8'b00010000; end
                5: begin sw <= 12; an <= 8'b00100000; end // 显示B
                6: begin sw <= completed_bottles % 10; an <= 8'b01000000; end
                7: begin sw <= completed_bottles / 10; an <= 8'b10000000; end
            endcase
        end
        else if(state == SET_MED) begin
            case(handle_an_cnt)
                0: begin  // 药片数个位
                    an <= (med_select == MED_PILLS) ? (enlight_flag ? 8'b00000001 : 8'b00000000) : 8'b00000001;
                    sw <= pills_per_bottle % 10;
                end
                1: begin  // 药片数十位
                    an <= (med_select == MED_PILLS) ? (enlight_flag ? 8'b00000010 : 8'b00000000) : 8'b00000010;
                    sw <= pills_per_bottle / 10;
                end
                2: begin  // 分隔符"-"
                    an <= 8'b00000100;
                    sw <= 11; 
                end
                3: begin  // 药瓶数个位
                    an <= (med_select == MED_BOTTLES) ? (enlight_flag ? 8'b00001000 : 8'b00000000) : 8'b00001000;
                    sw <= total_bottles % 10;
                end
                4: begin  // 药瓶数十位
                    an <= (med_select == MED_BOTTLES) ? (enlight_flag ? 8'b00010000 : 8'b00000000) : 8'b00010000;
                    sw <= total_bottles / 10;
                end
                5: begin  // 分隔符"-"
                    an <= 8'b00100000;
                    sw <= 11;
                end
                6: begin  // 时间个位
                    an <= (med_select == MED_TIME) ? (enlight_flag ? 8'b01000000 : 8'b00000000) : 8'b01000000;
                    sw <= time_per_pill % 10;
                end
                7: begin  // 时间十位
                    an <= (med_select == MED_TIME) ? (enlight_flag ? 8'b10000000 : 8'b00000000) : 8'b10000000;
                    sw <= time_per_pill / 10;
                end
            endcase
        end
        else begin
            case (handle_an_cnt)
                0: begin 
                    if (enlight != 3'b001) an <= 8'b00000001;
                    else if (state == IDEL) an <= 8'b00000001;
                    else if (enlight_flag) an <= 8'b00000001;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= second_clk % 10;
                    else sw <= second % 10;
                end
                1: begin 
                    if (enlight != 3'b001) an <= 8'b00000010;
                    else if (state == IDEL) an <= 8'b00000010;
                    else if (enlight_flag) an <= 8'b00000010;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= second_clk / 10;
                    else sw <= second / 10;
                end
                2: begin an <= 8'b00000100; sw <= 10; end  // 显示冒号
                3: begin 
                    if (enlight != 3'b010) an <= 8'b00001000;
                    else if (state == IDEL) an <= 8'b00001000;
                    else if (enlight_flag) an <= 8'b00001000;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= minute_clk % 10;
                    else sw <= minute % 10;
                end
                4: begin 
                    if (enlight != 3'b010) an <= 8'b00010000;
                    else if (state == IDEL) an <= 8'b00010000;
                    else if (enlight_flag) an <= 8'b00010000;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= minute_clk / 10;
                    else sw <= minute / 10;
                end
                5: begin an <= 8'b00100000; sw <= 10; end  // 显示冒号
                6: begin 
                    if (enlight != 3'b100) an <= 8'b01000000;
                    else if (state == IDEL) an <= 8'b01000000;
                    else if (enlight_flag) an <= 8'b01000000;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= hours_clk % 10;
                    else sw <= hours % 10;
                end
                7: begin 
                    if (enlight != 3'b100) an <= 8'b10000000;
                    else if (state == IDEL) an <= 8'b10000000;
                    else if (enlight_flag) an <= 8'b10000000;
                    else an <= 8'b00000000;
                    if (state == SET_CLOCK) sw <= hours_clk / 10;
                    else sw <= hours / 10;
                end
                default: an <= 8'b00000000;
            endcase
        end
    end

    // 数码管显示译码
    always @(posedge clk) begin
        case (sw)  
            4'd0: num <= 8'b11111100;  // 0
            4'd1: num <= 8'b01100000;  // 1
            4'd2: num <= 8'b11011010;  // 2
            4'd3: num <= 8'b11110010;  // 3
            4'd4: num <= 8'b01100110;  // 4
            4'd5: num <= 8'b10110110;  // 5
            4'd6: num <= 8'b10111110;  // 6
            4'd7: num <= 8'b11100000;  // 7
            4'd8: num <= 8'b11111110;  // 8
            4'd9: num <= 8'b11110110;  // 9
            4'd10: num <= 8'b00000010; // 冒号
            4'd11: num <= 8'b00000010; // 新增/符号
            4'd12: num <= 8'b00000010; // 新增B符号
            default: num <= 8'b00000000;
        endcase
    end
    
    
    always @(negedge reset or posedge sec_flag  or posedge stop or posedge toxic) begin
        if (!reset) begin
            temBottles <= 7'd0;
            temPills <= 11'd0;
            tempT <= 7'd1;
            working <= 1'd0;
            end
        else if(stop) begin
        end
        else if(toxic)begin
            temPills<=1'd0;
            tempT<=1'd1;
            working<=1'd0;
            //total_pills <= total_pills - temPills - 1'd1 > 0 ?total_pills - temPills - 1'd1:1'd0;
            //finaltotal_bottles <= finaltotal_bottles > 1? finaltotal_bottles - 1'b1:1'b1;
        end 
        else if (temBottles >= total_bottles) begin
            working <= 1'd1;
            temPills <= 1'd0;
            tempT <= 1'd1;
            end
        else if (temPills >= (pills_per_bottle-1'b1)) begin
            temPills <= 7'd0;
            temBottles <= temBottles + 7'd1;
            finaltotal_bottles <= finaltotal_bottles + 1'b1;
            total_pills <= total_pills + 1'b1;
            end
        else if (tempT >= time_per_pill) begin
            tempT <= 7'd1;
            temPills <= temPills + 7'd1;
            total_pills <= total_pills + 1'b1;
            end
        else if(stop || toxic)begin
            //停止中断
            end
        else begin
        tempT <= tempT + 5'd1;
        end
    end
    
    assign completed_bottles = temBottles;
    assign current_pills = temPills;
    assign bottle_full = working;
   
    // 输出信号赋值
    assign num_out0 = num;
    assign num_out1 = num;
    assign an_out = an;
    assign am_pm = hours >= 13? 1'b1: 1'b0;
    assign enlight_out = enlight;
    // 闹钟功能：当时间与设定时间相同时触发蜂鸣器
    assign beep_r = (minute == minute_clk) && (hours == hours_clk) && 
                   ((minute_clk != 0) || (hours_clk != 0)) && (state == IDEL)
                   ||((hours!=0)&&(minute==0)&&(second==0)&&(state==IDEL));
    assign state_out = state;
endmodule