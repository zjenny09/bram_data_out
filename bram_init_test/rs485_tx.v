//============================================================================//
//  Module:         uart_tx.v
//  Author         
//  Creation Date:  
//  Last Modified: 
//  Purpose:
//============================================================================//

`timescale 1ns/1ps

module rs485_tx
(
  bclk, 
  reset, 
  tx_din, 
  tx_cmd, 
  tx_start,
  tx_ready, 
  txd
);
//============================================================================//
// Inputs and Outputs 
//============================================================================//
  input           bclk;
  input           reset;
  input           tx_cmd;
  input  [7:0]    tx_din;
  output reg      tx_start;
  output reg      tx_ready;
  output reg      txd;
//============================================================================//
// Output regs
//============================================================================//
//============================================================================//
// Parameters
//============================================================================//
  parameter [3:0] Lframe  = 8;
  parameter [2:0] s_idle  = 3'b000;
  parameter [2:0] s_start = 3'b001;
  parameter [2:0] s_wait  = 3'b010;
  parameter [2:0] s_shift = 3'b011;
  parameter [2:0] s_stop  = 3'b100;
  parameter [2:0] s_ready = 3'b101;

//============================================================================//
// Internal Signals declaration
//============================================================================//
  reg  [2:0]    state;
  reg  [3:0]    cnt;
  reg  [3:0]    dcnt;
//============================================================================//
// Main code start here
//============================================================================// 

  always @(negedge reset or posedge bclk) 
  begin
      if(!reset) 
      begin
          state    <= s_idle;
          cnt      <= 4'b0;
          tx_ready <= 1;
          txd     <= 1;
		  tx_start <= 1'b0;
		  dcnt   <= 4'b0;
      end
      else 
      begin
          case(state)
          s_idle: 
          begin
              tx_ready <= 1;
              cnt <= 0;
              txd <= 1'b1;
			  tx_start <= 0;
              if(tx_cmd == 1'b1)
			  begin
                  state <= s_start;
				  tx_ready <= 0;
			  end
              else
                  state <= s_idle;
          end
          
          s_start: 
          begin
              txd <= 1'b0;
			  tx_start <= 1;
              state <= s_wait;
          end
          
          s_wait: 
          begin
              if(cnt == 4'b1110) 
              begin
                  cnt <= 0;
                  if(dcnt == Lframe) 
                  begin
                      state <= s_stop;
                      dcnt  <= 0;
                      txd <= txd;
                  end
                  else  
                  begin
                      state <= s_shift;
                      txd  <= txd;
                  end
              end
              else 
              begin
                  state <= s_wait;
                  cnt <= cnt + 1;
              end
          end
          
          s_shift: 
          begin
              txd <= tx_din[dcnt];
              dcnt <= dcnt + 1;
              state <= s_wait;
          end
          
          s_stop: 
          begin
              txd     <= 1'b1;
              if(cnt == 4'b1111) 
              begin
                  state <= s_ready;
                  cnt   <= 0;
              end
              else 
              begin
                  state <= s_stop;
                  cnt <= cnt + 1;
              end
          end
		  
		  s_ready: 
          begin
              txd     <= 1'b1;
			  state <= s_idle;
          end
		  
          default:
          begin
              state    <= s_idle;
              cnt      <= 0;
              txd     <= 1;
          end
          endcase
      end
  end
//============================================================================//
// Main code end here
//============================================================================// 
endmodule
