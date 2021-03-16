`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:01:09 06/19/2020 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
   clk,
   clk_b,
	reset,
	
	//runningled,
	//txd,
	LED,
	
	DI,
	RO,
	DE,
	RE
    );
	 
	input clk;
    input clk_b;
	input reset;
	output [7:0]	LED;
	//RS485
	output			DI;
	output			DE;
	input			RO;
	output			RE;
	
	wire [7:0]	LED;
	//RS485
	wire			DI;
	wire			DE;
	wire			RO;
	wire			RE;

	wire				clk;
	wire               clk_b;
	wire				reset;
	wire               clk_in;
	
	assign LED = read_address[7:0];

	wire	[1:0]		RS485BrSet;
	wire				RS485TxCmd;
	wire				RS485TxReady;
	wire	[7:0]		RS485TxData;
	wire				RS485TxCmd_top;
    wire    [7:0]      RS485TxData_top;
    wire				RS485TxCmd_ram;
    wire    [7:0]      RS485TxData_ram;
	wire				RS485RxReady;
	wire	[7:0]		RS485RxData;
	wire				Rs485R2TDelay;
	
	wire [9:0] read_address;
    wire [15:0] read_data;
    wire nrst;
    wire [9:0] rom_read_address;
    reg [15:0] rom_read_data;	 
    
     reg     [2:0]      clk_cnt;
     reg                clk50m;    
//================================================================================//
// controller
//================================================================================//
   IBUFDS ibuf (
      .O(clk_in),  // Buffer output
      .I(clk),  // Diff_p buffer input (connect directly to top-level port)
      .IB(clk_b) // Diff_n buffer input (connect directly to top-level port)
   );
   
   always@(posedge clk_in)
   begin
       if(!reset)
       begin
           clk_cnt = 3'd0;
           clk50m = 0;
       end
       else
       begin
           if(clk_cnt == 3'd3)
           begin
               clk_cnt <= 3'd0;
               clk50m <= 1'b0;
           end
           else if(clk_cnt == 3'd1)
           begin
               clk_cnt <= clk_cnt + 1'b1;
               clk50m <= 1'b1;
           end
           else
           begin
               clk_cnt <= clk_cnt + 1'b1;
           end
       end
   end
   
   
	main_controller	i_control
	(
	.clock					( clk50m ),
	.reset					( reset ),
	
	.LED					(  ),
	.SW1					( 1'b1 ),
	
	//RS485
	.uart_tx_sig			( RS485TxCmd_top ),
	.uart_idle				( RS485TxReady ),
	.uart_tx_data			( RS485TxData_top ),
	.uart_rx_ready			( RS485RxReady ),
	.uart_rx_data			( RS485RxData ),
	.r2t_delay				( Rs485R2TDelay ),
	
	.rom_en                (nrst),
	
	.tp						(  )
	);
	
	    
    
        always @(posedge clk50m) begin
            rom_read_data[9:0] <= rom_read_address;
            rom_read_data[15:10] <= 1'b0;
        end
    
        wire loop_complete;
        wire error_detected;
        wire [7:0] error_state;
        wire [9:0] error_address;
        wire [15:0] expected_data;
        wire [15:0] actual_data;
    
        ROM_TEST #(
            .ADDR_WIDTH(10),
            .DATA_WIDTH(16),
            .ADDRESS_STEP(1),
            .MAX_ADDRESS(1023)
        ) dram_test (
            .rst(!nrst),
            .clk(clk50m),
            // Memory connection
            .read_data(read_data),
            .read_address(read_address),
            // INIT ROM connection
            .rom_read_data(rom_read_data),
            .rom_read_address(rom_read_address),
            // Reporting
            .loop_complete(loop_complete),
            .error(error_detected),
            .error_state(error_state),
            .error_address(error_address),
            .expected_data(expected_data),
            .actual_data(actual_data)
        );
    
        ram0 #(
        ) bram (
            // Read port
            .rdclk(clk50m),
            .rdaddr(read_address),
            .do(read_data)
        );
    
        ERROR_OUTPUT_LOGIC #(
            .DATA_WIDTH(16),
            .ADDR_WIDTH(10)
        ) output_logic (
            .clk(clk50m),
            .rst(!nrst),
            .loop_complete(loop_complete),
            .error_detected(error_detected),
            .error_state(error_state),
            .error_address(error_address),
            .expected_data(expected_data),
            .actual_data(actual_data),
            .tx_data(RS485TxData_ram),
            .tx_data_ready(),
            .tx_data_accepted(RS485TxReady)
        );
//================================================================================//
// RS485
//================================================================================//
    assign RS485TxData = nrst ? RS485TxData_ram : RS485TxData_top;
    assign RS485TxCmd = nrst ? RS485TxCmd_ram : RS485TxCmd_top;
    
	rs485_top	i_uart584
	(
	.clock					( clk50m ),
	.reset					( reset ),
	
	.txd					( DI ),
	.rxd					( RO ),
	
	.tx_cmd					( RS485TxCmd ),
	.tx_ready				( RS485TxReady ),
	.tx_data				( RS485TxData ),
	.r2tdelay_en			( Rs485R2TDelay ),
	.rx_ready				( RS485RxReady ),
	.rx_data				( RS485RxData ),
	.i_pin_br_val_set		( RS485BrSet ),
	
	.tp						(  )
//	.i_br_val_sel,
//	.i_br_val
	);
	 
	assign	RS485BrSet = 2'b10;			//115200
	assign	DE = ~RS485TxReady;
	assign	RE= DE;
	
endmodule


module ram0(
    // Read port
    input rdclk,
    input [9:0] rdaddr,
    output reg [15:0] do);

    (* ram_style = "block" *) reg [15:0] ram[0:1023];

    genvar i;
    generate
        for (i=0; i<1024; i=i+1)
        begin
            initial begin
                ram[i] <= i;
            end
        end
    endgenerate

    always @ (posedge rdclk) begin
        do <= ram[rdaddr];
    end

endmodule

module ERROR_OUTPUT_LOGIC #(
    parameter [7:0] DATA_WIDTH = 1,
    parameter [7:0] ADDR_WIDTH = 6
) (
    input rst,
    input clk,

    input loop_complete,
    input error_detected,
    input [7:0] error_state,
    input [ADDR_WIDTH-1:0] error_address,
    input [DATA_WIDTH-1:0] expected_data,
    input [DATA_WIDTH-1:0] actual_data,

    // Output to UART
    input tx_data_accepted,
    output reg tx_data_ready,
    output reg [7:0] tx_data
);
    reg reg_error_detected;
    reg [7:0] reg_error_state;
    reg [ADDR_WIDTH-1:0] reg_error_address;
    reg [DATA_WIDTH-1:0] reg_expected_data;
    reg [DATA_WIDTH-1:0] reg_actual_data;

    reg [7:0] error_count;
    reg [7:0] output_shift;

    wire [7:0] next_output_shift = output_shift + 8;
    wire count_shift_done = next_output_shift >= 8'd16;
    wire address_shift_done = next_output_shift >= ADDR_WIDTH;
    wire data_shift_done = next_output_shift >= DATA_WIDTH;

    reg loop_ready;
    reg [7:0] latched_error_count;

    reg [7:0] errors;
    reg [10:0] state;
    reg [15:0] loop_count;
    reg [15:0] latched_loop_count;

    localparam START = (1 << 0),
        ERROR_COUNT_HEADER = (1 << 1),
        ERROR_COUNT_COUNT = (1 << 2),
        CR = (1 << 3),
        LF = (1 << 4),
        ERROR_HEADER = (1 << 5),
        ERROR_STATE = (1 << 6),
        ERROR_ADDRESS = (1 << 7),
        ERROR_EXPECTED_DATA = (1 << 8),
        ERROR_ACTUAL_DATA = (1 << 9),
        LOOP_COUNT = (1 << 10);

    initial begin
        tx_data_ready <= 1'b0;
        tx_data <= 8'b0;
        state <= START;
        reg_error_detected <= 1'b0;
    end

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            error_count <= 0;
            reg_error_detected <= 0;
            tx_data_ready <= 0;
            tx_data <= 8'b0;
            loop_count <= 0;
            loop_ready <= 0;
        end else begin

            if(error_detected) begin
                if(error_count < 255) begin
                    error_count <= error_count + 1;
                end

                if(!reg_error_detected) begin
                    reg_error_detected <= 1;
                    reg_error_state <= error_state;
                    reg_error_address <= error_address;
                    reg_expected_data <= expected_data;
                    reg_actual_data <= actual_data;
                end
            end

            if(tx_data_accepted) begin
                tx_data_ready <= 0;
            end

            if(loop_complete) begin
                loop_count <= loop_count + 1;
                if(!loop_ready) begin
                    loop_ready <= 1;
                    latched_error_count <= error_count;
                    latched_loop_count <= loop_count;
                    error_count <= 0;
                end
            end

            case(state)
                START: begin
                    if(reg_error_detected) begin
                        state <= ERROR_HEADER;
                    end else if(loop_ready) begin
                        state <= ERROR_COUNT_HEADER;
                    end
                end
                ERROR_COUNT_HEADER: begin
                    if(!tx_data_ready) begin
                        tx_data <= "L";
                        tx_data_ready <= 1;
                        state <= ERROR_COUNT_COUNT;
                    end
                end
                ERROR_COUNT_COUNT: begin
                    if(!tx_data_ready) begin
                        tx_data <= latched_error_count;
                        tx_data_ready <= 1;
                        output_shift <= 0;
                        state <= LOOP_COUNT;
                    end
                end
                LOOP_COUNT: begin
                    if(!tx_data_ready) begin
                        tx_data <= (latched_loop_count >> output_shift);
                        tx_data_ready <= 1;

                        if(count_shift_done) begin
                            output_shift <= 0;
                            loop_ready <= 0;
                            state <= CR;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                CR: begin
                    if(!tx_data_ready) begin
                        tx_data <= 8'h0D; // "\r"
                        tx_data_ready <= 1;
                        state <= LF;
                    end
                end
                LF: begin
                    if(!tx_data_ready) begin
                        tx_data <= 8'h0A; // "\n"
                        tx_data_ready <= 1;
                        state <= START;
                    end
                end
                ERROR_HEADER: begin
                    if(!tx_data_ready) begin
                        tx_data <= "E";
                        tx_data_ready <= 1;
                        state <= ERROR_STATE;
                    end
                end
                ERROR_STATE: begin
                    if(!tx_data_ready) begin
                        tx_data <= reg_error_state;
                        tx_data_ready <= 1;
                        output_shift <= 0;
                        state <= ERROR_ADDRESS;
                    end
                end
                ERROR_ADDRESS: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_error_address >> output_shift);
                        tx_data_ready <= 1;

                        if(address_shift_done) begin
                            output_shift <= 0;
                            state <= ERROR_EXPECTED_DATA;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                ERROR_EXPECTED_DATA: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_expected_data >> output_shift);
                        tx_data_ready <= 1;

                        if(data_shift_done) begin
                            output_shift <= 0;
                            state <= ERROR_ACTUAL_DATA;
                        end else begin
                            output_shift <= next_output_shift;
                        end
                    end
                end
                ERROR_ACTUAL_DATA: begin
                    if(!tx_data_ready) begin
                        tx_data <= (reg_actual_data >> output_shift);
                        tx_data_ready <= 1;

                        if(data_shift_done) begin
                            state <= CR;
                            reg_error_detected <= 0;
                        end else begin
                            output_shift <= output_shift + 8;
                        end
                    end
                end
                default: begin
                    state <= START;
                end
            endcase
        end
    end
endmodule

module ROM_TEST #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 1,
    // How much to increment the address to move 1 full data width.
    parameter ADDRESS_STEP = 1,
    // Max address for this memory
    parameter MAX_ADDRESS = 63
) (
    input rst,
    input clk,
    // Memory connection
    input [DATA_WIDTH-1:0] read_data,
    output reg [ADDR_WIDTH-1:0] read_address,
    // INIT ROM
    // When the memory is first initialized, it is expected to match the ROM
    // port.
    input [DATA_WIDTH-1:0] rom_read_data,
    output reg [ADDR_WIDTH-1:0] rom_read_address,
    // When an iteration is complete, success will be 1 for 1 cycle
    output reg loop_complete,
    // If an error occurs during a test, error will be 1 for each cycle
    // with an error.
    output reg error,
    // error_state will contain the state of test FSM when the error occured.
    output reg [7:0] error_state,
    // error_address will be the read address where the error occurred.
    output reg [ADDR_WIDTH-1:0] error_address,
    // expected_data will be the read value expected.
    output reg [DATA_WIDTH-1:0] expected_data,
    // actual_data will be the read value read.
    output reg [DATA_WIDTH-1:0] actual_data
);
    reg [7:0] state;
    reg [DATA_WIDTH-1:0] test_value;
    reg [1:0]            delay = 1'b0;

    localparam START = 8'd1,
        VERIFY_INIT = 8'd2;

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            error <= 0;
        end else begin
            case(state)
                START: begin
                    loop_complete <= 0;
                    state <= VERIFY_INIT;
                    read_address <= 0;
                    rom_read_address <= 0;
                    error <= 0;
                end
                VERIFY_INIT: begin
                    if(delay == 0) begin
                        if(rom_read_data != read_data) begin
                            error <= 1;
                            error_state <= state;
                            error_address <= read_address;
                            expected_data <= rom_read_data;
                            actual_data <= read_data;
                        end else begin
                            error <= 0;
                        end
                    end
                    else if (delay == 1) begin
                        if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                            read_address <= read_address + ADDRESS_STEP;
                            rom_read_address <= rom_read_address + ADDRESS_STEP;
                        end else begin
                            rom_read_address <= 0;
                            read_address <= 0;
                            loop_complete <= 1;
                            state <= START;
                        end
                    end
                    delay <= delay + 1;
                end
            endcase
        end
    end
endmodule
