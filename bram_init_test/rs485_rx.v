//============================================================================//
//  Module:         uart_rx.v
//  Author          
//  Creation Date:  
//  Last Modified:  
//  Purpose:
//============================================================================//

`timescale 1ns/1ps

module rs485_rx
(
  bclk, 
  reset, 
  rxd, 
  rx_ready, 
  rx_dout
);
//============================================================================//
// Inputs and Outputs 
//============================================================================//
  input         bclk;
  input         reset;
  input         rxd;
  output  reg   rx_ready;
  output [7:0]  rx_dout;
//============================================================================//
// Output regs
//============================================================================//
//============================================================================//
// Internal Signals declaration
//============================================================================//                
  reg    [1:0]  state;
  reg    [3:0]  cnt;
  reg    [3:0]  num;
  reg    [3:0]  dcnt;
  reg    [7:0]  rx_doutmp;  
  reg           rxd_reg;
  reg           rxd_reg2;
  reg           rxd_reg3;
  wire          rxd_fall;
//============================================================================//
// Parameters
//============================================================================//
  parameter [3:0] Lframe   = 8;
  parameter [1:0] s_idle   = 2'b00;
  parameter [1:0] s_sample = 2'b01;
  parameter [1:0] s_stop   = 2'b10;

//============================================================================//
// Main code start here
//============================================================================//
  always @ (negedge reset or posedge bclk)
  begin
      if(!reset)
	  begin
	      rxd_reg <= 1'b1;
		  rxd_reg2 <= 1'b1;
		  rxd_reg3 <= 1'b1;
	  end
	  else
	  begin
	      rxd_reg <= rxd;
          rxd_reg2<= rxd_reg;
	      rxd_reg3<= rxd_reg2;
	  end
  end
  assign rxd_fall = rxd_reg3 & !rxd_reg2; 

  assign rx_dout = rx_doutmp;


  always @ (negedge reset or posedge bclk ) 
  begin
      if (!reset) 
      begin
          state   <= s_idle;
          cnt     <= 4'b0;
          dcnt    <= 4'b0;
          num     <= 4'b0;
          rx_doutmp <= 8'b0;
          rx_ready <= 1'b1;
      end
      else 
      begin
          case(state)
          s_idle: 
          begin
              dcnt    <= 0;
              rx_ready <= 1;
              if(rxd_fall)
			  begin
				  cnt <= 0;
				  num <= 0;
		      end
              else if(cnt == 4'b1111) 
              begin
                  cnt <= 0;
                  if(num > 7) 
                  begin
                      state <= s_sample;
                      num <= 0;
                  end
                  else
                  begin
                    state <= s_idle;
                    num <= 0;
                  end
              end
              else 
              begin
                  cnt <= cnt + 1;
                  if(rxd_reg3 == 1'b0) 
                  begin
                      num <= num + 1;
                  end
                  else 
                  begin
                      num <= num;
                  end
              end
          end

          s_sample: 
          begin
              rx_ready <= 1'b0;
              if(dcnt == Lframe) 
              begin
                  state <= s_stop;
              end
              else 
              begin
                  state <= s_sample;
                  if(cnt == 4'b1111) 
                  begin
                      dcnt <= dcnt + 1;
                      cnt  <= 0;
                      if(num >= 3) 
                      begin
                          num <= 0;
                          rx_doutmp[dcnt] <= 1;
                      end
                      else 
                      begin
                          rx_doutmp[dcnt] <= 0;
                          num <= 0;
                      end
                  end
                  else 
                  begin
                      cnt <= cnt + 1;
					  if((cnt == 5) || (cnt == 6) || (cnt == 7) || (cnt == 8) || (cnt == 9))
					  begin
						  if(rxd_reg3 == 1'b1) 
                          begin
                              num <= num + 1;
                          end
                          else 
                          begin
                              num <= num;
                          end
					  end
                  end
              end
          end

          s_stop: 
          begin
              rx_ready <= 1'b1;
              if(cnt == 4'b1000) 
              begin
                  cnt <= 0;
				  rx_doutmp <= 0;
                  state <= s_idle;
              end
              else 
              begin
                  cnt <= cnt + 1;
              end
          end
          endcase
      end
  end
//============================================================================//
// Main code end here
//============================================================================// 
endmodule









