`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:43:09 06/03/2020 
// Design Name: 
// Module Name:    main_controller 
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
module main_controller(
	clock,
	reset,
	
	LED,
	SW1,
	
	//RS485
	uart_tx_sig,
	uart_idle,
	uart_tx_data,
	uart_rx_ready,
	uart_rx_data,
	r2t_delay,
	
	rom_en,
		
	tp
    );
	 
//================================================================================//
// Inputs and Outputs
//================================================================================//	 
	input			clock;
	input			reset;
	
	output	[3:0]	LED;
	input			SW1;
	
	//RS485
	output			uart_tx_sig;
	input			uart_idle;
	output	[7:0]	uart_tx_data;
	input			uart_rx_ready;
	input	[7:0]	uart_rx_data;
	output			r2t_delay;
	
	output          rom_en;
	
	output	[7:0]	tp;
	
//================================================================================//
// Output Regs
//================================================================================//
	wire	[3:0]	LED;
	
	reg			    uart_tx_sig;
	reg    	[7:0]	uart_tx_data;
	wire	[7:0]	uart_rx_data;
	wire		    r2t_delay;
	
    reg           rom_en;	
	
	wire	[7:0]	tp;
	
	
//================================================================================//
// Internal Signal Declares
//================================================================================//
	reg	[3:0]	state;
	reg	[7:0]	command;
	reg	[7:0]	command_cp;
	reg			command_cycle;

//================================================================================//
// Paramenters
//================================================================================//
	parameter	ST_IDLE			= 4'd0;
	parameter	ST_CMD_PARSE	= 4'd1;
	parameter	ST_HANDSHAKE	= 4'd3;
	parameter	ST_MC8051_CMD	= 4'd5;
	
//================================================================================//
// Main code start here 
//================================================================================//
	assign	r2t_delay = SW1;
	assign	LED = state;
	
	always@(posedge clock)
	begin
		if(!reset)
		begin
			state <= ST_IDLE;
			
			command <= 8'h00;
			command_cycle <= 1'b0;
			command_cp <= 8'h00;
			
			rom_en <= 1'b0;
			uart_tx_data <= 8'd0;
			uart_tx_sig <= 1'b0;			
		end//end for if
		else
		begin
			case(state)
				ST_IDLE:
				begin
					uart_tx_sig <= 1'b0;
					if(uart_rx_ready)
					begin
						if(command_cycle == 1'b1)
						begin
							command_cycle <= 1'b0;
							command_cp <= uart_rx_data;
							state <= ST_CMD_PARSE;
						end
						else
						begin
							command_cycle <= 1'b1;
							command <= uart_rx_data;
							state <= ST_IDLE;
						end
					end
				end//end for ST_IDLE
				
				ST_CMD_PARSE:
				begin
					if(command == command_cp)
					begin
						case(command)
							8'hF0:
							begin
								uart_tx_data <= 8'hF0;
								state <= ST_HANDSHAKE;
							end
							8'hFA:
                           begin
                               rom_en <= 1'b1;
                               uart_tx_data <= 8'hFA;
                               state <= ST_HANDSHAKE;
                            end
                            8'hFB:
                            begin
                               rom_en <= 1'b0;
                               uart_tx_data <= 8'hFB;
                               state <= ST_HANDSHAKE;
                            end
							default:
							begin
								uart_tx_data <= 8'hEF;
								state <= ST_HANDSHAKE;
							end
						endcase
					end//end for if
					else
					begin
						uart_tx_data <= 8'hEE;
						state <= ST_HANDSHAKE;
					end
				end//end for ST_CMD_PARSE
				
				ST_HANDSHAKE:
				begin
					if(uart_idle)
					begin
						uart_tx_sig <= 1'b1;
						state <= ST_IDLE;
					end
					else ;
				end//end for ST_HANDSHAKE
			endcase
		end//end for else
	end//end for always


endmodule
