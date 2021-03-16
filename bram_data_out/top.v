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
	wire				reset;
	
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
      
     wire   [7:0]   tp;
//================================================================================//
// controller
//================================================================================//
    assign LED = tp;
   
	main_controller	i_control
	(
	.clock					( clk ),
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
	
	        
        ROM_READ #(
            .ADDR_WIDTH(10),
            .DATA_WIDTH(16),
            .ADDRESS_STEP(1),
            .MAX_ADDRESS(1023)
        ) dram_test (
            .rst(!nrst),
            .clk(clk),
            // Memory connection
            .read_data(read_data),
            .read_address(read_address),
            // Reporting
            .tx_data(RS485TxData_ram),
            .tx_data_ready(RS485TxCmd_ram),
            .tx_data_accepted(RS485TxReady)
        );
            
        ram0 #(
        ) bram (
            // Read port
            .rdclk(clk),
            .rdaddr(read_address),
            .do(read_data)
        );
//================================================================================//
// RS485
//================================================================================//
    assign RS485TxData = nrst ? RS485TxData_ram : RS485TxData_top;
    assign RS485TxCmd = nrst ? RS485TxCmd_ram : RS485TxCmd_top;
    
	rs485_top	i_uart584
	(
	.clock					( clk ),
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

module ROM_READ #(
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
    // When an iteration is complete, success will be 1 for 1 cycle
    input tx_data_accepted,
    output reg tx_data_ready,
    output reg [7:0] tx_data
);
    reg [3:0] state;
    reg [ADDR_WIDTH-1:0] output_address;
    reg [DATA_WIDTH-1:0] actual_data;
        
    reg  [1:0] sub_state;
    reg  [7:0] temp_data;
    reg  [7:0] temp_num;
    
    localparam	START		= 4'd0,
                READ_RAM	= 4'd1,
                ADDR_OUT	= 4'd2,
                DATA_OUT	= 4'd3,
                ADDR_ADD	= 4'd4;

    always @(posedge clk) begin
        if(rst) begin
            state <= START;
            tx_data_ready <= 0;
            tx_data <= 0;
            read_address <= 0;
            sub_state <= 0;
        end else begin
            case(state)
                START: begin
                    state <= READ_RAM;
                    read_address <= 0;
                    tx_data_ready <= 0;
                    tx_data <= 0;
                    sub_state <= 0;
                end
                
                READ_RAM: begin;
                    output_address <= read_address;
                    actual_data <= read_data;
                    state <= DATA_OUT;
                end
                
                ADDR_OUT:begin
                    case(sub_state)
                        2'd0: begin
                        temp_data <= output_address;
                        temp_num <= ADDR_WIDTH;
                        sub_state <= 2'd1;
                        end
                    
                        2'd1: begin
                        if(tx_data_accepted) begin
                            tx_data_ready <= 1;
                            tx_data <= temp_data;
                            sub_state <= 2'd2;
                        end
                        end
                        
                        2'd2:begin
                        if(temp_num > 8) begin
                            temp_data <= output_address >> 8;
                            temp_num = temp_num - 8;
                            sub_state <= 2'd1;
                        end
                        else begin
                            sub_state <= 2'd0;
                            state <= ADDR_ADD;
                        end
                        end
                    endcase
                end
                
                DATA_OUT:begin
                    case(sub_state)
                    2'd0: begin
                    temp_data <= actual_data;
                    temp_num <= DATA_WIDTH;
                    sub_state <= 2'd1;
                    end
                
                    2'd1: begin
                    if(tx_data_accepted) begin
                        tx_data_ready <= 1;
                        tx_data <= temp_data;
                        sub_state <= 2'd2;
                    end
                    end
                    
                    2'd2: begin
                    if(temp_num > 8) begin
                        temp_data <= output_address >> 8;
                        temp_num = temp_num - 8;
                        sub_state <= 2'd1;
                    end
                    else begin
                        sub_state <= 2'd0;
                        state <= ADDR_OUT;
                    end
                    end
                endcase
                end
                
                ADDR_ADD:begin
                    if(read_address + ADDRESS_STEP <= MAX_ADDRESS) begin
                        read_address <= read_address + ADDRESS_STEP;
                        state <= READ_RAM;
                    end else begin
                        read_address <= 0;
                        state <= START;
                    end
                end
            endcase
        end
    end
endmodule
