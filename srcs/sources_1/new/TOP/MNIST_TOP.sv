`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:         -
// Engineer:        T.Y JANG
// 
// Create Date:     04/05/2025
// Design Name:     FPGA-Based MNIST Digit Classification System
// Module Name:     MNIST_TOP
// Project Name:    MNIST Handwritten Digit Recognition
// Target Devices:  BASYS-3
// Tool Versions:   Vivado 2020.2
// Description: 
//
// ******************************************************
// ** End-to-End Fully Connected Network Inference on FPGA **
// ******************************************************
//
// This module implements a fully pipelined digit classification system 
// based on the MNIST dataset using three fully connected layers (FCNs).
//
// The model follows a simple architecture:
//    [Input Image] → [FCN Layer 1] → [FCN Layer 2] → [Output Layer (Argmax)]
//
// Each fully connected layer is built with on-chip BRAM and MAC units,
// using an 8-bit quantized format for weights and activations.
// Data is processed layer-by-layer using handshaking signals.
//
// ----------------------- System Overview ------------------------
// • Input: 28x28 grayscale image (flattened to 784 elements, uint8)
// • Layer 1:
//     - Input: 784 (uint8), Weights: 784×60 (int8)
//     - Parallel 4-MAC architecture
//     - Output: 60 (uint32), with ReLU
//
// • Layer 2:
//     - Input: 60 (uint32), Weights: 60×30 (int8)
//     - Single-core MAC architecture
//     - Output: 30 (uint32), with ReLU
//
// • Output Layer:
//     - Input: 30 (uint32), Weights: 30×10 (int8)
//     - Output: 10 class scores (uint32)
//     - Argmax selection to determine final digit class
//
// ------------------------- Functional Flow -----------------------
// 1. System receives `i_run` trigger.
// 2. FCN Layer 1 starts processing the image → `layer_1_done` asserted.
// 3. FCN Layer 2 begins using Layer 1’s output → `layer_2_done` asserted.
// 4. Output Layer computes class scores and selects digit via `argmax`.
// 5. Final digit result is stored in `mnist_class`.
//
// -----------------------------------------------------------------
// Notes:
// - All weights and inputs are stored in separate BRAM blocks.
// - Uses dual-port BRAMs where inter-layer data transfer is needed.
//
// -----------------------------------------------------------------
//////////////////////////////////////////////////////////////////////////////////

module MNIST_TOP #(
    //  LAYER1_INPUT_DATA : 28 * 28 | UINT8 GRAYSCALE IMAGE
    parameter BRAM0_MEM_SIZE   = 196,
    parameter BRAM0_DATA_WIDTH = 32,
    parameter BRAM0_ADDR_WIDTH = 9,

    //  LAYER1_WEIGHT_DATA : 784 * 60 = 47,840 | INT8
    parameter BRAM1_MEM_SIZE   = 196 * 60,
    parameter BRAM1_DATA_WIDTH = 32,
    parameter BRAM1_ADDR_WIDTH = 14,

    //  LAYER1_OUTPUT_DATA
    //  LAYER2_INPUT_DATA   :   60 | UINT32
    parameter BRAM2_MEM_SIZE   = 60,
    parameter BRAM2_DATA_WIDTH = 32,
    parameter BRAM2_ADDR_WIDTH = 6,

    //  LAYER2_WEIGHT_DATA : 60 * 30 = 1,800 | INT8
    parameter BRAM3_MEM_SIZE   = 60 * 30,
    parameter BRAM3_DATA_WIDTH = 32,
    parameter BRAM3_ADDR_WIDTH = 12,

    //  LAYER2_OUTPUT_DATA
    //  OUTPUT_LAYER_INPUT_DATA   :   30 | UINT32
    parameter BRAM4_MEM_SIZE   = 30,
    parameter BRAM4_DATA_WIDTH = 32,
    parameter BRAM4_ADDR_WIDTH = 5,

    //  OUTPUT_LAYER_WEIGHT_DATA : 30 * 10 = 300 | INT8
    parameter BRAM5_MEM_SIZE   = 30 * 10,
    parameter BRAM5_DATA_WIDTH = 32,
    parameter BRAM5_ADDR_WIDTH = 9
) (
    clk,
    reset,
    i_run,
    mnist_class
);

    input logic clk;
    input logic reset;
    input logic i_run;
    output logic [3:0] mnist_class;

    logic ce_layer1_input;
    logic we_layer1_input;
    logic [BRAM0_ADDR_WIDTH - 1:0] addr_layer1_input;
    logic [BRAM0_DATA_WIDTH - 1:0] din_layer1_input;
    logic [BRAM0_DATA_WIDTH - 1:0] qout_layer1_input;

    logic ce_layer1_weight;
    logic we_layer1_weight;
    logic [BRAM1_ADDR_WIDTH - 1:0] addr_layer1_weight;
    logic signed [BRAM1_DATA_WIDTH - 1:0] din_layer1_weight;
    logic signed [BRAM1_DATA_WIDTH - 1:0] qout_layer1_weight;


    logic ce_layer1_output;
    logic we_layer1_output;
    logic [BRAM2_ADDR_WIDTH - 1:0] addr_layer1_output;
    logic [BRAM2_DATA_WIDTH - 1:0] din_layer1_output;
    logic [BRAM2_DATA_WIDTH - 1:0] qout_layer1_output;


    logic ce_layer2_input;
    logic we_layer2_input;
    logic [BRAM2_ADDR_WIDTH - 1:0] addr_layer2_input;
    logic [BRAM2_DATA_WIDTH - 1:0] din_layer2_input;
    logic [BRAM2_DATA_WIDTH - 1:0] qout_layer2_input;

    logic ce_layer2_weight;
    logic we_layer2_weight;
    logic [BRAM3_ADDR_WIDTH - 1:0] addr_layer2_weight;
    logic signed [BRAM3_DATA_WIDTH - 1:0] din_layer2_weight;
    logic signed [BRAM3_DATA_WIDTH - 1:0] qout_layer2_weight;

    logic ce_layer2_output;
    logic we_layer2_output;
    logic [BRAM4_ADDR_WIDTH - 1:0] addr_layer2_output;
    logic [BRAM4_DATA_WIDTH - 1:0] din_layer2_output;
    logic [BRAM4_DATA_WIDTH - 1:0] qout_layer2_output;

    logic ce_output_layer_input;
    logic we_output_layer_input;
    logic [BRAM4_ADDR_WIDTH - 1:0] addr_output_layer_input;
    logic [BRAM4_DATA_WIDTH - 1:0] din_output_layer_input;
    logic [BRAM4_DATA_WIDTH - 1:0] qout_output_layer_input;

    logic ce_output_layer_weight;
    logic we_output_layer_weight;
    logic [BRAM5_ADDR_WIDTH - 1:0] addr_output_layer_weight;
    logic signed [BRAM5_DATA_WIDTH - 1:0] din_output_layer_weight;
    logic signed [BRAM5_DATA_WIDTH - 1:0] qout_output_layer_weight;


    //////////////////////////////////////////////////////////////////////////////////
    //  BRAM
    //////////////////////////////////////////////////////////////////////////////////

    single_port_bram_layer1_input #(
        .DATA_WIDTH(BRAM0_DATA_WIDTH),
        .ADDR_WIDTH(BRAM0_ADDR_WIDTH),
        .MEM_SIZE  (BRAM0_MEM_SIZE)
    ) U_BRAM0 (
        .clk (clk),
        .ce  (ce_layer1_input),
        .we  (we_layer1_input),
        .addr(addr_layer1_input),
        .din (din_layer1_input),
        .qout(qout_layer1_input)
    );


    single_port_bram_layer1_weight #(
        .DATA_WIDTH(BRAM1_DATA_WIDTH),
        .ADDR_WIDTH(BRAM1_ADDR_WIDTH),
        .MEM_SIZE  (BRAM1_MEM_SIZE)
    ) U_BRAM1 (
        .clk (clk),
        .ce  (ce_layer1_weight),
        .we  (we_layer1_weight),
        .addr(addr_layer1_weight),
        .din (din_layer1_weight),
        .qout(qout_layer1_weight)
    );


    dual_port_bram_layer2_input #(
        .DATA_WIDTH(BRAM2_DATA_WIDTH),
        .ADDR_WIDTH(BRAM2_ADDR_WIDTH),
        .MEM_SIZE  (BRAM2_MEM_SIZE)
    ) U_BRAM2 (
        .clk(clk),

        .ce_a  (ce_layer1_output),
        .we_a  (we_layer1_output),
        .addr_a(addr_layer1_output),
        .din_a (din_layer1_output),
        .qout_a(qout_layer1_output),

        .ce_b  (ce_layer2_input),
        .we_b  (we_layer2_input),
        .addr_b(addr_layer2_input),
        .din_b (din_layer2_input),
        .qout_b(qout_layer2_input)
    );


    single_port_bram_layer2_weight #(
        .DATA_WIDTH(BRAM3_DATA_WIDTH),
        .ADDR_WIDTH(BRAM3_ADDR_WIDTH),
        .MEM_SIZE  (BRAM3_MEM_SIZE)
    ) U_BRAM3 (
        .clk (clk),
        .ce  (ce_layer2_weight),
        .we  (we_layer2_weight),
        .addr(addr_layer2_weight),
        .din (din_layer2_weight),
        .qout(qout_layer2_weight)
    );

    dual_port_bram_output_layer_input #(
        .DATA_WIDTH(BRAM4_DATA_WIDTH),
        .ADDR_WIDTH(BRAM4_ADDR_WIDTH),
        .MEM_SIZE  (BRAM4_MEM_SIZE)
    ) U_BRAM4 (
        .clk(clk),

        .ce_a  (ce_layer2_output),
        .we_a  (we_layer2_output),
        .addr_a(addr_layer2_output),
        .din_a (din_layer2_output),
        .qout_a(qout_layer2_output),

        .ce_b  (ce_output_layer_input),
        .we_b  (we_output_layer_input),
        .addr_b(addr_output_layer_input),
        .din_b (din_output_layer_input),
        .qout_b(qout_output_layer_input)
    );


    single_port_bram_output_layer_weight #(
        .DATA_WIDTH(BRAM5_DATA_WIDTH),
        .ADDR_WIDTH(BRAM5_ADDR_WIDTH),
        .MEM_SIZE  (BRAM5_MEM_SIZE)
    ) U_BRAM5 (
        .clk (clk),
        .ce  (ce_output_layer_weight),
        .we  (we_output_layer_weight),
        .addr(addr_output_layer_weight),
        .din (din_output_layer_weight),
        .qout(qout_output_layer_weight)
    );

    //////////////////////////////////////////////////////////////////////////////////
    //  FCN LAYER 1
    //////////////////////////////////////////////////////////////////////////////////
    // INPUT: 28x28×1 => 784 (UINT8)
    // 
    // WEIGHT: 784 * 60 = 47,840 (INT8)
    //
    // 4MAC PARALLEL PROCESS   
    //
    // OUTPUT: 60   (UINT32)
    //
    // ACTIVATION FUNCTION: ReLU
    //////////////////////////////////////////////////////////////////////////////////
    localparam LAYER1_INPUT_SIZE = 784;
    localparam LAYER1_OUTPUT_SIZE = 60;
    localparam LAYER1_DATA_WIDTH = 32;
    localparam LAYER1_ADDR_WIDTH = 14;
    logic layer_1_done;

    (* DONT_TOUCH = "TRUE" *)
    fully_connected_layer_4_CORE_PARALLEL_RELU #(
        .DATA_WIDTH (LAYER1_DATA_WIDTH),
        .ADDR_WIDTH (LAYER1_ADDR_WIDTH),
        .INPUT_SIZE (LAYER1_INPUT_SIZE),
        .OUTPUT_SIZE(LAYER1_OUTPUT_SIZE)
    ) FCN_LAYER_1 (
        .clk  (clk),
        .reset(reset),
        .i_run(i_run),

        .ce_input  (ce_layer1_input),
        .we_input  (we_layer1_input),
        .addr_input(addr_layer1_input),
        .din_input (din_layer1_input),
        .qout_input(qout_layer1_input),

        .ce_weight  (ce_layer1_weight),
        .we_weight  (we_layer1_weight),
        .addr_weight(addr_layer1_weight),
        .din_weight (din_layer1_weight),
        .qout_weight(qout_layer1_weight),

        .ce_output  (ce_layer1_output),
        .we_output  (we_layer1_output),
        .addr_output(addr_layer1_output),
        .din_output (din_layer1_output),
        .qout_output(qout_layer1_output),

        .layer_done(layer_1_done)
    );

    //////////////////////////////////////////////////////////////////////////////////
    //  FCN LAYER 2
    //////////////////////////////////////////////////////////////////////////////////
    // INPUT: 60    (UINT32)
    // 
    // WEIGHT: 60 * 30 = 1800 (UINT8)
    //
    // OUTPUT: 30
    //
    // ACTIVATION FUNCTION: ReLU
    //////////////////////////////////////////////////////////////////////////////////
    localparam LAYER2_INPUT_SIZE = 60;
    localparam LAYER2_OUTPUT_SIZE = 30;
    localparam LAYER2_DATA_WIDTH = 32;
    localparam LAYER2_ADDR_WIDTH = 12;
    logic layer_2_done;

    (* DONT_TOUCH = "TRUE" *)
    fully_connected_layer_SINGLE_CORE_RELU #(
        .DATA_WIDTH (LAYER2_DATA_WIDTH),
        .ADDR_WIDTH (LAYER2_ADDR_WIDTH),
        .INPUT_SIZE (LAYER2_INPUT_SIZE),
        .OUTPUT_SIZE(LAYER2_OUTPUT_SIZE)
    ) FCN_LAYER_2 (
        .clk  (clk),
        .reset(reset),
        .i_run(layer_1_done),

        .ce_input  (ce_layer2_input),
        .we_input  (we_layer2_input),
        .addr_input(addr_layer2_input),
        .din_input (din_layer2_input),
        .qout_input(qout_layer2_input),

        .ce_weight  (ce_layer2_weight),
        .we_weight  (we_layer2_weight),
        .addr_weight(addr_layer2_weight),
        .din_weight (din_layer2_weight),
        .qout_weight(qout_layer2_weight),

        .ce_output  (ce_layer2_output),
        .we_output  (we_layer2_output),
        .addr_output(addr_layer2_output),
        .din_output (din_layer2_output),
        .qout_output(qout_layer2_output),

        .layer_done(layer_2_done)
    );

    //////////////////////////////////////////////////////////////////////////////////
    //  OUTPUT LAYER
    //////////////////////////////////////////////////////////////////////////////////
    // INPUT: 30
    // 
    // WEIGHT: 30 * 10 = 300
    //
    // OUTPUT: 10
    //
    // ACTIVATION FUNCTION: Softmax
    //////////////////////////////////////////////////////////////////////////////////
    localparam OUTPUT_LAYER_INPUT_SIZE = 30;
    localparam OUTPUT_LAYER_OUTPUT_SIZE = 10;
    localparam OUTPUT_LAYER_DATA_WIDTH = 32;
    localparam OUTPUT_LAYER_ADDR_WIDTH = 9;
    logic output_layer_done;

    (* DONT_TOUCH = "TRUE" *)
    fully_connected_layer_SINGLE_CORE_ARGMAX #(
        .DATA_WIDTH(OUTPUT_LAYER_DATA_WIDTH),
        .ADDR_WIDTH(OUTPUT_LAYER_ADDR_WIDTH),
        .INPUT_SIZE(OUTPUT_LAYER_INPUT_SIZE),
        .OUTPUT_SIZE(OUTPUT_LAYER_OUTPUT_SIZE)
    ) OUTPUT_LAYER (
        .clk(clk),
        .reset(reset),
        .i_run(layer_2_done),

        .ce_input(ce_output_layer_input),
        .we_input(we_output_layer_input),
        .addr_input(addr_output_layer_input),
        .din_input(din_output_layer_input),
        .qout_input(qout_output_layer_input),

        .ce_weight(ce_output_layer_weight),
        .we_weight(we_output_layer_weight),
        .addr_weight(addr_output_layer_weight),
        .din_weight(din_output_layer_weight),
        .qout_weight(qout_output_layer_weight),

        .layer_done(output_layer_done),
        .mnist_class(mnist_class)
    );




endmodule
