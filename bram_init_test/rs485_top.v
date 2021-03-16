//============================================================================//
//  Module:         uart_top.v
//  Author          
//  Creation Date:  
//  Last Modified:  
//  Purpose:
//============================================================================//

`timescale 1ns/1ps

module rs485_top
(
  clock, 
  reset, 
  txd, 
  rxd,
  tx_cmd,
  tx_ready,
  tx_data,
  r2tdelay_en,
  rx_ready,
  rx_data,
  i_pin_br_val_set,
//  i_br_val_sel,
//  i_br_val
	tp
  );
//============================================================================//
// Inputs and Outputs 
//============================================================================//
  input           clock;
  input           reset;
  input           rxd;
  output          txd;
  input           tx_cmd;
  output   reg    tx_ready;
  input   [7:0]   tx_data;
  output          rx_ready;
  input           r2tdelay_en;    //receive to transmit delay, 1 for enable
  output  [7:0]   rx_data;
  input   [1:0]   i_pin_br_val_set; //baudrate selecting pin 00 : 1280000
                                    //                       01 : 628000
									//                       10 : 115200
									//                       11 : 57600
//  input           i_br_val_sel;     //0: baudrate set from external pins;   1: baudrate set from uart module
//  input   [7:0]  i_br_val;         //baudrate load value, from uart module
  
  output	[7:0]	tp;
  
  parameter  r2tdelay = 320;    // SN65HVD78 receiver disable to driver enable time : 8us MAX  (we choose 16us) 


//============================================================================//
// Output regs
//============================================================================//
//============================================================================//
// Internal Signals declaration
//============================================================================//
  wire            bclk;
  reg     [7:0]   tx_data_bc;
  reg             tx_cmd_bc;
  wire            tx_start;
  wire            tx_ready_bc;
  reg     [2:0]   tx_step;
  reg     [8:0]   tx_cmd_cnt;

  wire            rx_ready_bc;
  wire    [7:0]   rx_data_bc; 
  reg     [2:0]   rx_ready_bc_reg;
  wire            rx_ready_bc_posedge;

  reg [1:0] pin_br_val_set1, pin_br_val_set2;
  reg [7:0] br_load_init_val;
  wire [7:0] br_load_val;
  wire [7:0] tp;
//============================================================================//
// module instantiation
//============================================================================//

  rs485_baud_gen inst_rs485_baud_gen(
     .clk(clock),
     .reset(reset),
     .bclk(bclk),
//	  .br_load_val(br_load_val)
	  .br_load_val(br_load_init_val)
     );

  
  rs485_tx inst_rs485_tx(
      .bclk(bclk),
      .reset(reset),
      .tx_din(tx_data_bc),
      .tx_cmd(tx_cmd_bc),
		.tx_start(tx_start),
      .tx_ready(tx_ready_bc),
      .txd(txd)
    );

  rs485_rx inst_rs485_rx(
      .bclk(bclk),
      .reset(reset),
      .rxd(rxd),
      .rx_ready(rx_ready_bc),
      .rx_dout(rx_data_bc)
     );
	  
//============================================================================//
// Main code start here
//============================================================================// 
//*receive
  always @ (negedge reset or posedge clock)
  begin
      if(!reset)
	      rx_ready_bc_reg <= 3'b111;
	  else
	      rx_ready_bc_reg <= {rx_ready_bc_reg[1:0],rx_ready_bc}; 
  end
    
    
  assign rx_ready_bc_posedge = !rx_ready_bc_reg[2] & rx_ready_bc_reg[1];
  assign rx_ready = rx_ready_bc_posedge;

  assign rx_data = rx_data_bc;

    always @ (negedge reset or posedge clock)
    begin
      if(!reset)
      begin
          tx_ready <= 1'b1;
          tx_cmd_bc <= 1'b0;
          tx_data_bc <= 8'd0;
          tx_step  <= 3'd0;
          tx_cmd_cnt <= 9'd0;
      end
      else
      begin
		  case(tx_step)
	      3'd0:
		  begin
			  tx_ready <= 1'b1;
		      tx_cmd_cnt <= 9'd0;
			  tx_cmd_bc <= 1'b0;
			  if(tx_cmd)
              begin
				  if(r2tdelay_en)
				  begin
				      tx_step <= 3'd1;
					  tx_data_bc <= tx_data;
                      tx_ready <= 1'b0; 
				  end
				  else
				  begin
					  tx_step <= 3'd2;
					  tx_data_bc <= tx_data;
                      tx_ready <= 1'b0; 
				  end                
              end
		  end
		  3'd1:
		  begin
			  if(tx_cmd_cnt == r2tdelay)
			  begin
				  tx_cmd_cnt <= 9'd0;
				  tx_cmd_bc <= 1'b1;
				  tx_step <= 3'd3;
			  end
			  else
			  begin
				  tx_cmd_cnt <= tx_cmd_cnt + 1;
			  end
		  end
		  3'd2:
		  begin
			  tx_cmd_bc <= 1'b1;
			  tx_step <= 3'd3;
		  end
		  3'd3:
		  begin
			  if(tx_start == 1'b1)
			  begin
				  tx_cmd_bc <= 1'b0;
				  tx_step <= 3'd4;
			  end  
		  end
		  3'd4:
		  begin
			  if(tx_ready_bc == 1'b1)
			  begin
				  tx_ready <= 1'b1;
				  tx_step <= 3'd0;
			  end  
		  end
		  default:
		  begin
			  tx_cmd_bc <= 1'b0;
			  tx_step <= 3'd0;
		  end
		  endcase
		end
    end  

/////////////////////////////////////////baudrate setting//////////////////////////
  always @ (negedge reset or posedge clock)
  begin
    if(!reset)
	begin
		pin_br_val_set1 <= 2'b0; pin_br_val_set2 <= 2'b0;
		br_load_init_val <= 8'b0;
    end
	else
	begin
		pin_br_val_set2 <= pin_br_val_set1; pin_br_val_set1 <= i_pin_br_val_set;
		if(pin_br_val_set2 == 2'b00) br_load_init_val <= 8'h00;  //baudrate 1280000
		else if(pin_br_val_set2 == 2'b01) br_load_init_val <= 8'h01; //baudrate 628000
		else if(pin_br_val_set2 == 2'b10) br_load_init_val <= 8'h19;    //0a; //baudrate 115200
		else if(pin_br_val_set2 == 2'b11) br_load_init_val <= 8'h15; //baudrate 57600
    end
  end

//  assign br_load_val = (!i_br_val_sel) ? br_load_init_val : i_br_val;
        
//============================================================================//
// Main code end here
//============================================================================// 


endmodule
