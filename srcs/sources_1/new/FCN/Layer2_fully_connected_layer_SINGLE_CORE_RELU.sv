`timescale 1ns / 1ps


module fully_connected_layer_SINGLE_CORE_RELU #(
    parameter DATA_WIDTH      = 32,
    parameter ADDR_WIDTH      = 12,
    parameter INPUT_SIZE      = 0,
    parameter OUTPUT_SIZE     = 0
) (
    // CONTROL LOGIC
    input logic clk,
    input logic reset,
    input logic i_run,

    // BRAM2 READ INPUT_DATA FOR LAYER_2
    // BRAM4 READ INPUT_DATA FOR OUTPUT_LAYER
    output logic ce_input,  // Clock Enable 
    output logic we_input,  // Write Enable (`0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_input,
    output logic [DATA_WIDTH - 1:0] din_input,
    input logic [DATA_WIDTH - 1:0] qout_input,

    // BRAM3 READ WEIGHT_DATA FOR LAYER_2
    // BRAM5 READ WEIGHT_DATA FOR OUTPUT_LAYER
    output logic ce_weight,  // Clock Enable 
    output logic we_weight,  // Write Enable (0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_weight,
    output logic [DATA_WIDTH - 1:0] din_weight,
    input logic signed [DATA_WIDTH - 1:0] qout_weight,


    // BRAM4 Write OUTPUT_DATA FOR LAYER_2
    output logic ce_output,  // Clock Enable 
    output logic we_output,  // Write Enable (0: Read, 1:Write)
    output logic [ADDR_WIDTH - 1:0] addr_output,
    output logic [DATA_WIDTH - 1:0] din_output,
    input logic [DATA_WIDTH - 1:0] qout_output,

    output logic layer_done
);

    localparam DATA_WIDTH_8BIT = 8;


    logic [$clog2(OUTPUT_SIZE) - 1 : 0] input_read_done_cnt;

    logic layer_input_read_done;



    //////////////////////////////////////////////////////////////////////////////////
    //  DATA LOAD FROM BRAM
    //////////////////////////////////////////////////////////////////////////////////


    //-- FSM

    typedef enum {
        IDLE,
        RUN,
        STORE,
        DONE
    } state_e;

    state_e input_read_state, input_read_state_next;
    state_e weight_read_state, weight_read_state_next;
    logic input_read_done;
    logic weight_read_done;




    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            input_read_state  <= IDLE;
            weight_read_state <= IDLE;
        end else begin
            input_read_state  <= input_read_state_next;
            weight_read_state <= weight_read_state_next;
        end
    end


    always_comb begin
        input_read_state_next  = input_read_state;
        weight_read_state_next = weight_read_state;

        case (input_read_state)
            IDLE:
            if (i_run) begin
                input_read_state_next = RUN;
            end

            RUN:
            if (input_read_done) begin
                input_read_state_next = STORE;
            end


            STORE: begin
                if (layer_input_read_done) begin
                    input_read_state_next = DONE;
                end else begin
                    input_read_state_next = RUN;
                end
            end

            DONE: input_read_state_next = IDLE;
        endcase

        case (weight_read_state)
            IDLE:
            if (i_run) begin
                weight_read_state_next = RUN;
            end

            RUN: begin
                if (weight_read_done) begin
                    weight_read_state_next = DONE;
                end else if (input_read_done) begin
                    weight_read_state_next = STORE;
                end
            end
 
            STORE: weight_read_state_next = RUN;

            DONE: weight_read_state_next = IDLE;
        endcase
    end

    //-- Address Counter

    logic [ADDR_WIDTH-1:0] addr_input_cnt_read;
    logic [ADDR_WIDTH-1:0] addr_weight_cnt_read;


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            addr_input_cnt_read <= 0;
        end else if (input_read_done) begin
            addr_input_cnt_read <= 0;
        end else if (input_read_state == RUN) begin
            addr_input_cnt_read <= addr_input_cnt_read + 1;
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            addr_weight_cnt_read <= 0;
        end else if (weight_read_done) begin
            addr_weight_cnt_read <= 0;
        end else if (weight_read_state == RUN) begin
            addr_weight_cnt_read <= addr_weight_cnt_read + 1;
        end
    end

    assign input_read_done = addr_input_cnt_read == (INPUT_SIZE - 1);
    assign weight_read_done = addr_weight_cnt_read == ((INPUT_SIZE * OUTPUT_SIZE) - 1);


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            input_read_done_cnt   <= 0;
            layer_input_read_done <= 0;
        end else if (input_read_done) begin
            if (input_read_done_cnt == OUTPUT_SIZE - 1) begin
                input_read_done_cnt   <= input_read_done_cnt + 1;
                layer_input_read_done <= 1;
            end else begin
                input_read_done_cnt   <= input_read_done_cnt + 1;
                layer_input_read_done <= 0;
            end
        end
    end


    //-- READ FROM BRAM


    assign addr_input = addr_input_cnt_read;
    assign ce_input = (input_read_state == RUN);
    assign we_input = 0;
    assign din_input = 0;

    assign addr_weight = addr_weight_cnt_read;
    assign ce_weight = (weight_read_state == RUN);
    assign we_weight = 0;
    assign din_weight = 0;




    //////////////////////////////////////////////////////////////////////////////////
    //  ACCUMULATE INPUT * WEIGHT
    //////////////////////////////////////////////////////////////////////////////////

    logic input_valid;
    logic store_valid;
    logic signed [DATA_WIDTH-1 : 0] MAC_result;
    logic MAC_done;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            input_valid <= 0;
            store_valid <= 0;
        end else begin
            input_valid <= (input_read_state == RUN);
            store_valid <= (input_read_state == STORE);
        end
    end



    MAC #(
        .DATA_WIDTH(DATA_WIDTH)
    ) U_MAC_0 (
        .clk(clk),
        .reset(reset),
        .input_valid(input_valid),
        .store(store_valid),
        .input_data(qout_input),
        .weight(qout_weight),
        .result(MAC_result),
        .result_valid(MAC_done)
    );







    //////////////////////////////////////////////////////////////////////////////////
    //  Relu
    //////////////////////////////////////////////////////////////////////////////////
    logic [DATA_WIDTH-1 : 0] MAC_result_relu;

    assign MAC_result_relu = MAC_done ? ((MAC_result >= 0) ? MAC_result : 8'b0) : 8'b0;




    //////////////////////////////////////////////////////////////////////////////////
    //  WRITE RESULT
    //////////////////////////////////////////////////////////////////////////////////

    logic [ADDR_WIDTH-1:0] addr_output_cnt;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            addr_output_cnt <= 0;
        end else if (MAC_done) begin
            addr_output_cnt <= addr_output_cnt + 1;
        end
    end

    assign addr_output = addr_output_cnt;
    assign ce_output = MAC_done;
    assign we_output = 1'b1;
    assign din_output = MAC_result_relu;

    //////////////////////////////////////////////////////////////////////////////////
    //  LAYER DONE SIGNAL
    //////////////////////////////////////////////////////////////////////////////////


    typedef enum logic [1:0] {
        L_IDLE,
        L_PROCESSING,
        L_DONE
    } layer_state_e;

    layer_state_e layer_state, layer_state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            layer_state <= L_IDLE;
        else
            layer_state <= layer_state_next;
    end

    always_comb begin
        layer_state_next = layer_state;

        case (layer_state)
            L_IDLE:
                if (i_run)
                    layer_state_next = L_PROCESSING;

            L_PROCESSING:
                if (addr_output_cnt == OUTPUT_SIZE)
                    layer_state_next = L_DONE;

            L_DONE:
                layer_state_next = L_IDLE;
        endcase
    end

    assign layer_done = (layer_state == L_DONE);

endmodule
