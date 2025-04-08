//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/21/2025 08:46:02 AM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb();
   
 //  LAYER1_INPUT_DATA : 28 * 28 | UINT8 GRAYSCALE IMAGE
    parameter BRAM0_MEM_SIZE   = 196;
    parameter BRAM0_DATA_WIDTH = 32;
    parameter BRAM0_ADDR_WIDTH = 9;

    //  LAYER1_WEIGHT_DATA : 784 * 60 = 47,840 | INT8
    parameter BRAM1_MEM_SIZE   = 196 * 60;
    parameter BRAM1_DATA_WIDTH = 32;
    parameter BRAM1_ADDR_WIDTH = 14;

    //  LAYER1_OUTPUT_DATA
    //  LAYER2_INPUT_DATA   :   60 | UINT32
    parameter BRAM2_MEM_SIZE   = 60;
    parameter BRAM2_DATA_WIDTH = 32;
    parameter BRAM2_ADDR_WIDTH = 6;

    //  LAYER2_WEIGHT_DATA : 60 * 30 = 1,800 | INT8
    parameter BRAM3_MEM_SIZE   = 60 * 30;
    parameter BRAM3_DATA_WIDTH = 32;
    parameter BRAM3_ADDR_WIDTH = 12;

    //  LAYER2_OUTPUT_DATA
    //  OUTPUT_LAYER_INPUT_DATA   :   30 | UINT32
    parameter BRAM4_MEM_SIZE   = 30;
    parameter BRAM4_DATA_WIDTH = 32;
    parameter BRAM4_ADDR_WIDTH = 5;

    //  OUTPUT_LAYER_WEIGHT_DATA : 30 * 10 = 300 | INT8
    parameter BRAM5_MEM_SIZE   = 30 * 10;
    parameter BRAM5_DATA_WIDTH = 32;
    parameter BRAM5_ADDR_WIDTH = 9;

    logic clk;
    logic reset;
    logic i_run;
    logic [3:0] mnist_class;
    
    MNIST_TOP #(    
    .BRAM0_MEM_SIZE(BRAM0_MEM_SIZE),
    .BRAM0_DATA_WIDTH(BRAM0_DATA_WIDTH),
    .BRAM0_ADDR_WIDTH(BRAM0_ADDR_WIDTH),
    
    .BRAM1_MEM_SIZE(BRAM1_MEM_SIZE),
    .BRAM1_DATA_WIDTH(BRAM1_DATA_WIDTH),
    .BRAM1_ADDR_WIDTH(BRAM1_ADDR_WIDTH),
    
    .BRAM2_MEM_SIZE(BRAM2_MEM_SIZE),
    .BRAM2_DATA_WIDTH(BRAM2_DATA_WIDTH),
    .BRAM2_ADDR_WIDTH(BRAM2_ADDR_WIDTH),

    .BRAM3_MEM_SIZE(BRAM3_MEM_SIZE),
    .BRAM3_DATA_WIDTH(BRAM3_DATA_WIDTH),
    .BRAM3_ADDR_WIDTH(BRAM3_ADDR_WIDTH),

    .BRAM4_MEM_SIZE(BRAM4_MEM_SIZE),
    .BRAM4_DATA_WIDTH(BRAM4_DATA_WIDTH),
    .BRAM4_ADDR_WIDTH(BRAM4_ADDR_WIDTH),

    
    .BRAM5_MEM_SIZE(BRAM5_MEM_SIZE),
    .BRAM5_DATA_WIDTH(BRAM5_DATA_WIDTH),
    .BRAM5_ADDR_WIDTH(BRAM5_ADDR_WIDTH)

    ) DUT
    (
        .*
    );


    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 0;
        reset = 1;
        i_run = 0;

        @(posedge clk);
        reset = 0;
        @(posedge clk);
        i_run = 1;
        @(posedge clk);
        i_run = 0;
        
    end
    
    
endmodule
