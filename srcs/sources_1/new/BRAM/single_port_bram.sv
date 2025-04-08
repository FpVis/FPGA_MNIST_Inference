module single_port_bram_layer1_input #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 9,
    parameter MEM_SIZE   = 196
) (
    input  logic                    clk,
    input  logic                    ce,    // Clock Enable 
    input  logic                    we,    // Write Enable (0: Read, 1: Write)
    input  logic [ADDR_WIDTH - 1:0] addr,
    input  logic [DATA_WIDTH - 1:0] din,
    output logic [DATA_WIDTH - 1:0] qout
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];

    initial begin
        $readmemh("layer_1_input_4_12.mem", mem);
    end

    always @(posedge clk) begin
        if (ce) begin
            if (we) begin
                mem[addr] <= din;
            end else begin
                qout <= mem[addr];
            end
        end
    end
endmodule


module single_port_bram_layer1_weight #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 14,
    parameter MEM_SIZE   = 196 * 60
) (
    input logic clk,
    input logic ce,  // Clock Enable 
    input logic we,  // Write Enable (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr,
    input logic signed [DATA_WIDTH - 1:0] din,
    output logic signed [DATA_WIDTH - 1:0] qout
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];

    initial begin
        $readmemh("layer_1_weights.mem", mem);
    end

    always @(posedge clk) begin
        if (ce) begin
            if (we) begin
                mem[addr] <= din;
            end else begin
                qout <= mem[addr];
            end
        end
    end
endmodule


module single_port_bram_layer2_weight #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 12,
    parameter MEM_SIZE   = 60 * 30
) (
    input logic clk,
    input logic ce,  // Clock Enable 
    input logic we,  // Write Enable (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr,
    input logic signed [DATA_WIDTH - 1:0] din,
    output logic signed [DATA_WIDTH - 1:0] qout
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];

    initial begin
        $readmemh("layer_2_weights.mem", mem);
    end

    always @(posedge clk) begin
        if (ce) begin
            if (we) begin
                mem[addr] <= din;
            end else begin
                qout <= mem[addr];
            end
        end
    end
endmodule


module single_port_bram_output_layer_weight #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 9,
    parameter MEM_SIZE   = 30 * 10
) (
    input logic clk,
    input logic ce,  // Clock Enable 
    input logic we,  // Write Enable (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr,
    input logic signed [DATA_WIDTH - 1:0] din,
    output logic signed [DATA_WIDTH - 1:0] qout
);
    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];

    initial begin
        $readmemh("layer_3_weights.mem", mem);
    end

    always @(posedge clk) begin
        if (ce) begin
            if (we) begin
                mem[addr] <= din;
            end else begin
                qout <= mem[addr];
            end
        end
    end
endmodule
