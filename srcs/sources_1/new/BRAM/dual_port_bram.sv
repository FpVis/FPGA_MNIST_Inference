module dual_port_bram_layer2_input #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 6,
    parameter MEM_SIZE   = 60
) (
    input logic clk,

    input logic ce_a,  // Clock Enable A
    input logic we_a,  // Write Enable A (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr_a,
    input logic [DATA_WIDTH - 1:0] din_a,
    output logic [DATA_WIDTH - 1:0] qout_a,

    input logic ce_b,  // Clock Enable B
    input logic we_b,  // Write Enable B (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr_b,
    input logic [DATA_WIDTH - 1:0] din_b,
    output logic [DATA_WIDTH - 1:0] qout_b
);

    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];


    always @(posedge clk) begin
        if (ce_a) begin
            if (we_a) begin
                mem[addr_a] <= din_a;
            end else begin
                qout_a <= mem[addr_a];
            end
        end
    end


    always @(posedge clk) begin
        if (ce_b) begin
            if (we_b) begin
                mem[addr_b] <= din_b;
            end else begin
                qout_b <= mem[addr_b];
            end
        end
    end

endmodule


module dual_port_bram_output_layer_input #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter MEM_SIZE   = 30
) (
    input logic clk,

    input logic ce_a,  // Clock Enable A
    input logic we_a,  // Write Enable A (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr_a,
    input logic [DATA_WIDTH - 1:0] din_a,
    output logic [DATA_WIDTH - 1:0] qout_a,


    input logic ce_b,  // Clock Enable B
    input logic we_b,  // Write Enable B (0: Read, 1: Write)
    input logic [ADDR_WIDTH - 1:0] addr_b,
    input logic [DATA_WIDTH - 1:0] din_b,
    output logic [DATA_WIDTH - 1:0] qout_b
);

    (* ram_style = "block" *)
    reg [DATA_WIDTH - 1:0] mem[0:MEM_SIZE - 1];


    always @(posedge clk) begin
        if (ce_a) begin
            if (we_a) begin
                mem[addr_a] <= din_a;
            end else begin
                qout_a <= mem[addr_a];
            end
        end
    end


    always @(posedge clk) begin
        if (ce_b) begin
            if (we_b) begin
                mem[addr_b] <= din_b;
            end else begin
                qout_b <= mem[addr_b];
            end
        end
    end

endmodule
