`timescale 1ns / 1ps

module final_top(
    input wire clk,
    input wire reset,       // 清零
    input wire stop,
    input wire toxic,
    input wire S0,          // 时钟设置右移
    input wire S1,          // 时钟设置减少
    input wire S2,          // 模式改变
    input wire S3,          // 时钟设置左移
    input wire S4,          // 时钟设置增加
    output wire sd,
    output wire [7:0] num_out0, // 数码管段驱动输出
    output wire [7:0] num_out1, // 数码管段驱动输出
    output wire [7:0] an_out,   // 数码管位驱动输出
    output wire [2:0] enlight_out, // 环形控制检验
    output wire beep_out,
    output [3:0] state_out,
    output wire beep_r_out,      // 闹钟状态灯检测
    output wire bottle_full,
    output wire am_pm           //上下午显示
);

    wire beep_r; 
    wire SW1 ; // 默认正计时模式
   
    // 实例化时钟模块
    final_clock clock_inst (
        .clk(clk),
        .reset(reset),
        .stop(stop),
        .toxic(toxic),
        .S0(S0),
        .S1(S1),
        .S2(S2),
        .S3(S3),
        .S4(S4),
        .SW1(SW1),
        .beep_r(beep_r),
        .num_out0(num_out0),
        .num_out1(num_out1),
        .an_out(an_out),
        .enlight_out(enlight_out),
        .state_out(state_out),
        .bottle_full(bottle_full),
        .am_pm(am_pm)
    );
    
    
    
    // 实例化音频模块
    final_mp3 mp3_inst (
        .clk(clk),
        .beep_r(beep_r),
        .sd(sd),
        .beep_out(beep_out)
    );
    
    assign beep_r_out = beep_r;
endmodule