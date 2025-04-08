`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 09:39:15 AM
// Design Name: 
// Module Name: MAC
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


module MAC_4CORE #(
    parameter DATA_WIDTH = 8
) (
    input  logic                             clk,
    input  logic                             reset,
    input  logic                             input_valid,
    input  logic                             store,
    input  logic        [    DATA_WIDTH-1:0] input_data,
    input  logic signed [    DATA_WIDTH-1:0] weight,
    output logic signed [(4*DATA_WIDTH)-1:0] result,
    output logic                             result_valid
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            result <= 0;
        end else if (store) begin
            result <= 0;
        end else if (input_valid) begin
            result <= result + ($signed({1'b0, input_data}) * weight);
        end

    end

    assign result_valid = store;

endmodule

module MAC #(
    parameter DATA_WIDTH = 8
) (
    input  logic                         clk,
    input  logic                         reset,
    input  logic                         input_valid,
    input  logic                         store,
    input  logic        [DATA_WIDTH-1:0] input_data,
    input  logic signed [DATA_WIDTH-1:0] weight,
    output logic signed [DATA_WIDTH-1:0] result,
    output logic                         result_valid
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            result <= 0;
        end else if (store) begin
            result <= 0;
        end else if (input_valid) begin
            result <= result + ($signed({1'b0, input_data}) * weight);
        end

    end

    assign result_valid = store;

endmodule
