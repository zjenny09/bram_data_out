//============================================================================//
//  Module:         baud_gen.v
//  Author          
//  Creation Date:  
//  Last Modified: 
//  Purpose:
//============================================================================//

`timescale 1ns/1ps

module rs485_baud_gen
(
  clk,
  reset,
  bclk,
  br_load_val
);
//============================================================================//
// Inputs and Outputs 
//============================================================================//
  input           clk;
  input           reset;
 // 57600*16
  output          bclk;   //921.60kbps
  input [7:0]  br_load_val;
  
//============================================================================//
// Internal Signals declaration
//============================================================================//
  reg             bclk_reg;
  reg      [7:0]  cnt;
//============================================================================//
// Main code start here
//============================================================================//  
 assign bclk = (br_load_val == 0) ? clk : bclk_reg;

  always @(negedge reset or posedge clk)
  begin
      if(!reset)
      begin
          cnt <= 8'd0;
          bclk_reg <= 1'b0;
      end
      else
	  begin
      // 50_000_000 /921600 = 54.25
      //if(cnt > 8'd53) begin
		  if(cnt == br_load_val) 
		  begin
              cnt <= 8'd0;
              bclk_reg <= 1'b1;
          end
          else 
		  begin
              cnt <= cnt + 8'd1;
              bclk_reg <= 1'b0;
          end
      end
  end
//============================================================================//
// Main code end here
//============================================================================//  
endmodule
